library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.DLX_Types.all;

entity cu_test is
end cu_test;

architecture TEST of cu_test is

    component Hardwired_CU
        port (
            -- # /* INPUT PORTS*/

            -- ## CLOCK AND RESET SIGNALS
            Clk : in std_logic;
            Rst : in std_logic; -- Active High
            -- ## OPCODE AND FUNC FIELDS
            OPCODE : in std_logic_vector(OP_CODE_SIZE - 1 downto 0);
            FUNC   : in std_logic_vector(FUNC_SIZE - 1 downto 0);
            -- ## BRANCH PREDICTION
            PREDICTION : in std_logic;
            -- ## BRANCH CORRECTION FLUSH REQUEST
            FLUSH_REQ : in std_logic;
            -- ## RAW HAZARD STALL REQUESTS
            STALL_EX_MEM   : in std_logic; -- request to stall EX/MEM stage
            STALL_ID_EX    : in std_logic; -- request to stall ID/EX stage
            n_cycles_stall : in integer;   -- number of cycles to stall
            -- ## FORWARDING LOGIC SIGNALS 
            fwd : in std_logic_vector(11 downto 0); -- concatenation of all forwarding signals
            -- ## CACHE MISS SIGNAL
            CACHE_MISS : in std_logic;

            -- # /* OUTPUT PORTS */
            -- ## REGULAR CONTROL SIGNALS 
            -- ### DECODE (ID) STAGE CONTROL 
            UIS   : out std_logic; -- selects to shift or not shift the immediate by 16 bits leftwards (0: no shift, 1: shift)
            SUS   : out std_logic; -- selects to consider the immediate as signed or unsigned (0: signed, 1: unsigned)
            SES   : out std_logic; -- selects the right sign-extension of the immediate ( 0: 16 -> 32, 1: 26 -> 32)
            RF1   : out std_logic; -- enables the read port 1 of the register file
            RF2   : out std_logic; -- enables the read port 2 of the register file
            JUMPS : out std_logic; -- selects correct target address for jump instructions
            -- ### EXECUTE (EXE) STAGE CONTROL
            BS   : out std_logic;                    -- selects the input B of the ALU (0: out2, 1: imm)
            AS   : out std_logic;                    -- selects the input A of the ALU (0: out1, 1: NPC)
            CNDS : out std_logic_vector(1 downto 0); -- selects the COND register input (00: 0 (normal behavior), 01: 1 (jump), 10: out1==0, 11: out1!=0) 
            ALUS : out aluOp;                        -- selects the ALU operation
            -- ### MEMORY (MEM) STAGE CONTROL
            DMS   : out std_logic;                    -- selects between a signed (1) or unsigned (0) value from memory
            DMB   : out std_logic_vector(1 downto 0); -- selects the number of bytes for the memory operation
            RnW   : out std_logic;                    -- selects read or write of data memory
            DM_EN : out std_logic;                    -- enables the data memory
            -- ### WRITE BACK (WB) STAGE CONTROL
            WBS : out std_logic_vector(1 downto 0); -- selects output to be written back (00: LMD, 01: ALU_out, 10: PC_INCR)
            WRF : out std_logic;                    -- enables the write port of the register file
            RDS : out std_logic_vector(1 downto 0); -- selects the right bits of the instruction as register destination address (00: RS2, 01: RD, 10: R31)
            -- ## SPECIAL CONTROL SIGNALS
            -- ### REGISTER ENABLE CONTROL
            WBIFEN, IFIDEN, IDEXEN, EXMEMEN, MEMWBEN : out std_logic; -- enable the respective pipeline registers when asserted
            -- ### FORWARDING LOGIC CONTROL
            FWD_A_SEL, FWD_B_SEL, FWD_DM_SEL, FWD_JR_SEL : out std_logic_vector(1 downto 0); -- select the right forwarding source
            -- ### JUMP AND BRANCH PREDICTION CONTROL
            JUMP   : out std_logic; -- do jump
            BRANCH : out std_logic; -- do branch prediction
            -- ### BRANCH CORRECTION CONTROL
            NPC_SEL_RST : out std_logic -- forces NPC_SEL signal to 0 when high
        );
    end component;

    signal Clock : std_logic := '0';
    signal Reset : std_logic := '1';

    -- DECODE STAGE CONTROL SIGNALS
    signal UIS_s   : std_logic;
    signal SUS_s   : std_logic;
    signal SES_s   : std_logic;
    signal RF1_s   : std_logic;
    signal RF2_s   : std_logic;
    signal JUMPS_s : std_logic;

    -- EXEC STAGE CONTROL SIGNALS
    signal BS_s   : std_logic;
    signal AS_s   : std_logic;
    signal CNDS_s : std_logic_vector(1 downto 0);
    signal ALUS_s : aluOp;

    -- MEM STAGE CONTROL SIGNALS
    signal DMS_s   : std_logic;
    signal DMB_s   : std_logic_vector(1 downto 0);
    signal RnW_s   : std_logic;
    signal DM_EN_s : std_logic;

    -- WRITE BACK STAGE CONTROL SIGNALS
    signal WBS_s : std_logic_vector(1 downto 0);
    signal WRF_s : std_logic;
    signal RDS_s : std_logic_vector(1 downto 0);

    -- INSTRUCTION OPCODE and FUNC fields
    signal OPCODE : std_logic_vector(OP_CODE_SIZE - 1 downto 0);
    signal FUNC   : std_logic_vector(FUNC_SIZE - 1 downto 0);

    -- FORWARDING
    signal fwd_s                                                : std_logic_vector(11 downto 0);
    signal FWD_A_SEL_s, FWD_B_SEL_s, FWD_DM_SEL_s, FWD_JR_SEL_s : std_logic_vector(1 downto 0);

    -- flush and stall request
    signal FLUSH_REQ_s                   : std_logic;
    signal STALL_EX_MEM_s, STALL_ID_EX_s : std_logic;
    signal n_cycles_stall_s              : integer;

    -- register enable signals
    signal WBIFEN_s, IFIDEN_s, IDEXEN_s, EXMEMEN_s, MEMWBEN_s : std_logic;
    signal NPC_SEL_RST_s                                       : std_logic;

    -- JUMP and BRANCH PREDICTION signals
    signal JUMP_s       : std_logic;
    signal BRANCH_s     : std_logic;
    signal PREDICTION_s : std_logic;

    -- CACHE MISS signal
    signal CACHE_MISS_s : std_logic;

    -- Other signals
    signal Clk, Rst : std_logic;

begin

    -- instance of CU
    dut : Hardwired_CU
    port map(
        ------ # INPUTS FROM DATAPATH # ------

        -- ## OPCODE AND FUNC FIELDS
        OPCODE => OPCODE,
        FUNC   => FUNC,
        -- ## BRANCH PREDICTION
        PREDICTION => PREDICTION_s,
        -- ## BRANCH CORRECTION FLUSH REQUEST
        FLUSH_REQ => FLUSH_REQ_s,
        -- ## RAW HAZARD STALL REQUESTS
        STALL_EX_MEM   => STALL_EX_MEM_s,
        STALL_ID_EX    => STALL_ID_EX_s,
        n_cycles_stall => n_cycles_stall_s,
        -- ## FORWARDING LOGIC SIGNALS
        fwd => fwd_s,
        -- ## CACHE MISS SIGNAL
        CACHE_MISS => CACHE_MISS_s,

        ------ # OUTPUTS TO DATAPATH # ------
        
        -- ## REGULAR CONTROL SIGNALS
        -- ### DECODE STAGE OUTPUTS
        UIS   => UIS_s,
        SUS   => SUS_s,
        SES   => SES_s,
        RF1   => RF1_s,
        RF2   => RF2_s,
        JUMPS => JUMPS_s,
        -- ### EXEC STAGE OUTPUTS
        BS   => BS_s,
        AS   => AS_s,
        CNDS => CNDS_s,
        ALUS => ALUS_s,
        -- ### MEM STAGE OUTPUTS
        DMS   => DMS_s,
        DMB   => DMB_s,
        RnW   => RnW_s,
        DM_EN => DM_EN_s,
        -- ### WRITE BACK STAGE OUTPUTS
        WBS => WBS_s,
        WRF => WRF_s,
        RDS => RDS_s,
        -- ## SPECIAL CONTROL SIGNALS
        -- ### PIPELINE REGISTER ENABLE SIGNALS
        WBIFEN  => WBIFEN_s,
        IFIDEN  => IFIDEN_s,
        IDEXEN  => IDEXEN_s,
        EXMEMEN => EXMEMEN_s,
        MEMWBEN => MEMWBEN_s,
        -- ### FORWARDING LOGIC CONTROL SIGNALS
        FWD_A_SEL  => FWD_A_SEL_s,
        FWD_B_SEL  => FWD_B_SEL_s,
        FWD_DM_SEL => FWD_DM_SEL_s,
        FWD_JR_SEL => FWD_JR_SEL_s,
        -- ### JUMP AND BRANCH PREDICTION CONTROL SIGNALS
        JUMP   => JUMP_s,
        BRANCH => BRANCH_s,
        -- ### BRANCH CORRECTION CONTROL SIGNALS
        NPC_SEL_RST => NPC_SEL_RST_s,
        Clk    => Clock,
        Rst    => Reset
    );

    Clock <= not Clock after 1 ns;
    Reset <= '0', '1' after 6 ns;

    CONTROL : process
    begin

        wait for 4 ns;
        -- add RD,RS1,RS2 -> Rtype
        cu_opcode_i <= RTYPE;
        cu_func_i   <= RTYPE_ADD;
        wait for 2 ns;
        -- add RD,RS1,RS2 -> Rtype
        cu_opcode_i <= RTYPE;
        cu_func_i   <= RTYPE_ADD;
        wait for 2 ns;
        -- add RD,RS1,RS2 -> Rtype
        cu_opcode_i <= RTYPE;
        cu_func_i   <= RTYPE_ADD;
        wait for 2 ns;
        -- add RD,RS1,RS2 -> Rtype
        cu_opcode_i <= RTYPE;
        cu_func_i   <= RTYPE_ADD;
        wait for 2 ns;
        -- -- SUB RS1,RS2,RD -> Rtype
        -- cu_opcode_i <= RTYPE;
        -- cu_func_i   <= RTYPE_SUB;
        -- wait for 2 ns;

        -- -- AND RS1,RS2,RD -> Rtype
        -- cu_opcode_i <= RTYPE;
        -- cu_func_i   <= RTYPE_AND;
        -- wait for 2 ns;

        -- -- OR RS1,RS2,RD -> Rtype
        -- cu_opcode_i <= RTYPE;
        -- cu_func_i   <= RTYPE_OR;
        -- wait for 2 ns;
        -- -- ADDI1 RS1,RD,INP1 -> Itype
        -- cu_opcode_i <= ITYPE_ADDI1;
        -- cu_func_i   <= NOP;
        -- wait for 2 ns;

        -- -- SUBI1 RS2,RD,INP1 -> Itype
        -- cu_opcode_i <= ITYPE_SUBI1;
        -- cu_func_i   <= NOP;
        -- wait for 2 ns;

        -- -- ANDI1 RS2,RD,INP1 -> Itype
        -- cu_opcode_i <= ITYPE_ANDI1;
        -- cu_func_i   <= NOP;
        -- wait for 2 ns;
        -- -- ORI1 RS2,RD,INP1 -> Itype
        -- cu_opcode_i <= ITYPE_ORI1;
        -- cu_func_i   <= NOP;
        -- wait for 2 ns;
        -- -- ADDI2 RS1,RD,INP2 -> Itype
        -- cu_opcode_i <= ITYPE_ADDI2;
        -- cu_func_i   <= NOP;
        -- wait for 2 ns;
        -- -- SUBI2 RS1,RD,INP2 -> Itype
        -- cu_opcode_i <= ITYPE_SUBI2;
        -- cu_func_i   <= NOP;
        -- wait for 2 ns;
        -- -- ANDI2 RS1,RD,INP2 -> Itype
        -- cu_opcode_i <= ITYPE_ANDI2;
        -- cu_func_i   <= NOP;
        -- wait for 2 ns;

        -- -- ORI2 RS1,RD,INP2 -> Itype
        -- cu_opcode_i <= ITYPE_ORI2;
        -- cu_func_i   <= NOP;
        -- wait for 2 ns;
        -- -- MOV RS1,RD -> Itype
        -- cu_opcode_i <= ITYPE_MOV;
        -- cu_func_i   <= NOP;
        -- wait for 2 ns;
        -- -- S_REG1 RD,INP1 -> Itype
        -- cu_opcode_i <= ITYPE_S_REG1;
        -- cu_func_i   <= NOP;
        -- wait for 2 ns;
        -- -- S_REG2 RD,INP2 -> Itype
        -- cu_opcode_i <= ITYPE_S_REG2;
        -- cu_func_i   <= NOP;
        -- wait for 2 ns;

        -- -- S_MEM RS1,RS2,INP2 -> Itype
        -- cu_opcode_i <= ITYPE_S_MEM;
        -- cu_func_i   <= NOP;
        -- wait for 2 ns;
        -- -- L_MEM1 RS2,RD,INP1 -> Itype
        -- cu_opcode_i <= ITYPE_L_MEM1;
        -- cu_func_i   <= NOP;
        -- wait for 2 ns;
        -- -- L_MEM2 RS1,RD,INP2 -> Itype
        -- cu_opcode_i <= ITYPE_L_MEM2;
        -- cu_func_i   <= NOP;
        -- wait for 2 ns;
        wait;
    end process;

end TEST;