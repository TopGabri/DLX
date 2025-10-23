library ieee;
use ieee.std_logic_1164.all;
use WORK.DLX_Types.all;
entity DLX is
    port (
        Clk : in std_logic;
        Rst : in std_logic
    );
end DLX;

architecture STRUCTURAL of DLX is

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

    component Hardwired_CU is
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
    end component Hardwired_CU;

    -- # /* SIGNAL DECLARATIONS */

    -- ## REGULAR CONTROL SIGNALS
    -- ### DECODE STAGE OUTPUTS
    signal UIS_s   : std_logic;
    signal SUS_s   : std_logic;
    signal SES_s   : std_logic;
    signal RF1_s   : std_logic;
    signal RF2_s   : std_logic;
    signal JUMPS_s : std_logic;

    -- ### EXEC STAGE OUTPUTS
    signal BS_s   : std_logic;
    signal AS_s   : std_logic;
    signal CNDS_s : std_logic_vector(1 downto 0);
    signal ALUS_s : aluOp;

    -- ###MEM STAGE OUTPUTS
    signal DMS_s   : std_logic;
    signal DMB_s   : std_logic_vector(1 downto 0);
    signal RnW_s   : std_logic;
    signal DM_EN_s : std_logic;

    -- ### WRITE BACK STAGE OUTPUTS
    signal WBS_s : std_logic_vector(1 downto 0);
    signal WRF_s : std_logic;
    signal RDS_s : std_logic_vector(1 downto 0);

    -- ## INSTRUCTION OPCODE and FUNC fields
    signal OPCODE : std_logic_vector(OP_CODE_SIZE - 1 downto 0);
    signal FUNC   : std_logic_vector(FUNC_SIZE - 1 downto 0);

    -- ## FORWARDING
    signal fwd_s                                                : std_logic_vector(11 downto 0);
    signal FWD_A_SEL_s, FWD_B_SEL_s, FWD_DM_SEL_s, FWD_JR_SEL_s : std_logic_vector(1 downto 0);

    -- ## FLUSH AND STALL REQUESTS
    signal FLUSH_REQ_s                   : std_logic;
    signal STALL_EX_MEM_s, STALL_ID_EX_s : std_logic;
    signal n_cycles_stall_s              : integer;

    -- ## PIPELINE REGISTER ENABLE SIGNALS
    signal WBIFEN_s, IFIDEN_s, IDEXEN_s, EXMEMEN_s, MEMWBEN_s : std_logic;
    signal NPC_SEL_RST_s                                      : std_logic;

    -- JUMP and BRANCH PREDICTION SIGNALS
    signal JUMP_s       : std_logic;
    signal BRANCH_s     : std_logic;
    signal PREDICTION_s : std_logic;

    -- CACHE MISS SIGNAL
    signal CACHE_MISS_s : std_logic;

begin

    -- CONNECT DATAPATH AND CONTROL UNIT COMPONENTS

    -- DP: DATAPATH
    DP : DATAPATH port map(
        WBIFEN         => WBIFEN_s,
        IFIDEN         => IFIDEN_s,
        IDEXEN         => IDEXEN_s,
        EXMEMEN        => EXMEMEN_s,
        MEMWBEN        => MEMWBEN_s,
        STALL_EX_MEM   => STALL_EX_MEM_s,
        STALL_ID_EX    => STALL_ID_EX_s,
        n_cycles_stall => n_cycles_stall_s,
        NPC_SEL        => FLUSH_REQ_s,
        PREDICTION     => PREDICTION_s,
        UIS            => UIS_s,
        SUS            => SUS_s,
        SES            => SES_s,
        RF1            => RF1_s,
        RF2            => RF2_s,
        BS             => BS_s,
        AS             => AS_s,
        CNDS           => CNDS_s,
        ALUS           => ALUS_s,
        DMS            => DMS_s,
        DMB            => DMB_s,
        RnW            => RnW_s,
        DM_EN          => DM_EN_s,
        WBS            => WBS_s,
        WRF            => WRF_s,
        RDS            => RDS_s,
        FWD_A_SEL      => FWD_A_SEL_s,
        FWD_B_SEL      => FWD_B_SEL_s,
        FWD_DM_SEL     => FWD_DM_SEL_s,
        FWD_JR_SEL     => FWD_JR_SEL_s,
        Clk            => Clk,
        Rst            => Rst,
        OPCODE         => OPCODE,
        FUNC           => FUNC,
        fwd            => fwd_s,
    );

    -- CU: CONTROL UNIT
    CU : Hardwired_CU port map(
        UIS            => UIS_s,
        SUS            => SUS_s,
        SES            => SES_s,
        RF1            => RF1_s,
        RF2            => RF2_s,
        JUMPS          => JUMPS_s,
        BS             => BS_s,
        AS             => AS_s,
        CNDS           => CNDS_s,
        ALUS           => ALUS_s,
        DMS            => DMS_s,
        DMB            => DMB_s,
        RnW            => RnW_s,
        DM_EN          => DM_EN_s,
        WBS            => WBS_s,
        WRF            => WRF_s,
        RDS            => RDS_s,
        FWD_A_SEL      => FWD_A_SEL_s,
        FWD_B_SEL      => FWD_B_SEL_s,
        FWD_DM_SEL     => FWD_DM_SEL_s,
        FWD_JR_SEL     => FWD_JR_SEL_s,
        OPCODE         => OPCODE,
        FUNC           => FUNC,
        fwd            => fwd_s,
        CACHE_MISS     => CACHE_MISS_s,
        Clk            => Clk,
        Rst            => Rst,
        FLUSH_REQ      => FLUSH_REQ_s,
        STALL_EX_MEM   => STALL_EX_MEM_s,
        STALL_ID_EX    => STALL_ID_EX_s,
        n_cycles_stall => n_cycles_stall_s,
        PREDICTION     => PREDICTION_s,
        WBIFEN         => WBIFEN_s,
        IFIDEN         => IFIDEN_s,
        IDEXEN         => IDEXEN_s,
        EXMEMEN        => EXMEMEN_s,
        MEMWBEN        => MEMWBEN_s,
        NPC_SEL_RST    => NPC_SEL_RST_s,
        JUMP           => JUMP_s,
        BRANCH         => BRANCH_s
    );

end STRUCTURAL;