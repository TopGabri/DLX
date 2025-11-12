library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.DLX_Types.all;

entity DATAPATH is
    port (
        -- # /* INPUT PORTS */

        -- ## CLOCK AND RESET SIGNALS
        Clk, Rst : in std_logic;
        -- ## REGULAR CONTROL SIGNALS
        -- ### DECODE (ID) STAGE CONTROL
        UIS   : in std_logic; -- selects shift or don't shift the immediate by 16 bits leftwards (0: no shift, 1: shift)
        SUS   : in std_logic; -- selects to consider the immediate as signed or unsigned (0: signed, 1: unsigned)
        SES   : in std_logic; -- selects the right sign-extension of the immediate ( 0: 16 -> 32, 1: 26 -> 32)
        RF1   : in std_logic; -- enables the read port 1 of the register file
        RF2   : in std_logic; -- enables the read port 2 of the register file
        JUMPS : in std_logic; -- selects correct target address for jump instructions
        -- ### EXECUTE (EXE) STAGE CONTROL
        BS   : in std_logic;                    -- selects the input B of the ALU (0: out2, 1: imm)
        AS   : in std_logic;                    -- selects the input A of the ALU (0: out1, 1: NPC)
        CNDS : in std_logic_vector(1 downto 0); -- selects the COND register input (00: 0 (normal behavior), 01: 1 (jump), 10: out1==0, 11: out1!=0) 
        ALUS : in aluOp;                        -- alu control bits
        -- ### MEMORY (MEM) STAGE CONTROL
        DMS   : in std_logic;                    -- selects between a signed (1) or unsigned (0) value from memory
        DMB   : in std_logic_vector(1 downto 0); -- selects the number of bytes for the memory operation
        RnW   : in std_logic;                    -- enables read or write of data memory
        DM_EN : in std_logic;                    -- enables the data memory
        -- ### WRITE BACK (WB) STAGE CONTROL
        WBS : in std_logic_vector(1 downto 0); -- selects output to be written back (00: LMD, 01: ALU_out, 10: PC_INCR)
        WRF : in std_logic;                    -- enables the write port of the register file
        RDS : in std_logic_vector(1 downto 0); -- selects the right bits of the instruction as register destination address (00: RS2, 01: RD, 10: R31)
        -- ## SPECIAL CONTROL SIGNALS
        -- ### PIPELINE REGISTER ENABLE CONTROL SIGNALS
        IFIDEN, IDEXEN, EXMEMEN, MEMWBEN, WBIFEN : in std_logic; -- enable the respective pipeline registers when asserted
        -- ### FORWARDING LOGIC CONTROL SIGNALS
        FWD_A_SEL, FWD_B_SEL, FWD_DM_SEL, FWD_JR_SEL : in std_logic_vector(1 downto 0); -- select the right forwarding source
        -- ### JUMP AND BRANCH PREDICTION CONTROL SIGNALS
        JUMP   : in std_logic; -- do jump
        BRANCH : in std_logic; -- do branch prediction
        -- ### BRANCH CORRECTION CONTROL SIGNALS
        NPC_SEL_RST : in std_logic; -- forces NPC_SEL signal to 0 when high
        -- ## INSTRUCTION MEMORY INTERFACE
        INSTR_MEM_OUT : in std_logic_vector(INSTRUCTION_WIDTH - 1 downto 0); -- INSTR_MEM_OUT: Output of Instruction Memory
        -- ## DATA MEMORY INTERFACE
        DATA_FROM_DM : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        -- # /* OUTPUT PORTS */

        -- ## OPCODE AND FUNC
        OPCODE : out std_logic_vector(OP_CODE_SIZE - 1 downto 0);
        FUNC   : out std_logic_vector(FUNC_SIZE - 1 downto 0);
        -- ## BRANCH PREDICTION 
        PREDICTION : out std_logic;
        -- ## FLUSH REQUEST FOR BRANCH CORRECTION
        FLUSH_REQ : out std_logic;
        -- ## RAW HAZARDS STALL REQUEST
        STALL_EX_MEM   : out std_logic; -- request to stall EX/MEM pipeline register
        STALL_ID_EX    : out std_logic; -- request to stall ID/EX pipeline register
        n_cycles_stall : out integer;   -- number of cycles to stall
        -- ## FORWARDING LOGIC SIGNALS 
        fwd : out std_logic_vector(11 downto 0); -- concatenation of all forwarding signals
        -- ## CACHE MISS SIGNAL    
        CACHE_MISS : out std_logic;
        -- ## INSTRUCTION MEMORY INTERFACE
        PC_OUT : out std_logic_vector(ADDR_WIDTH - 1 downto 0); -- PC address sent to Instruction Memory
        -- ## DATA MEMORY INTERFACE
        ADDR_TO_DM : out std_logic_vector(ADDR_WIDTH - 1 downto 0); -- address sent to Data Memory
        ENABLE_DM  : out std_logic;                                 -- enable signal sent to Data Memory
        RnW_DM     : out std_logic;                                 -- read/not write signal sent to Data Memory
        DATA_TO_DM : out std_logic_vector(DATA_WIDTH - 1 downto 0)  -- data to be written to Data Memory
    );
end DATAPATH;

architecture STRUCT of DATAPATH is

    component REG is
        generic (
            N : natural := 32
        );
        port (
            d            : in std_logic_vector(N - 1 downto 0);
            Clk, Rst, en : in std_logic;
            q            : out std_logic_vector(N - 1 downto 0)
        );
    end component REG;

    component P4_ADDER is
        generic (
            NBIT           : integer := 32;
            NBIT_PER_BLOCK : integer := 4
        );
        port (
            A    : in std_logic_vector(NBIT - 1 downto 0);
            B    : in std_logic_vector(NBIT - 1 downto 0);
            Ci   : in std_logic;
            S    : out std_logic_vector(NBIT - 1 downto 0);
            Cout : out std_logic
        );
    end component P4_ADDER;

    component MUX_2_1_1bit is
        port (
            A : in std_logic;
            B : in std_logic;
            S : in std_logic;
            Y : out std_logic);
    end component;

    component MUX_2_1 is
        generic (
            N : natural
        );
        port (
            a1, a2 : in std_logic_vector(N - 1 downto 0);
            sel    : std_logic;
            o      : out std_logic_vector(N - 1 downto 0)
        );
    end component MUX_2_1;

    component MUX_4_1 is
        generic (
            N : natural
        );
        port (
            a1, a2, a3, a4 : in std_logic_vector(N - 1 downto 0);
            sel            : std_logic_vector(1 downto 0);
            o              : out std_logic_vector(N - 1 downto 0)
        );
    end component MUX_4_1;

    component MUX_8_1 is
        generic (
            N : natural
        );
        port (
            a1, a2, a3, a4, a5, a6, a7, a8 : in std_logic_vector(N - 1 downto 0);
            sel                            : std_logic_vector(2 downto 0);
            o                              : out std_logic_vector(N - 1 downto 0)
        );
    end component MUX_8_1;

    component ALU is
        port (
            A, B    : in std_logic_vector(31 downto 0);
            Sel     : in std_logic_vector(ALUS_SIZE - 1 downto 0);
            ALU_OUT : out std_logic_vector(31 downto 0)
        );
    end component ALU;

    component EQUAL0 is
        generic (N : integer := 32);
        port (
            x : in std_logic_vector(N - 1 downto 0);
            o : out std_logic
        );
    end component EQUAL0;

    component SIGN_EXTENDER is
        generic (
            N_BITS_BEFORE : natural := 16;
            N_BITS_AFTER  : natural := 32
        );
        port (
            i : in std_logic_vector(N_BITS_BEFORE - 1 downto 0);
            o : out std_logic_vector(N_BITS_AFTER - 1 downto 0)
        );
    end component SIGN_EXTENDER;

    component ZERO_EXTENDER is
        generic (
            N_BITS_BEFORE : natural := 16;
            N_BITS_AFTER  : natural := 32
        );
        port (
            i : in std_logic_vector(N_BITS_BEFORE - 1 downto 0);
            o : out std_logic_vector(N_BITS_AFTER - 1 downto 0)
        );
    end component ZERO_EXTENDER;

    component REGISTER_FILE is
        generic (
            NBIT_ADD  : integer := 5;
            NBIT_DATA : integer := 32;
            FILE_PATH : string
        );
        port (
            Clk     : in std_logic;
            reset   : in std_logic;
            enable  : in std_logic;
            rd1     : in std_logic;
            rd2     : in std_logic;
            wr      : in std_logic;
            add_wr  : in std_logic_vector(NBIT_ADD - 1 downto 0);
            add_rd1 : in std_logic_vector(NBIT_ADD - 1 downto 0);
            add_rd2 : in std_logic_vector(NBIT_ADD - 1 downto 0);
            datain  : in std_logic_vector(NBIT_DATA - 1 downto 0);
            out1    : out std_logic_vector(NBIT_DATA - 1 downto 0);
            out2    : out std_logic_vector(NBIT_DATA - 1 downto 0)
        );
    end component REGISTER_FILE;

    component BHT is
        generic (
            BHT_SIZE  : integer := 16; -- number of entries in the BHT
            ADDR_SIZE : integer := 4;  -- number of bits used for indexing the
            FILE_PATH : string
        );
        port (
            Clk : in std_logic;
            Rst : in std_logic;
            -- inputs
            PC_1   : in std_logic_vector(31 downto 0); -- ID stage PC (for prediction)
            PC_2   : in std_logic_vector(31 downto 0); -- EX stage PC  (for update)
            Taken  : in std_logic;                     -- actual branch outcome from EX stage
            Update : in std_logic;                     -- update prediction 
            -- outputs
            Prediction_1 : out std_logic; -- predicted branch outcome 
            Prediction_2 : out std_logic  -- predicted branch outcome 
        );
    end component BHT;

    component DATA_CACHE is
        generic (
            FILE_PATH            : string  := "./memory_files/cache.mem";
            MEMORY_ACCESS_CYCLES : integer := 0;
            K                    : integer; -- log2 MAINSIZE (#words in memory)
            R                    : integer; -- log2 NLINES (#lines in the cache)
            W                    : integer  -- log2 LINESIZE (#words in a cache line)
        );
        port (
            clk, rst            : in std_logic;
            enable              : in std_logic;
            ctrl                : in std_logic_vector(1 downto 0);
            is_signed           : in std_logic;
            addr                : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
            data_in             : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            data_out            : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            RnW                 : in std_logic;
            addr_to_memory      : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
            data_in_from_memory : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            data_out_to_memory  : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            RnW_memory          : out std_logic;
            miss                : out std_logic;
            enable_memory       : out std_logic
        );
    end component DATA_CACHE;

    component FORWARDING_STALLING_LOGIC is
        port (
            -- IR through the pipeline
            IF_ID_IR, ID_EX_IR, EX_MEM_IR, MEM_WB_IR : in std_logic_vector(INSTRUCTION_WIDTH - 1 downto 0);
            -- FORWARDING SIGNALS
            -- FWD to ALU A input
            FWD_ALU_to_A  : out std_logic; -- FWD from EX/MEM.ALUOUT
            FWD_ALU2_to_A : out std_logic; -- FWD from MEM/WB.ALUOUT
            FWD_LMD_to_A  : out std_logic; -- FWD from MEM/WB.LMD
            -- FWD to ALU B input
            FWD_ALU_to_B  : out std_logic; -- FWD from EX/MEM.ALUOUT
            FWD_ALU2_to_B : out std_logic; -- FWD from MEM/WB.ALUOUT
            FWD_LMD_to_B  : out std_logic; -- FWD from MEM/WB.LMD
            -- FWD to DM_IN (Data Memory input)
            FWD_ALU2_to_DM       : out std_logic; -- FWD from MEM/WB.ALUOUT
            FWD_LMD_to_DM        : out std_logic; -- FWD from MEM/WB.LMD
            FWD_PC_INCR_WB_to_DM : out std_logic; -- FWD from MEM/WB.PC_INCR
            -- FWD to Jump Register Address
            FWD_ALU_to_JR         : out std_logic; -- FWD from EX/MEM.ALUOUT
            FWD_PC_INCR_EX_to_JR  : out std_logic; -- FWD from ID/EX.PC_INCR
            FWD_PC_INCR_MEM_to_JR : out std_logic; -- FWD from EX/MEM.PC_INCR

            -- STALLING SIGNALS
            STALL_EX_MEM   : out std_logic; -- STALL EX/MEM pipeline register
            STALL_ID_EX    : out std_logic; -- STALL ID/EX pipeline register
            n_cycles_stall : out integer    -- number of cycles to stall
        );
    end component;

    -- DATAPATH signals

    -- IF
    signal PC_Q       : std_logic_vector(ADDR_WIDTH - 1 downto 0); -- PC_Q: Program Counter
    signal PC_INCR    : std_logic_vector(ADDR_WIDTH - 1 downto 0); -- PC_INCR: Program Counter Incremented (PC+4)
    signal INSTR_ADDR : std_logic_vector(ADDR_WIDTH - 1 downto 0); -- INSTR_ADDR: potential NPC

    -- ID
    signal PC_INCR_ID_Q             : std_logic_vector(ADDR_WIDTH - 1 downto 0);        -- PC_INCR_ID_Q: PC_INCR in pipeline stage ID
    signal PC_ID_Q                  : std_logic_vector(ADDR_WIDTH - 1 downto 0);        -- PC_ID_Q: PC in pipeline stage ID
    signal IR_Q                     : std_logic_vector(INSTRUCTION_WIDTH - 1 downto 0); -- IR_Q: Output of Instruction Register
    signal RS1, RS2                 : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);    -- RS1: Source Register 1, RS2: Source Register 2
    signal IMM_I                    : std_logic_vector(IMM_I_WIDTH - 1 downto 0);       -- IMM_I: IMMEDIATE in I-type instructions
    signal IMM_J                    : std_logic_vector(IMM_J_WIDTH - 1 downto 0);       -- IMM_J: IMMEDIATE in J-type instructions
    signal EXT_IMM_I_S, EXT_IMM_I_U : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- EXT_IMM_I_S: sign-extended (16->32 bits) IMM_I, EXT_IMM_I_U: zero-extended (16->32 bits) IMM_I
    signal EXT_IMM_I_SU             : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- EXT_IMM_SU: selected (sign-extended or zero-extended) IMM_I
    signal EXT_IMM_I_SHIFTED        : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- EXT_IMM_I_SHIFTED: IMM_I << 16
    signal EXT_IMM_I, EXT_IMM_J     : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- EXT_IMM_I: selected (sign-extended or zero-extended or shifted) IMM_I, EXT_IMM_J: sign-extended (26->32 bits) IMM_J
    signal EXT_IMM                  : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- EXT_IMM: final selected extended immediate
    signal PREDICTION_1             : std_logic;                                        -- PREDICTION_1: predicted branch outcome in ID stage
    signal UPDATE_BHT               : std_logic;                                        -- UPDATE_BHT: signal to update the BHT
    signal JB                       : std_logic;                                        -- JB: jump branch signal
    signal TARGET_ADDR_I            : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- TARGET_ADDR_I: target address for jump instructions (immediate)
    signal JR_TARGET_ADDR           : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- JR_TARGET_ADDR: target address for jump register instructions
    signal TARGET_ADDR              : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- TARGET_ADDR: target address for jump instructions
    signal RF_OUT_1, RF_OUT_2       : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- RF_OUT_1: Register File Output 1, RF_OUT_2: Register File Output 2

    -- EX
    signal ID_EX_IR_Q             : std_logic_vector(INSTRUCTION_WIDTH - 1 downto 0); -- ID_EX_IR_Q: Instruction Regiter in EX stage
    signal PC_INCR_EX_Q           : std_logic_vector(ADDR_WIDTH - 1 downto 0);        -- PC_INCR_EX_Q: PC_INCR in pipeline stage EX
    signal PC_EX_Q                : std_logic_vector(ADDR_WIDTH - 1 downto 0);        -- PC_EX_Q: PC in pipeline stage EX
    signal RF_OUT_1_Q, RF_OUT_2_Q : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- RF_OUT_1_Q: RF Output 1 in EX, RF_OUT_2_Q: RF Output 2 in EX
    signal EXT_IMM_Q              : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- EXT_IMM_Q: sign-extended IMMEDIATE in EX
    signal A, B                   : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- A: first source register (read from RF or forwarded), B: second source register (read from RF or forwarded)
    signal ALU_IN_1, ALU_IN_2     : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- ALU_IN_1: first operand of ALU, ALU_IN_2: second operand of ALU
    signal EQUAL_0                : std_logic;                                        -- EQUAL_0: Output of EQUAL0 block
    signal NOT_EQUAL_0            : std_logic;                                        -- NOT_EQUAL_0: negated output of EQUAL0 block
    signal PREDICTION_2           : std_logic;                                        -- PREDICTION_2: predicted branch outcome in EX stage
    signal MISS                   : std_logic;                                        -- BRANCH: 1 if the prediction was wrong and the instruction is a branch
    signal COND                   : std_logic;                                        -- COND: input of COND register
    signal DIFF                   : std_logic;                                        -- DIFF: 1 when the prediction != actual outcome
    signal NPC_SEL                : std_logic;                                        -- NPC_SEL: selects the next NPC (0: PC_INCR, 1: ALU_OUT_D)
    signal ALU_OUT_D              : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- ALU_OUT_D: ALU output
    signal CORRECTED_INSTR_ADDR   : std_logic_vector(ADDR_WIDTH - 1 downto 0);        -- CORRECTED_INSTR_ADDR: corrected NPC (after branch prediction)

    -- MEM
    signal EX_MEM_IR_Q   : std_logic_vector(INSTRUCTION_WIDTH - 1 downto 0); -- EX_MEM_IR_Q: Instruction Regiter in MEM stage
    signal PC_INCR_MEM_Q : std_logic_vector(ADDR_WIDTH - 1 downto 0);        -- PC_INCR_MEM_Q: PC_INCR in pipeline stage MEM
    signal NPC           : std_logic_vector(ADDR_WIDTH - 1 downto 0);        -- NPC: Next Program Counter
    signal ALU_OUT_Q     : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- ALU_OUT_Q: Output of ALU in MEM stage
    signal IN_DATA_Q     : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- IN_DATA_Q: register to write in store operations (read from RF or forwarded)
    signal DM_IN         : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- DM_IN: Input Data of Data Memory
    signal LMD_D         : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- LMD_D: Output of Data Memory/Input of LMD register
    -- WB
    signal MEM_WB_IR_Q                 : std_logic_vector(INSTRUCTION_WIDTH - 1 downto 0); -- MEM_WB_IR_Q: Instruction Regiter in WB stage
    signal PC_INCR_WB_Q                : std_logic_vector(ADDR_WIDTH - 1 downto 0);        -- PC_INCR_WB_Q: PC_INCR in pipeline stage WB
    signal LMD_Q                       : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- LMD_Q: Output of LMD register
    signal ALU_OUT_2_Q                 : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- ALU_OUT_2_Q: ALU output in WB stage
    signal WB_DATA                     : std_logic_vector(DATA_WIDTH - 1 downto 0);        -- WB_DATA: Write-back data
    signal MEM_WB_IR_RS2, MEM_WB_IR_RD : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);    --MEM_WB_IR_RS2: IR[rs2] in WB stage, MEM_WB_IR_RD: IR[rd] in WB stage
    signal RD                          : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);    -- destination register of write back

begin
    --------------------------------------- * START OF DATAPATH PIPELINE * -------------------------------------------

    ------------------------------------------------ FETCH (IF) ---------------------------------------------------- 

    -- MUX_NPC: 2-1 multiplexer that returns the NPC choosing among PC_INCR (COND_Q = 0) and ALU_OUT_Q (COND_Q = 1)
    MUX_NPC : MUX_2_1 generic map(N => ADDR_WIDTH)
    port map(
        a1  => INSTR_ADDR,
        a2  => CORRECTED_INSTR_ADDR,
        sel => NPC_SEL,
        o   => NPC
    );

    -- PC_REG: stores program counter and fetches it to the instruction memory and to the PC_ADDER
    PC : REG generic map(N => ADDR_WIDTH) port map(D => NPC, CLK => Clk, Rst => Rst, EN => WBIFEN, Q => PC_Q);
    -- PC_INCR: PC+4
    PC_INCR <= std_logic_vector(unsigned(PC_Q) + 4);

    -- MUX_INSTR_ADDR: chooses between PC+4 and TARGET_ADDR 
    MUX_INSTR_ADDR : MUX_2_1 generic map(N => ADDR_WIDTH)
    port map(
        a1  => PC_INCR,
        a2  => TARGET_ADDR,
        sel => JB,
        o   => INSTR_ADDR
    );

    JB <= JUMP or BRANCH;

    -- send PC to Instruction Memory
    PC_OUT <= PC_Q;

    -- IR: Instruction Register
    IR : REG generic map(N => INSTRUCTION_WIDTH) port map(D => INSTR_MEM_OUT, CLK => Clk, Rst => Rst, EN => IFIDEN, Q => IR_Q);

    -- PC_INCR_ID_REG: pipeline register that forwards PC_INCR from IF to ID stage
    PC_INCR_ID : REG generic map(N => ADDR_WIDTH) port map(D => PC_INCR, CLK => Clk, Rst => Rst, EN => IFIDEN, Q => PC_INCR_ID_Q);

    ------------------------------------------------- DECODE (ID) ---------------------------------------------------

    -- assignments of IR fields

    OPCODE <= IR_Q(31 downto 26);
    RS1    <= IR_Q(25 downto 21);
    RS2    <= IR_Q(20 downto 16);
    FUNC   <= IR_Q(10 downto 0);
    IMM_I  <= IR_Q(15 downto 0);
    IMM_J  <= IR_Q(25 downto 0);

    -- RF: register file
    RF : REGISTER_FILE generic map(NBIT_ADD => REG_ADDR_WIDTH, NBIT_DATA => DATA_WIDTH, FILE_PATH => "./memory_files/reg_file.mem")
    port map(
        Clk     => Clk,
        reset   => Rst,
        enable  => '1',
        rd1     => RF1,
        rd2     => RF2,
        wr      => WRF,
        add_wr  => RD,
        add_rd1 => RS1,
        add_rd2 => RS2,
        datain  => WB_DATA,
        out1    => RF_OUT_1,
        out2    => RF_OUT_2
    );

    PC_ID_Q <= std_logic_vector(unsigned(PC_INCR_ID_Q) - 4);
    PC_EX_Q <= std_logic_vector(unsigned(PC_INCR_EX_Q) - 4);

    -- BHT: Branch History Table
    BRANCH_HISTORY_TABLE : BHT generic map(BHT_SIZE => 16, ADDR_SIZE => 4, FILE_PATH => "./memory_files/bht.mem")
    port map(
        Clk          => Clk,
        Rst          => Rst,
        PC_1         => PC_ID_Q,      -- ID stage PC (for prediction)
        PC_2         => PC_EX_Q,      -- EX stage PC  (for update)
        Taken        => COND,         -- actual branch outcome from EX stage
        Update       => UPDATE_BHT,   -- update prediction 
        Prediction_1 => PREDICTION_1, -- ID stage predicted branch outcome 
        Prediction_2 => PREDICTION_2  -- EX stage predicted branch outcome 
    );

    PREDICTION <= PREDICTION_1;                  -- output the prediction signal
    UPDATE_BHT <= CNDS(0) and (not NPC_SEL_RST); -- UPDATE_BHT is asserted when the instruction in EX is a valid branch 

    -- SIGN_EXTENDER_I: sign-extender for I-type immediate
    SIGN_EXTENDER_I : SIGN_EXTENDER generic map(N_BITS_BEFORE => IMM_I_WIDTH, N_BITS_AFTER => DATA_WIDTH)
    port map(
        i => IMM_I,
        o => EXT_IMM_I_S
    );

    -- ZERO_EXTENDER_I: zero-extender for I-type immediate
    ZERO_EXTENDER_I : ZERO_EXTENDER generic map(N_BITS_BEFORE => IMM_I_WIDTH, N_BITS_AFTER => DATA_WIDTH)
    port map(
        i => IMM_I,
        o => EXT_IMM_I_U
    );

    -- shifting leftwards by 16 bits
    EXT_IMM_I_SHIFTED <= IMM_I & (15 downto 0 => '0');

    MUX_SIGN_EXTENDER_I : MUX_2_1 generic map(N => DATA_WIDTH)
    port map(
        a1  => EXT_IMM_I_S,
        a2  => EXT_IMM_I_U,
        sel => SUS,
        o   => EXT_IMM_I_SU
    );

    MUX_SHIFTING_I : MUX_2_1 generic map(N => DATA_WIDTH)
    port map(
        a1  => EXT_IMM_I_SU,
        a2  => EXT_IMM_I_SHIFTED,
        sel => UIS,
        o   => EXT_IMM_I
    );

    -- SIGN_EXTENDER_J: sign-extender for J-type immediate
    SIGN_EXTENDER_J : SIGN_EXTENDER generic map(N_BITS_BEFORE => IMM_J_WIDTH, N_BITS_AFTER => DATA_WIDTH)
    port map(
        i => IMM_J,
        o => EXT_IMM_J
    );

    -- MUX_SIGN_EXTENDER: chooses between SIGN_EXTENDER_I (I-type instruction) and SIGN_EXTENDER_J (J-type instruction)
    MUX_SIGN_EXTENDER : MUX_2_1 generic map(N => DATA_WIDTH)
    port map(
        a1  => EXT_IMM_I,
        a2  => EXT_IMM_J,
        sel => SES,
        o   => EXT_IMM
    );

    -- ADDR_ADD: computes the target address for branch and jump instructions as PC_INCR + EXT_IMM
    PC_ADDER : P4_ADDER generic map(NBIT => DATA_WIDTH, NBIT_PER_BLOCK => 4)
    port map(
        A    => PC_INCR_ID_Q,
        B    => EXT_IMM,
        Ci   => '0',
        S    => TARGET_ADDR_I,
        Cout => open
    );

    -- MUX_JR_TARGET_ADDR: chooses between RF_OUT_1 and forwarded values as target address for jump register instructions
    MUX_JR_TARGET_ADDR : MUX_4_1 generic map(N => DATA_WIDTH)
    port map(
        a1  => RF_OUT_1,
        a2  => ALU_OUT_Q,
        a3  => PC_INCR_MEM_Q,
        a4  => PC_INCR_EX_Q,
        sel => FWD_JR_SEL,
        o   => JR_TARGET_ADDR
    );

    -- MUX_J_TARGET_ADDR: chooses between TARGET_ADDR_I (immediate) and RF_OUT_1 (register) as target address for jump instructions
    MUX_J_TARGET_ADDR : MUX_2_1 generic map(N => DATA_WIDTH)
    port map(
        a1  => TARGET_ADDR_I,
        a2  => JR_TARGET_ADDR,
        sel => JUMPS,
        o   => TARGET_ADDR
    );

    -- OUT_1: pipeline register containing output 1 of register file
    OUT_1 : REG generic map(N => DATA_WIDTH) port map(D => RF_OUT_1, CLK => Clk, Rst => Rst, EN => IDEXEN, Q => RF_OUT_1_Q);

    -- OUT_2: pipeline register containing output 2 of register file
    OUT_2 : REG generic map(N => DATA_WIDTH) port map(D => RF_OUT_2, CLK => Clk, Rst => Rst, EN => IDEXEN, Q => RF_OUT_2_Q);

    -- IMM: pipeline register containing the IMMEDIATE
    IMM : REG generic map(N => DATA_WIDTH) port map(D => EXT_IMM, CLK => Clk, Rst => Rst, EN => IDEXEN, Q => EXT_IMM_Q);

    -- PC_INCR_EX_REG: pipeline register that forwards PC_INCR from ID to EX stage
    PC_INCR_EX : REG generic map(N => ADDR_WIDTH) port map(D => PC_INCR_ID_Q, CLK => Clk, Rst => Rst, EN => IDEXEN, Q => PC_INCR_EX_Q);

    -- ID_EX_IR: pipeline register between ID and EX containing instruction
    ID_EX_IR : REG generic map(N => INSTRUCTION_WIDTH) port map(D => IR_Q, CLK => Clk, Rst => Rst, EN => IDEXEN, Q => ID_EX_IR_Q);

    ---------------------------------------------- EXECUTE (EX) ---------------------------------------------------

    -- MUX_A: outputs the fiRst source register, choosing between the value read from the RF and the forwarded values
    MUX_A : MUX_4_1 generic map(N => DATA_WIDTH)
    port map(
        a1  => ALU_OUT_2_Q,
        a2  => LMD_Q,
        a3  => ALU_OUT_Q,
        a4  => RF_OUT_1_Q,
        sel => FWD_A_SEL,
        o   => A
    );

    -- MUX_B: outputs the second source register, choosing between the value read from the RF and the forwarded values
    MUX_B : MUX_4_1 generic map(N => DATA_WIDTH)
    port map(
        a1  => RF_OUT_2_Q,
        a2  => LMD_Q,
        a3  => ALU_OUT_2_Q,
        a4  => ALU_OUT_Q,
        sel => FWD_B_SEL,
        o   => B
    );
    -- MUX_ALU_IN_1: outputs the fiRst operand of ALU (ALU_IN_1), choosing between A and PC_INCR_EX
    MUX_ALU_IN_1 : MUX_2_1 generic map(N => DATA_WIDTH)
    port map(
        a1  => A,
        a2  => PC_INCR_EX_Q,
        sel => AS,
        o   => ALU_IN_1
    );

    -- MUX_ALU_IN_2: outputs the second operand of ALU (ALU_IN_2), choosing between B and EXT_IMM_Q
    MUX_ALU_IN_2 : MUX_2_1 generic map(N => DATA_WIDTH)
    port map(
        a1  => B,
        a2  => EXT_IMM_Q,
        sel => BS,
        o   => ALU_IN_2
    );

    -- ALU_0: ALU
    ALU_0 : ALU port map(
        A       => ALU_IN_1,
        B       => ALU_IN_2,
        Sel     => ALUS,
        ALU_OUT => ALU_OUT_D
    );

    -- EQUAL0_0: EQUAL0 block, receiving a signal vector as input and returning 1 if the vector is all 0
    EQUAL0_0 : EQUAL0 generic map(N => DATA_WIDTH)
    port map(
        x => A,
        o => EQUAL_0
    );

    NOT_EQUAL_0 <= not EQUAL_0;
    -- MUX_COND: mux that chooses between 0 (normal flow) when CNDS[0]=0 and BRANCH (branch instruction) when CNDS[0]=1
    MUX_COND : MUX_2_1_1bit port map(
        A => EQUAL_0,
        B => NOT_EQUAL_0,
        S => CNDS(1),
        Y => COND
    );

    DIFF      <= COND xor PREDICTION_2;     -- DIFF is 1 when the prediction != actual outcome
    MISS      <= DIFF and CNDS(0);          -- BRANCH is 1 when DIFF is 1 and the instruction is a branch (CNDS[0]=1)
    NPC_SEL   <= MISS and not(NPC_SEL_RST); -- NPC_SEL is 1 when BRANCH=1 and NPC_SEL_RST=0 (not a reset)
    FLUSH_REQ <= NPC_SEL;                   -- FLUSH_REQ is asserted when NPC_SEL is 1 (to correct branch misprediction)

    -- MUX_CORRECTED_INSTR_ADDR: chooses between ALU_OUT_D (mispredicted not taken) and PC_INCR_EX_Q (mispredicted taken)
    MUX_CORRECTED_INSTR_ADDR : MUX_2_1 generic map(
        N   => ADDR_WIDTH) port map(
        a1  => PC_INCR_EX_Q,
        a2  => ALU_OUT_D,
        Sel => COND,
        o   => CORRECTED_INSTR_ADDR
    );

    -- ALU_OUT: register containing output of ALU
    ALU_OUT : REG generic map(N => DATA_WIDTH) port map(D => ALU_OUT_D, CLK => Clk, Rst => Rst, EN => EXMEMEN, Q => ALU_OUT_Q);

    -- IN_DATA: register containing input data of Data Memory (RF_OUT_2_Q)
    IN_DATA : REG generic map(N => DATA_WIDTH) port map(D => B, CLK => Clk, Rst => Rst, EN => EXMEMEN, Q => IN_DATA_Q);

    -- EX_MEM_IR: pipeline register between EX and MEM containing instruction
    EX_MEM_IR : REG generic map(N => INSTRUCTION_WIDTH) port map(D => ID_EX_IR_Q, CLK => Clk, Rst => Rst, EN => EXMEMEN, Q => EX_MEM_IR_Q);

    -- PC_INCR_MEM_REG: pipeline register that forwards PC_INCR from EX to MEM stage
    PC_INCR_MEM : REG generic map(N => ADDR_WIDTH) port map(D => PC_INCR_EX_Q, CLK => Clk, Rst => Rst, EN => EXMEMEN, Q => PC_INCR_MEM_Q);

    ------------------------------------------------ MEMORY (MEM) ---------------------------------------------------

    -- MUX_DM_IN: outputs the register to write in Data Memory, choosing between the value read from RF and the forwarded ones
    MUX_DM_IN : MUX_4_1 generic map(N => DATA_WIDTH)
    port map(
        a1  => IN_DATA_Q,
        a2  => ALU_OUT_2_Q,
        a3  => LMD_Q,
        a4  => PC_INCR_WB_Q,
        sel => FWD_DM_SEL,
        o   => DM_IN
    );

    -- DATA_CACHE
    CACHE : DATA_CACHE generic map(
        FILE_PATH            => "./memory_files/data_cache.mem",
        MEMORY_ACCESS_CYCLES => DATA_DELAY,
        K                    => WORD_ADDR_WIDTH,
        R                    => CACHE_LINE_ADDR_WIDTH,
        W                    => CACHE_WORD_OFFSET_WIDTH
    )
    port map(
        clk                 => clk,
        rst                 => Rst,
        enable              => DM_EN,
        ctrl                => DMB,
        is_signed           => DMS,
        addr                => ALU_OUT_Q,
        data_in             => DM_IN,
        data_out            => LMD_D,
        RnW                 => RnW,
        addr_to_memory      => ADDR_TO_DM,
        data_in_from_memory => DATA_FROM_DM,
        data_out_to_memory  => DATA_TO_DM,
        RnW_memory          => RnW_DM,
        miss                => CACHE_MISS,
        enable_memory       => ENABLE_DM
    );

    -- LMD: Load Memory Data. Stores the output of the Data Memory
    LMD : REG generic map(N => DATA_WIDTH) port map(D => LMD_D, CLK => Clk, Rst => Rst, EN => MEMWBEN, Q => LMD_Q);

    -- ALU_OUT_2: forwards ALU_OUT_Q from MEM stage to WB stage in case it has to be written back
    ALU_OUT_2 : REG generic map(N => DATA_WIDTH) port map(D => ALU_OUT_Q, CLK => Clk, Rst => Rst, EN => MEMWBEN, Q => ALU_OUT_2_Q);

    -- MEM_WB_IR: pipeline register between MEM and WB containing instruction
    MEM_WB_IR : REG generic map(N => INSTRUCTION_WIDTH) port map(D => EX_MEM_IR_Q, CLK => Clk, Rst => Rst, EN => MEMWBEN, Q => MEM_WB_IR_Q);

    -- PC_INCR_WB_REG: pipeline register that forwards PC_INCR from MEM to WB stage
    PC_INCR_WB : REG generic map(N => ADDR_WIDTH) port map(D => PC_INCR_MEM_Q, CLK => Clk, Rst => Rst, EN => MEMWBEN, Q => PC_INCR_WB_Q);

    -------------------------------------------------- WRITE BACK --------------------------------------------------- 
    -- MUX_WB: chooses the signal to write-back, between LMD_Q, ALU_OUT_2_Q and PC_INCR_WB_Q
    MUX_WB : MUX_4_1 generic map(N => DATA_WIDTH)
    port map(
        a1  => LMD_Q,
        a2  => ALU_OUT_2_Q,
        a3  => PC_INCR_WB_Q,
        a4 => (others => '0'),
        sel => WBS,
        o   => WB_DATA
    );

    MEM_WB_IR_RS2 <= MEM_WB_IR_Q(20 downto 16);
    MEM_WB_IR_RD  <= MEM_WB_IR_Q(15 downto 11);

    -- MUX_RD: chooses the destination address of the register file in the write-back stage, between MEM/WB.IR[rd] (R-type), MEM/WB.IR[rs2] (I-type) and r31 (JAL)
    MUX_RD : MUX_4_1 generic map(N => REG_ADDR_WIDTH)
    port map(
        a1  => MEM_WB_IR_RS2,
        a2  => MEM_WB_IR_RD,
        a3  => "11111",
        a4 => (others => '0'),
        sel => RDS,
        o   => RD
    );

    -------------------------------------------- * END OF DATAPATH PIPELINE * ----------------------------------------- 
    --/* OTHER LOGIC */

    -- FORWARDING AND STALLING LOGIC
    FWD_LOG : FORWARDING_STALLING_LOGIC
    port map(
        IF_ID_IR              => IR_Q,
        ID_EX_IR              => ID_EX_IR_Q,
        EX_MEM_IR             => EX_MEM_IR_Q,
        MEM_WB_IR             => MEM_WB_IR_Q,
        FWD_ALU_to_A          => fwd(0),
        FWD_ALU2_to_A         => fwd(1),
        FWD_LMD_to_A          => fwd(2),
        FWD_ALU_to_B          => fwd(3),
        FWD_ALU2_to_B         => fwd(4),
        FWD_LMD_to_B          => fwd(5),
        FWD_ALU2_to_DM        => fwd(6),
        FWD_LMD_to_DM         => fwd(7),
        FWD_PC_INCR_WB_to_DM  => fwd(8),
        FWD_ALU_to_JR         => fwd(9),
        FWD_PC_INCR_EX_to_JR  => fwd(10),
        FWD_PC_INCR_MEM_to_JR => fwd(11),
        STALL_EX_MEM          => STALL_EX_MEM,
        STALL_ID_EX           => STALL_ID_EX,
        n_cycles_stall        => n_cycles_stall
    );

end STRUCT;

configuration CFG_DATAPATH of DATAPATH is
    for STRUCT
        for all : MUX_4_1
            use configuration WORK.CFG_MUX_4_1_STRUCTURAL;
        end for;
        for all : MUX_2_1
            use configuration WORK.CFG_MUX_2_1_STRUCTURAL;
        end for;
    end for;
end CFG_DATAPATH;