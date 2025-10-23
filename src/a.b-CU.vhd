library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use WORK.DLX_Types.all;

entity Hardwired_CU is
    port (
        -- # /* INPUT PORTS*/

        -- ## CLOCK AND RESET SIGNALS
        Clk    : in std_logic;
        Rst    : in std_logic; -- Active High
        -- ## OPCODE AND FUNC FIELDS
        OPCODE : in std_logic_vector(OP_CODE_SIZE - 1 downto 0);
        FUNC   : in std_logic_vector(FUNC_SIZE - 1 downto 0);
        -- ## BRANCH PREDICTION
        PREDICTION : in std_logic;
        -- ## BRANCH CORRECTION FLUSH REQUEST
        FLUSH_REQ : in std_logic;
        -- ## RAW HAZARD STALL REQUESTS
        STALL_EX_MEM   : in std_logic;  -- request to stall EX/MEM stage
        STALL_ID_EX    : in std_logic;  -- request to stall ID/EX stage
        n_cycles_stall : in integer;    -- number of cycles to stall
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
end Hardwired_CU;

architecture Behavioral of Hardwired_CU is

    -- PIPELINE CONTROL

    --control word signals

    -- ID
    --    cw[19] = UIS          ; Upper Immediate Signal
    --    cw[18] = SUS          ; Signed Unsigned (Immediate) Signal
    --    cw[17] = SES          ; Sign-Extender Selection 
    --    cw[16] = RF1          ; RF read port 1 enable
    --    cw[15] = RF2          ; RF read port 2 enable
    --    cw[14] = JUMPS        ; Jump select
    -- EX
    --    cw[13] = BS	        ; B Selection
    --    cw[12] = AS	        ; A Selection
    --    cw[11:10] = CNDS      ; COND Selection
    -- MEM
    --    cw[9] = DMS           ; Data Memory Signed
    --    cw[8:7] = DMB         ; Data Memory Bytes
    --    cw[6] = RnW	        ; Read-not-Write (Data Memory) 
    --    cw[5] = DM_EN         ; Data Memory Enable
    -- WB
    --    cw[4:3] = WBS	        ; Write Back Selection
    --    cw[2] = WRF           ; RF write port enable
    --    cw[1:0] = RDS         ; Register Destination Selection

    type mem_array is array (integer range 0 to MICROCODE_MEM_SIZE - 1) of std_logic_vector(CW_SIZE - 1 downto 0);
    -- LUT generating for each instruction the corresponding control signals (excluding ALU control signals,
    -- that are generated separately)

    signal cw_mem : mem_array := (
        --           JIHGFEDCBA9876543210
        0        => "00011000000001001101", -- 0. R-type
        1        => "00000000000000000000", -- 1. //
        2        => "00100011000001000000", -- 2. JTYPE_J,
        3        => "00100011000001010110", -- 3. JTYPE_JAL,
        4        => "00010011010001000000", -- 4. ITYPE_BEQZ
        5        => "00010011110001000000", -- 5. ITYPE_BNEZ
        6        => "00000000000000000000", -- 6. //
        7        => "00000000000000000000", -- 7. //
        8        => "00010010000001001100", -- 8. ITYPE_ADDI
        9        => "01010010000001001100", -- 9. ITYPE_ADDUI
        10       => "00010010000001001100", -- 10. ITYPE_SUBI
        11       => "01010010000001001100", -- 11. ITYPE_SUBUI
        12       => "00010010000001001100", -- 12. ITYPE_ANDI
        13       => "00010010000001001100", -- 13. ITYPE_ORI
        14       => "00010010000001001100", -- 14. ITYPE_XORI
        15       => "10010010000001001100", -- 15. ITYPE_LHI
        16       => "00000000000000000000", -- 16. //
        17       => "00000000000000000000", -- 17. //
        18       => "00010110000001000000", -- 18. ITYPE_JR
        19       => "00010110000001010110", -- 19. ITYPE_JALR
        20       => "00010010000001001100", -- 20. ITYPE_SLLI
        21       => "00000000000000000000", -- 21. NOP 
        22       => "00010010000001001100", -- 22. ITYPE_SRLI
        23       => "01010010000001001100", -- 23. ITYPE_SRAI
        24       => "00010010000001001100", -- 24. ITYPE_SEQI
        25       => "00010010000001001100", -- 25. ITYPE_SNEI
        26       => "00010010000001001100", -- 26. ITYPE_SLTI
        27       => "00010010000001001100", -- 27. ITYPE_SGTI
        28       => "00010010000001001100", -- 28. ITYPE_SLEI
        29       => "00010010000001001100", -- 29. ITYPE_SGEI
        30       => "00000000000000000000", -- 30. //
        31       => "00000000000000000000", -- 31. //
        32       => "00010010001001100100", -- 32. ITYPE_LB
        33       => "00010010001011100100", -- 33. ITYPE_LH
        34       => "00000000000000000000", -- 34. //
        35       => "00010010001101100100", -- 35. ITYPE_LW
        36       => "00010010000001100100", -- 36. ITYPE_LBU
        37       => "00010010000011100100", -- 37. ITYPE_LHU
        38       => "00000000000000000000", -- 38. //
        39       => "00000000000000000000", -- 39. //
        40       => "00011010000000100000", -- 40. ITYPE_SB
        41       => "00011010000010100000", -- 41. ITYPE_SH
        42       => "00000000000000000000", -- 42. //
        43       => "00011010000100100000", -- 43 ITYPE_SW
        44 to 57 => "00000000000000000000", -- //
        58       => "01010010000001001100", -- 58. ITYPE_SLTUI
        59       => "01010010000001001100", -- 59. ITYPE_SLTUI
        60       => "01010010000001001100", -- 60. ITYPE_SLEUI
        61       => "01010010000001001100"  -- 61. ITYPE_SGEUI
    );

    signal cw : std_logic_vector(CW_SIZE - 1 downto 0); -- full control word read from cw_mem

    -- stage specific control words
    --signal cw1         : std_logic_vector(CW_SIZE - 1 downto 0);           -- first stage - ID
    signal cw2 : std_logic_vector(CW_SIZE - 1 - 6 downto 0);         -- second stage - EX
    signal cw3 : std_logic_vector(CW_SIZE - 1 - 6 - 4 downto 0);     -- third stage - MEM
    signal cw4 : std_logic_vector(CW_SIZE - 1 - 6 - 4 - 5 downto 0); -- fourth stage - WB

    -- ALU control signals
    signal aluOpcode_i : aluOp; -- aluOp defined in package DLX_Types
    signal aluOpcode1  : aluOp;
    -- pipeline register enable signals
    signal WBIFEN_s, IFIDEN_s, IDEXEN_s, EXMEMEN_s, MEMWBEN_s : std_logic;
    -- Bits -> 4: WBIFEN, 3: IFIDEN, 2: IDEXEN, 1: EXMEMEN, 0: MEMWBEN
    signal enableSignals : std_logic_vector(4 downto 0);

    -- FLUSH and STALL control signals
    type StateType is (WaitForReq, JumpState, BranchPred, FixBranchPred, IDEXStall, EXMEMStall, CacheMiss);
    signal state, nextState               : StateType;
    signal flushCounter, nextFlushCounter : integer; -- n° cycles of flushing
    signal stallCounter, nextStallCounter : integer; -- n° cycles of stalling
begin

    cw <= cw_mem(conv_integer(unsigned(OPCODE)));

    -- DECODE stage control signals
    UIS   <= cw(CW_SIZE - 1);
    SUS   <= cw(CW_SIZE - 2);
    SES   <= cw(CW_SIZE - 3);
    RF1   <= cw(CW_SIZE - 4);
    RF2   <= cw(CW_SIZE - 5);
    JUMPS <= cw(CW_SIZE - 6);

    -- EXECUTION stage control signals
    BS   <= cw2(CW_SIZE - 7);
    AS   <= cw2(CW_SIZE - 8);
    CNDS <= cw2(CW_SIZE - 9 downto CW_SIZE - 10);

    -- MEMORY stage control signals
    DMS   <= cw3(CW_SIZE - 11);
    DMB   <= cw3(CW_SIZE - 12 downto CW_SIZE - 13);
    RnW   <= cw3(CW_SIZE - 14);
    DM_EN <= cw3(CW_SIZE - 15);

    -- WRITE BACK stage control signals
    WBS <= cw4(CW_SIZE - 16 downto CW_SIZE - 17);
    WRF <= cw4(CW_SIZE - 18);
    RDS <= cw4(CW_SIZE - 19 downto CW_SIZE - 20);

    -- ALU control signals
    ALUS <= aluOpcode1;

    -- register enable signals
    WBIFEN_s  <= enableSignals(4); --WB/IF pipeline register enable
    IFIDEN_s  <= enableSignals(3); --IF/ID pipeline register enable
    IDEXEN_s  <= enableSignals(2); --ID/EX pipeline register enable
    EXMEMEN_s <= enableSignals(1); --EX/MEM pipeline register enable
    MEMWBEN_s <= enableSignals(0); --MEM/WB pipeline register enable

    WBIFEN  <= WBIFEN_s;
    IFIDEN  <= IFIDEN_s;
    IDEXEN  <= IDEXEN_s;
    EXMEMEN <= EXMEMEN_s;
    MEMWBEN <= MEMWBEN_s;

    -- process to pipeline control word
    CW_PIPE : process (Clk, Rst)
    begin
        if Rst = '1' then
            cw2        <= (others => '0');
            cw3        <= (others => '0');
            cw4        <= (others => '0');
            aluOpcode1 <= (others => '0');
        elsif rising_edge(Clk) then -- rising clock edge 	
            if (IDEXEN_s = '1') then
                cw2        <= cw(CW_SIZE - 1 - 6 downto 0);
                aluOpcode1 <= aluOpcode_i;
            end if;
            if (EXMEMEN_s = '1') then
                cw3 <= cw2(CW_SIZE - 1 - 6 - 4 downto 0);
            end if;
            if (MEMWBEN_s = '1') then
                cw4 <= cw3(CW_SIZE - 1 - 6 - 4 - 5 downto 0);
            end if;
        end if;
    end process CW_PIPE;
    --ALU control signals

    --    aluOpcode[10:8] -> S_OUT
    --    aluOpcode[7] -> Cin
    --    aluOpcode[6] -> SnU
    --    aluOpcode[5] -> EQnNE
    --    aluOpcode[4:2] -> S_LOGIC
    --    aluOpcode[1] -> LEFT_RIGHT
    --    aluOpcode[0] -> LOGIC_ARITH 
    -- process to generate alu opcode
    ALU_OP_CODE_P : process (OPCODE, FUNC)
    begin
        case conv_integer(unsigned(OPCODE)) is
                -- when instruction is R-type, we look at FUNC
            when 0 =>
                -- R-type
                case conv_integer(unsigned(FUNC)) is
                    when 4  => aluOpcode_i  <= "111" & "000000" & "10";          -- SLL
                    when 6  => aluOpcode_i  <= "111" & "000000" & "00";          -- SRL
                    when 7  => aluOpcode_i  <= "111" & "000000" & "01";          -- SRA
                    when 32 => aluOpcode_i <= "000" & '0' & "0000000";           -- ADD
                    when 33 => aluOpcode_i <= "000" & '0' & "0000000";           -- ADDU (same as ADD)
                    when 34 => aluOpcode_i <= "000" & '1' & "0000000";           -- SUB
                    when 35 => aluOpcode_i <= "000" & '1' & "0000000";           -- SUBU (same as SUB)
                    when 36 => aluOpcode_i <= "110" & "000" & "001" & "00";      -- AND
                    when 37 => aluOpcode_i <= "110" & "000" & "110" & "00";      -- OR
                    when 38 => aluOpcode_i <= "110" & "000" & "111" & "00";      -- XOR
                    when 40 => aluOpcode_i <= "101" & '1' & '0' & '1' & "00000"; -- SEQ
                    when 41 => aluOpcode_i <= "101" & '1' & '0' & '0' & "00000"; -- SNE
                    when 42 => aluOpcode_i <= "100" & '1' & '1' & "000000";      -- SLT
                    when 43 => aluOpcode_i <= "011" & '1' & '1' & "000000";      -- SGT
                    when 44 => aluOpcode_i <= "010" & '1' & '1' & "000000";      -- SLE
                    when 45 => aluOpcode_i <= "001" & '1' & '1' & "000000";      -- SGE
                    when 58 => aluOpcode_i <= "100" & '1' & '0' & "000000";      -- SLTU
                    when 59 => aluOpcode_i <= "011" & '1' & '0' & "000000";      -- SGTU
                    when 60 => aluOpcode_i <= "010" & '1' & '0' & "000000";      -- SLEU
                    when 61 => aluOpcode_i <= "001" & '1' & '0' & "000000";      -- SGEU

                    when others => aluOpcode_i <= (others => '0'); --default operation
                end case;
                -- I-type 
            when 10 | 11 => aluOpcode_i <= "000" & '1' & "0000000";                -- subi | subui => SUB
            when 12      => aluOpcode_i      <= "110" & "000" & "001" & "00";      -- andi => AND
            when 13      => aluOpcode_i      <= "110" & "000" & "110" & "00";      -- ori => OR
            when 14      => aluOpcode_i      <= "110" & "000" & "111" & "00";      -- xori => XOR
            when 20      => aluOpcode_i      <= "111" & "000000" & "10";           -- slli => SLL
            when 22      => aluOpcode_i      <= "111" & "000000" & "00";           -- srli => SRL
            when 23      => aluOpcode_i      <= "111" & "000000" & "01";           -- srai => SRA
            when 24      => aluOpcode_i      <= "101" & '1' & '0' & '1' & "00000"; -- seqi => SEQ
            when 25      => aluOpcode_i      <= "101" & '1' & '0' & '0' & "00000"; -- snei => SNE
            when 26      => aluOpcode_i      <= "100" & '1' & '1' & "000000";      -- snei => SLT
            when 27      => aluOpcode_i      <= "011" & '1' & '1' & "000000";      -- sgti => SGT
            when 28      => aluOpcode_i      <= "010" & '1' & '1' & "000000";      -- slei => SLE
            when 29      => aluOpcode_i      <= "001" & '1' & '1' & "000000";      -- sgei => SGE
            when 58      => aluOpcode_i      <= "100" & '1' & '0' & "000000";      -- sltui => SLTU
            when 59      => aluOpcode_i      <= "011" & '1' & '0' & "000000";      -- sgtui => SGTU
            when 60      => aluOpcode_i      <= "010" & '1' & '0' & "000000";      -- sleui => SLEU
            when 61      => aluOpcode_i      <= "001" & '1' & '0' & "000000";      -- sgeui => SGEU
            when others => aluOpcode_i  <= (others => '0');
        end case;
    end process ALU_OP_CODE_P;

    -- /* FORWARDING LOGIC CONTROL */
    -- fwd is a 12-bit vector of signals produced by the forwarding logic (datapath), directed to CU

    -- fwd[11] = FWD_PC_INCR_MEM_to_JR -- forward from PC_INCR in MEM stage to JR address input
    -- fwd[10] = FWD_PC_INCR_EX_to_JR  -- forward from PC_INCR in EX stage to JR address input
    -- fwd[9]  = FWD_ALU_to_JR         -- forward from ALU_OUT in MEM stage to JR address input
    -- fwd[8]  = FWD_PC_INCR_WB_to_DM  -- forward from PC_INCR in WB stage to DM input
    -- fwd[7] = FWD_LMD_to_DM          -- forward from LMD register to DM input
    -- fwd[6] = FWD_ALU2_to_DM         -- forward from ALU_OUT_2 to DM input
    -- fwd[5] = FWD_LMD_to_B           -- forward from LMD to B (ALU input 2)
    -- fwd[4] = FWD_ALU2_to_B          -- forward from ALU_OUT_2 to B (ALU input 2)
    -- fwd[3] = FWD_ALU_to_B           -- forward from ALU_OUT to B (ALU input 2)
    -- fwd[2] = FWD_LMD_to_A           -- forward from LMD to A (ALU input 1)
    -- fwd[1] = FWD_ALU2_to_A          -- forward from ALU_OUT_2 to A (ALU input 1)
    -- fwd[0] = FWD_ALU_to_A           -- forward from ALU_OUT to A (ALU input 1)

    FWD_LOGIC : process (fwd)
    begin

        -- forward to A
        if (fwd(0) = '1') then
            FWD_A_SEL <= "10"; -- A <= ALU_OUT_Q
        elsif (fwd(1) = '1') then
            FWD_A_SEL <= "00"; -- A <= ALU_OUT_2_Q
        elsif (fwd(2) = '1') then
            FWD_A_SEL <= "01"; -- A <= LMD_Q
        else
            FWD_A_SEL <= "11"; -- A <= RF_OUT_1_Q
        end if;

        -- forward to B
        if (fwd(3) = '1') then
            FWD_B_SEL <= "11"; -- B <= ALU_OUT_Q
        elsif (fwd(4) = '1') then
            FWD_B_SEL <= "10"; -- B <= ALU_OUT_2_Q
        elsif (fwd(5) = '1') then
            FWD_B_SEL <= "01"; -- B <= LMD_Q
        else
            FWD_B_SEL <= "00"; -- B <= RF_OUT_2_Q
        end if;

        -- forward to DM_IN
        if (fwd(6) = '1') then
            FWD_DM_SEL <= "01"; -- DM_IN <= ALU_OUT_2_Q
        elsif (fwd(7) = '1') then
            FWD_DM_SEL <= "10"; -- DM_IN <= LMD_Q
        elsif (fwd(8) = '1') then
            FWD_DM_SEL <= "11"; -- DM_IN <= PC_INCR_WB_Q
        else
            FWD_DM_SEL <= "00"; -- DM_IN <= IN_DATA_Q
        end if;

        -- forward to JR address input
        if (fwd(10) = '1') then
            FWD_JR_SEL <= "11"; -- JR address input <= PC_INCR_EX_Q
        elsif (fwd(11) = '1') then
            FWD_JR_SEL <= "10"; -- JR address input <= PC_INCR_MEM_Q
        elsif (fwd(9) = '1') then
            FWD_JR_SEL <= "01"; -- JR address input <= ALU_OUT_Q
        else
            FWD_JR_SEL <= "00"; -- JR address input <= RF_OUT_1
        end if;
    end process FWD_LOGIC;

    -- /* FLUSH AND STALL CONTROL */
    -- The control unit implements a simple Mealy FSM that manages:
    -- Jumps, Branch prediction, Branch prediction correction
    -- and Stalls due to RAW hazards that can't be solved by forwarding 

    -- enableSignals(4) = WBIFEN_s (WB/IF pipeline register enable)
    -- enableSignals(3) = IFIDEN_s (IF/ID pipeline register enable)
    -- enableSignals(2) = IDEXEN_s (ID/EX pipeline register enable)
    -- enableSignals(1) = EXMEMEN_s (EX/MEM pipeline register enable)
    -- enableSignals(0) = MEMWBEN_s (MEM/WB pipeline register enable)

    FLUSH_STALL_STATE : process (Clk, Rst)
    begin
        if (Rst = '1') then
            flushCounter <= 0;
            stallCounter <= 0;
            state        <= WaitForReq;
        elsif (rising_edge(Clk)) then
            flushCounter <= nextFlushCounter;
            stallCounter <= nextStallCounter;
            state        <= nextState;
        end if;
    end process;

    FLUSH_STALL_COMB_LOGIC : process (OPCODE,
        FLUSH_REQ,
        STALL_EX_MEM,
        STALL_ID_EX,
        n_cycles_stall,
        state,
        stallCounter,
        flushCounter,
        PREDICTION,
        CACHE_MISS
        )
    begin

        -- default behaviour
        enableSignals <= "11111"; --all pipeline registers enabled
        NPC_SEL_RST   <= '0';
        nextState     <= state;
        JUMP          <= '0'; -- jump select signal
        BRANCH        <= '0'; -- branch select signal 

        case state is

            when WaitForReq =>
                if (CACHE_MISS = '1') then
                    enableSignals <= "00000"; -- stall pipeline (only MEM/WB enabled)
                    nextState     <= CacheMiss;
                elsif (FLUSH_REQ = '1') then
                    nextFlushCounter <= 1;
                    enableSignals    <= "11011"; -- ID/EX pipeline register disabled as soon as FLUSH_REQ is received
                    nextState        <= FixBranchPred;
                elsif (STALL_EX_MEM = '1') then
                    enableSignals    <= "00001"; -- all pipeline registers up to EX/MEM are disabled
                    nextStallCounter <= n_cycles_stall;
                    nextState        <= EXMEMStall;
                elsif (STALL_ID_EX = '1') then
                    enableSignals    <= "00011"; -- all pipeline registers up to ID/EX are disabled
                    nextStallCounter <= n_cycles_stall;
                    nextState        <= IDEXStall;
                elsif (is_jump(OPCODE)) then
                    JUMP          <= '1';     -- jump signal
                    enableSignals <= "10111"; -- IF/ID pipeline register disabled to flush the instruction after the jump
                    nextState     <= JumpState;
                elsif (is_branch(OPCODE) and PREDICTION = '1') then
                    BRANCH        <= '1';     -- branch signal
                    enableSignals <= "10111"; -- IF/ID pipeline register disabled to flush the instruction after the branch
                    nextState     <= BranchPred;
                end if;

            when JumpState =>
                nextState <= WaitForReq;

            when BranchPred =>
                nextState <= WaitForReq;
                if (FLUSH_REQ = '1') then
                    nextFlushCounter <= 1;
                    enableSignals    <= "11011"; -- ID/EX pipeline register disabled as soon as FLUSH_REQ is received
                    nextState        <= FixBranchPred;
                end if;

            when FixBranchPred =>

                NPC_SEL_RST <= '1';

                if (flushCounter > 0) then
                    -- correct instruction entered IF stage. wrong instruction in ID
                    nextFlushCounter <= flushCounter - 1;
                    enableSignals    <= "11011"; -- ID/EX pipeline registers disabled
                else
                    -- correct instruction entered ID stage. normal operation
                    nextState <= WaitForReq;
                    if (is_jump(OPCODE)) then
                        JUMP          <= '1';     -- jump signal
                        enableSignals <= "10111"; -- IF/ID pipeline disabled to flush the instruction after the jump
                        nextState     <= JumpState;
                    elsif (is_branch(OPCODE) and PREDICTION = '1') then
                        BRANCH        <= '1';     -- branch signal
                        enableSignals <= "10111"; -- IF/ID pipeline register disabled to flush the instruction after the branch
                        nextState     <= BranchPred;
                    end if;
                end if;

            when EXMEMStall =>
                if (stallCounter > 1) then
                    nextStallCounter <= stallCounter - 1;
                    enableSignals    <= "00001"; -- all pipeline registers up to EX/MEM are disabled
                    nextState        <= EXMEMStall;
                else
                    nextState <= WaitForReq;
                    if (STALL_ID_EX = '1') then
                        enableSignals    <= "00011"; -- all pipeline registers up to ID/EX are disabled
                        nextStallCounter <= n_cycles_stall;
                        nextState        <= IDEXStall;
                    elsif (is_jump(OPCODE)) then
                        JUMP          <= '1';     -- jump signal
                        enableSignals <= "10111"; -- IF/ID pipeline register disabled to flush the instruction after the jump
                        nextState     <= JumpState;
                    elsif (is_branch(OPCODE) and PREDICTION = '1') then
                        BRANCH        <= '1';     -- branch signal
                        enableSignals <= "10111"; -- IF/ID pipeline register disabled to flush the instruction after the branch
                        nextState     <= BranchPred;
                    end if;

                end if;

            when IDEXStall =>
                if (stallCounter > 1) then
                    nextStallCounter <= stallCounter - 1;
                    enableSignals    <= "00011"; -- all pipeline registers up to EX/MEM are disabled
                    nextState        <= IDEXStall;
                else
                    nextState <= WaitForReq;
                    if (is_jump(OPCODE)) then
                        JUMP          <= '1';     -- jump signal
                        enableSignals <= "10111"; -- IF/ID pipeline register disabled to flush the instruction after the jump
                        nextState     <= JumpState;
                    end if;
                    enableSignals(1) <= '0';
                end if;

            when CacheMiss =>
                enableSignals <= "00000";
                if (CACHE_MISS = '0') then
                    nextState <= WaitForReq;
                end if;

            when others =>
                nextState <= WaitForReq;
        end case;

    end process;
end Behavioral;