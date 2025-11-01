library IEEE;
use IEEE.std_logic_1164.all;
use WORK.DLX_Types.all;

entity DATAPATH_TB is
end DATAPATH_TB;

architecture TBARCH of DATAPATH_TB is

    component DATAPATH is
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
            CACHE_MISS : out std_logic
        );
    end component DATAPATH;

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


    -- control words
    signal cw : std_logic_vector(CW_SIZE - 1 downto 0); -- full control word read from cw_mem
    signal cw2 : std_logic_vector(CW_SIZE - 1 - 6 downto 0);         -- second stage - EX
    signal cw3 : std_logic_vector(CW_SIZE - 1 - 6 - 4 downto 0);     -- third stage - MEM
    signal cw4 : std_logic_vector(CW_SIZE - 1 - 6 - 4 - 5 downto 0); -- fourth stage - WB

    signal aluOpcode1, aluOpcode2 : std_logic_vector(8 downto 0);

begin

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

    ALUS_s <= aluOpcode1;

    dp : DATAPATH port map(

        Clk => Clk,
        Rst => Rst,

        ------ # INPUTS FROM CU # ------

        -- ## REGULAR CONTROL SIGNALS
        UIS   => UIS_s,
        SUS   => SUS_s,
        SES   => SES_s,
        RF1   => RF1_s,
        RF2   => RF2_s,
        JUMPS => JUMPS_s,
        BS    => BS_s,
        AS    => AS_s,
        CNDS  => CNDS_s,
        ALUS  => ALUS_s,
        DMS   => DMS_s,
        DMB   => DMB_s,
        RnW   => RnW_s,
        DM_EN => DM_EN_s,
        WBS   => WBS_s,
        WRF   => WRF_s,
        RDS   => RDS_s,
        -- ## SPECIAL CONTROL SIGNALS
        -- ### PIPELINE REGISTER ENABLE CONTROL SIGNALS
        IFIDEN  => IFIDEN_s,
        IDEXEN  => IDEXEN_s,
        EXMEMEN => EXMEMEN_s,
        MEMWBEN => MEMWBEN_s,
        WBIFEN  => WBIFEN_s,
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

        ------ # OUTPUTS TO CU # ------

        -- ## OPCODE AND FUNC
        OPCODE => OPCODE,
        FUNC   => FUNC,
        -- ## BRANCH PREDICTION 
        PREDICTION => PREDICTION_s,
        -- ## FLUSH REQUEST FOR BRANCH CORRECTION
        FLUSH_REQ => FLUSH_REQ_s,
        -- ## RAW HAZARDS STALL REQUESTS
        STALL_EX_MEM   => STALL_EX_MEM_s,
        STALL_ID_EX    => STALL_ID_EX_s,
        n_cycles_stall => n_cycles_stall_s,
        -- ## FORWARDING LOGIC SIGNALS
        fwd => fwd_s,
        -- ## CACHE MISS SIGNAL
        CACHE_MISS => CACHE_MISS_s
    );

    clock_process : process
    begin
        Clk <= '0';
        wait for 5ns;
        Clk <= '1';
        wait for 5ns;
    end process;

    -- always enabled signals
    IFIDEN_s  <= '1';
    IDEXEN_s  <= '1';
    EXMEMEN_s <= '1';
    MEMWBEN_s <= '1';
    WBIFEN_s  <= '1';

    cu_sim_process : process (Clk, Rst)
    begin
        if (Rst = '1') then
            cw2        <= (others => '0');
            cw3        <= (others => '0');
            cw4        <= (others => '0');
            aluOpcode2 <= (others => '0');
        elsif (rising_edge(Clk)) then
            cw2        <= cw1(6 downto 0);
            cw3        <= cw2(2 downto 0);
            cw4        <= cw3(1 downto 0);
            aluOpcode2 <= aluOpcode1;
        end if;
    end process;

    tb_process : process
    begin
        --initial values
        Rst      <= '0';
        cw        <= "00000000000000000000";
        aluOpcode1 <= "000000000";

        wait for 2ns;
        Rst <= '1';
        wait for 5ns;
        Rst <= '0';

        wait for 5ns;

        wait until rising_edge(Clk);
        cw        <= "00010010000001001100";    -- addi
        aluOpcode1 <= "00000000000"; --add

        wait;
    end process;

end TBARCH;