library ieee;
use ieee.std_logic_1164.all;
use WORK.DLX_Types.all;
entity FORWARDING_STALLING_LOGIC is
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
        STALL_EX_MEM   : out std_logic; -- STALL up to EX/MEM pipeline register
        STALL_ID_EX    : out std_logic; -- STALL up to ID/EX pipeline register
        n_cycles_stall : out integer    -- number of cycles to stall
    );
end FORWARDING_STALLING_LOGIC;

architecture BEHAVIORAL of FORWARDING_STALLING_LOGIC is

    signal IF_ID_OPCODE, ID_EX_OPCODE, EX_MEM_OPCODE, MEM_WB_OPCODE : std_logic_vector(OP_CODE_SIZE - 1 downto 0);   -- IF/ID.IR[opcode], ID/EX.IR[opcode], EX/MEM.IR[opcode], MEM/WB.IR[opcode]
    signal IF_ID_RS1, IF_ID_RS2, IF_ID_RD                           : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0); -- IF/ID.IR[rs1], IF/ID.IR[rs2], IF/ID.IR[rd]
    signal ID_EX_RS1, EX_MEM_RS1, MEM_WB_RS1                        : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0); -- ID/EX.IR[rs1], EX/MEM.IR[rs1], MEM/WB.IR[rs1]
    signal ID_EX_RS2, EX_MEM_RS2, MEM_WB_RS2                        : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0); -- ID/EX.IR[rs2], EX/MEM.IR[rs2], MEM/WB.IR[rs2] 
    signal ID_EX_RD, EX_MEM_RD, MEM_WB_RD                           : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0); -- ID/EX.IR[rd],  EX/MEM.IR[rd], MEM/WB.IR[rd]

    signal LR : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0) := "11111"; -- link register address (r31)
begin
    -- OPCODE
    IF_ID_OPCODE  <= IF_ID_IR(31 downto 26);
    ID_EX_OPCODE  <= ID_EX_IR(31 downto 26);
    EX_MEM_OPCODE <= EX_MEM_IR(31 downto 26);
    MEM_WB_OPCODE <= MEM_WB_IR(31 downto 26);

    -- RS1
    IF_ID_RS1  <= IF_ID_IR(25 downto 21);
    ID_EX_RS1  <= ID_EX_IR(25 downto 21);
    EX_MEM_RS1 <= EX_MEM_IR(25 downto 21);
    MEM_WB_RS1 <= MEM_WB_IR(25 downto 21);

    -- RS2
    IF_ID_RS2  <= IF_ID_IR(20 downto 16);
    ID_EX_RS2  <= ID_EX_IR(20 downto 16);
    EX_MEM_RS2 <= EX_MEM_IR(20 downto 16);
    MEM_WB_RS2 <= MEM_WB_IR(20 downto 16);

    -- RD
    IF_ID_RD  <= IF_ID_IR(15 downto 11);
    ID_EX_RD  <= ID_EX_IR(15 downto 11);
    EX_MEM_RD <= EX_MEM_IR(15 downto 11);
    MEM_WB_RD <= MEM_WB_IR(15 downto 11);

    forward_stall : process (
        IF_ID_OPCODE,
        ID_EX_OPCODE,
        EX_MEM_OPCODE,
        MEM_WB_OPCODE,
        IF_ID_RS1,
        ID_EX_RS1,
        EX_MEM_RS1,
        MEM_WB_RS1,
        IF_ID_RS2,
        ID_EX_RS2,
        EX_MEM_RS2,
        MEM_WB_RS2,
        IF_ID_RD,
        ID_EX_RD,
        EX_MEM_RD,
        MEM_WB_RD
        )
    begin

        FWD_ALU_to_A  <= '0';
        FWD_ALU2_to_A <= '0';
        FWD_LMD_to_A  <= '0';

        FWD_ALU_to_B  <= '0';
        FWD_ALU2_to_B <= '0';
        FWD_LMD_to_B  <= '0';

        FWD_ALU2_to_DM       <= '0';
        FWD_LMD_to_DM        <= '0';
        FWD_PC_INCR_WB_to_DM <= '0';

        FWD_ALU_to_JR         <= '0';
        FWD_PC_INCR_EX_to_JR  <= '0';
        FWD_PC_INCR_MEM_to_JR <= '0';

        STALL_EX_MEM   <= '0';
        STALL_ID_EX    <= '0';
        n_cycles_stall <= 0;

        -- /* FORWARDING LOGIC */

        -- forward TO A (ALU)

        -- forward FROM EX/MEM.ALUOUT
        if (
            -- F1. 
            (EX_MEM_OPCODE = RTYPE and (ID_EX_OPCODE = RTYPE or is_itype(ID_EX_OPCODE)) and EX_MEM_RD = ID_EX_RS1) or
            -- F5
            (is_itype_alu(EX_MEM_OPCODE) and (ID_EX_OPCODE = RTYPE or is_itype(ID_EX_OPCODE)) and EX_MEM_RS2 = ID_EX_RS1)
            ) then

            FWD_ALU_to_A <= '1';

            -- forward FROM MEM/WB.ALUOUT 
        elsif (
            -- F3 
            (MEM_WB_OPCODE = RTYPE and (ID_EX_OPCODE = RTYPE or is_itype(ID_EX_OPCODE)) and MEM_WB_RD = ID_EX_RS1) or
            -- F7 
            (is_itype_alu(MEM_WB_OPCODE) and (ID_EX_OPCODE = RTYPE or is_itype(ID_EX_OPCODE)) and MEM_WB_RS2 = ID_EX_RS1)
            ) then

            FWD_ALU2_to_A <= '1';

            -- forward FROM MEM/WB.LMD
        elsif (
            -- F9 
            is_load(MEM_WB_OPCODE) and (ID_EX_OPCODE = RTYPE or is_itype(ID_EX_OPCODE)) and MEM_WB_RS2 = ID_EX_RS1
            ) then

            FWD_LMD_to_A <= '1';

        end if;
        -- forward TO B (ALU)

        -- forward FROM EX/MEM.ALUOUT 
        if (
            -- F2 
            (EX_MEM_OPCODE = RTYPE and ID_EX_OPCODE = RTYPE and EX_MEM_RD = ID_EX_RS2) or
            -- F6 
            (is_itype_alu(EX_MEM_OPCODE) and ID_EX_OPCODE = RTYPE and EX_MEM_RS2 = ID_EX_RS2)
            ) then

            FWD_ALU_to_B <= '1';

            -- forward FROM MEM/WB.ALUOUT
        elsif (
            -- F4 
            (MEM_WB_OPCODE = RTYPE and ID_EX_OPCODE = RTYPE and MEM_WB_RD = ID_EX_RS2) or
            -- F8 
            (is_itype_alu(MEM_WB_OPCODE) and ID_EX_OPCODE = RTYPE and MEM_WB_RS2 = ID_EX_RS2) or
            -- F15 
            (MEM_WB_OPCODE = RTYPE and is_store(ID_EX_OPCODE) and MEM_WB_RD = ID_EX_RS2) or
            -- F16 
            (is_itype_alu(MEM_WB_OPCODE) and is_store(ID_EX_OPCODE) and MEM_WB_RS2 = ID_EX_RS2)
            ) then

            FWD_ALU2_to_B <= '1';

            -- forward FROM MEM/WB.LMD
        elsif (
            -- F10 
            (is_load(MEM_WB_OPCODE) and ID_EX_OPCODE = RTYPE and MEM_WB_RS2 = ID_EX_RS2) or
            -- F17 
            (is_load(MEM_WB_OPCODE) and is_store(ID_EX_OPCODE) and MEM_WB_RS2 = ID_EX_RS2)
            ) then

            FWD_LMD_to_B <= '1';

        end if;

        -- FORWARD to DM_IN (DATA MEMORY)

        -- forward FROM MEM/WB.ALUOUT
        if (
            -- F11 
            (MEM_WB_OPCODE = RTYPE and is_store(EX_MEM_OPCODE) and MEM_WB_RD = EX_MEM_RS2) or
            -- F12 
            (is_itype_alu(MEM_WB_OPCODE) and is_store(EX_MEM_OPCODE) and MEM_WB_RS2 = EX_MEM_RS2)
            ) then

            FWD_ALU2_to_DM <= '1';

            -- forward FROM MEM/WB.LMD
        elsif (
            -- F13 
            (is_load(MEM_WB_OPCODE) and is_store(EX_MEM_OPCODE) and MEM_WB_RS2 = EX_MEM_RS2)
            ) then

            FWD_LMD_to_DM <= '1';
            -- forward FROM MEM/WB.PC_INCR
        elsif (
            -- F14 
            (is_jump_lr(MEM_WB_OPCODE) and is_store(EX_MEM_OPCODE) and EX_MEM_RS2 = LR)
            ) then
            FWD_PC_INCR_WB_to_DM <= '1';
        end if;

        -- FORWARD TO JUMP ADDRESS

        -- forward FROM EX/MEM.ALUOUT
        if (
            -- F20 
            (EX_MEM_OPCODE = RTYPE and is_jump_reg(IF_ID_OPCODE) and EX_MEM_RD = IF_ID_RS1) or
            -- F21
            (is_itype_alu(EX_MEM_OPCODE) and is_jump_reg(IF_ID_OPCODE) and EX_MEM_RS2 = IF_ID_RS1)
            ) then

            FWD_ALU_to_JR <= '1';
            -- forward FROM ID/EX.PC_INCR
        elsif (
            -- F18
            (is_jump_lr(ID_EX_OPCODE) and is_jump_reg(IF_ID_OPCODE) and IF_ID_RS1 = LR)
            ) then
            FWD_PC_INCR_EX_to_JR <= '1';
            -- forward FROM EX/MEM.PC_INCR
        elsif (
            -- F19
            (is_jump_lr(EX_MEM_OPCODE) and is_jump_reg(IF_ID_OPCODE) and IF_ID_RS1 = LR)
            ) then
            FWD_PC_INCR_MEM_to_JR <= '1';
        end if;

        -- /* STALLING LOGIC */

        -- Stall EX/MEM for 1 cc
        if (
            -- S1
            (is_load(EX_MEM_OPCODE) and (ID_EX_OPCODE = RTYPE or is_itype(ID_EX_OPCODE)) and (EX_MEM_RS2 = ID_EX_RS1)) or
            -- S2
            (is_load(EX_MEM_OPCODE) and ID_EX_OPCODE = RTYPE and (EX_MEM_RS2 = ID_EX_RS2))
            ) then
            STALL_EX_MEM   <= '1';
            n_cycles_stall <= 1;

            -- Stall ID/EX for 2 cc
        elsif (
            -- S5
            (is_load(ID_EX_OPCODE) and is_jump_reg(IF_ID_OPCODE) and (ID_EX_RS2 = IF_ID_RS1)) or
            -- S8
            (is_jump_lr(ID_EX_OPCODE) and (IF_ID_OPCODE = RTYPE or is_itype(IF_ID_OPCODE)) and (IF_ID_RS1 = LR)) or
            -- S9
            (is_jump_lr(ID_EX_OPCODE) and IF_ID_OPCODE = RTYPE and (IF_ID_RS2 = LR))
            ) then
            STALL_ID_EX    <= '1';
            n_cycles_stall <= 2;

            -- Stall ID/EX for 1 cc
        elsif (
            -- S3
            (ID_EX_OPCODE = RTYPE and is_jump_reg(IF_ID_OPCODE) and (ID_EX_RD = IF_ID_RS1)) or
            -- S4
            (is_itype_alu(ID_EX_OPCODE) and is_jump_reg(IF_ID_OPCODE) and (ID_EX_RS2 = IF_ID_RS1)) or
            -- S6
            (is_load(EX_MEM_OPCODE) and is_jump_reg(IF_ID_OPCODE) and (EX_MEM_RS2 = IF_ID_RS1)) or
            -- S7
            (is_jump_lr(ID_EX_OPCODE) and is_store(IF_ID_OPCODE) and (IF_ID_RS2 = LR)) or
            -- S10
            (is_jump_lr(EX_MEM_OPCODE) and (IF_ID_OPCODE = RTYPE or is_itype(IF_ID_OPCODE)) and (IF_ID_RS1 = LR)) or
            -- S11
            (is_jump_lr(EX_MEM_OPCODE) and IF_ID_OPCODE = RTYPE and (IF_ID_RS2 = LR))
            ) then
            STALL_ID_EX    <= '1';
            n_cycles_stall <= 1;
        end if;
    end process;
end BEHAVIORAL;