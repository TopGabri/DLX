library ieee;
use ieee.std_logic_1164.all;
package DLX_types is

    -- datapath sizes
    constant ADDR_WIDTH              : integer := 32;
    constant REG_ADDR_WIDTH          : integer := 5;
    constant DATA_WIDTH              : integer := 32;
    constant INSTRUCTION_WIDTH       : integer := 32;
    constant IMM_I_WIDTH             : integer := 16;
    constant IMM_J_WIDTH             : integer := 26;
    constant WORD_ADDR_WIDTH         : integer := 14;
    constant CACHE_LINE_ADDR_WIDTH   : integer := 4;
    constant CACHE_WORD_OFFSET_WIDTH : integer := 2;
    constant D_MEM_DEPTH             : integer := 2 ** WORD_ADDR_WIDTH; -- 8KB data memory
    constant I_MEM_DEPTH             : integer := 256;

    -- Control unit input sizes
    constant OP_CODE_SIZE       : integer := 6;  -- OPCODE field size                                          
    constant FUNC_SIZE          : integer := 11; -- FUNC field size
    constant CW_SIZE            : integer := 20; -- CONTROL WORD size 
    constant ALUS_SIZE          : integer := 11;
    constant MICROCODE_MEM_SIZE : integer := 62;               -- MICROCODE MEMORY size   
    subtype aluOp is std_logic_vector(ALUS_SIZE - 1 downto 0); -- type of ALU OPERATION  
	
	-- Delays
    constant DATA_DELAY : integer := 2; --clock cycles needed to read/write a word to/from data memory when there is a cache miss

    -- R-Type instruction -> FUNC field
    constant RTYPE_SLL  : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000000100"; -- 4. sll RD,RS1,RS2
    constant RTYPE_SRL  : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000000110"; -- 6. srl RD,RS1,RS2
    constant RTYPE_SRA  : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000000111"; -- 7. sra RD,RS1,RS2
    constant RTYPE_ADD  : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000100000"; -- 32. add RD,RS1,RS2
    constant RTYPE_ADDU : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00100000001"; -- 33. addu RD,RS1,RS2
    constant RTYPE_SUB  : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000100010"; -- 34. sub RD,RS1,RS2
    constant RTYPE_SUBU : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00100000011"; -- 35. subu RD,RS1,RS2
    constant RTYPE_AND  : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000100100"; -- 36. and RD,RS1,RS2
    constant RTYPE_OR   : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000100101"; -- 37. or RD,RS1,RS2
    constant RTYPE_XOR  : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000100110"; -- 38. xor RD,RS1,RS2 
    constant RTYPE_SEQ  : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00100001000"; -- 40. seq RD,RS1,RS2
    constant RTYPE_SNE  : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000101001"; -- 41. sne RD,RS1,RS2
    constant RTYPE_SLT  : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00100001001"; -- 42. slt RD,RS1,RS2
    constant RTYPE_SGT  : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00100001011"; -- 43. sgt RD,RS1,RS2
    constant RTYPE_SLE  : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000101100"; -- 44. sle RD,RS1,RS2
    constant RTYPE_SGE  : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000101101"; -- 45. sge RD,RS1,RS2
    constant RTYPE_SLTU : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000111010"; -- 58. sltu RD,RS1,RS2
    constant RTYPE_SGTU : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000111011"; -- 59. sgtu RD,RS1,RS2
    constant RTYPE_SLEU : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000111100"; -- 60. sleu RD,RS1,RS2
    constant RTYPE_SGEU : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000111101"; -- 61. sgeu RD,RS1,RS2
    -- R-Type instruction -> OPCODE field
    constant RTYPE : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "000000"; -- 0. for register-to-register operations

    -- I-Type and J-Type instruction -> OPCODE field
    constant JTYPE_J     : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "000010"; -- 2. j name
    constant JTYPE_JAL   : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "000011"; -- 3. jal name
    constant ITYPE_BEQZ  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "000100"; -- 4. beqz RS,name
    constant ITYPE_BNEZ  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "000101"; -- 5. bnez RS,name
    constant ITYPE_ADDI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "001000"; -- 8. addi RD,RS,#imm
    constant ITYPE_ADDUI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "001001"; -- 9. addui RD,RS,#imm
    constant ITYPE_SUBI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "001010"; -- 10. subi RD,RS,#imm
    constant ITYPE_SUBUI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "001011"; -- 11. subui RD,RS,#imm
    constant ITYPE_ANDI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "001100"; -- 12. andi RD,RS,#imm
    constant ITYPE_ORI   : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "001101"; -- 13. ori RD,RS,#imm
    constant ITYPE_XORI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "001110"; -- 14. xori RD,RS,#imm
    constant ITYPE_LHI   : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "001111"; -- 15. lhi RD,#imm
    constant JTYPE_JR    : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "010010"; -- 18. jr RS
    constant JTYPE_JALR  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "010011"; -- 19. jalr RS
    constant ITYPE_SLLI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "010100"; -- 20. slli RD,RS,#imm
    constant ITYPE_SRLI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "010110"; -- 22. srli RD,RS,#imm
    constant ITYPE_SRAI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "010111"; -- 23. srai RD,RS,#imm
    constant ITYPE_SEQI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "011000"; -- 24. seqi RD,RS,#imm
    constant ITYPE_SNEI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "011001"; -- 25. snei RD,RS,#imm
    constant ITYPE_SLTI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "011010"; -- 26. slti RD,RS,#imm
    constant ITYPE_SGTI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "011011"; -- 27. sgti RD,RS,#imm
    constant ITYPE_SLEI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "011100"; -- 28. slei RD,RS,#imm
    constant ITYPE_SGEI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "011101"; -- 29. sgei RD,RS,#imm
    constant ITYPE_LB    : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "100000"; -- 32. lb RD,#imm(RS)
    constant ITYPE_LH    : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "100001"; -- 33. lh RD,#imm(RS)
    constant ITYPE_LW    : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "100011"; -- 35. lw RD,#imm(RS)
    constant ITYPE_LBU   : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "100100"; -- 36. lbu RD,#imm(RS)
    constant ITYPE_LHU   : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "100101"; -- 37. lhu RD,#imm(RS)
    constant ITYPE_SB    : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "101000"; -- 40. sb #imm(RD), RS
    constant ITYPE_SH    : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "101001"; -- 41. sh #imm(RD), RS
    constant ITYPE_SW    : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "101011"; -- 43. sw #imm(RD), RS
    constant ITYPE_SLTUI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "111010"; -- 58. sltui RD,RS,#imm
    constant ITYPE_SGTUI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "111011"; -- 59. sgtui RD,RS,#imm
    constant ITYPE_SLEUI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "111100"; -- 60. sleui RD,RS,#imm
    constant ITYPE_SGEUI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "111101"; -- 61. sgeui RD,RS,#imm
    constant NOP         : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "010101"; -- 21. nop
    -- classification of instructions

    type instruction_type is array (natural range <>) of std_logic_vector(OP_CODE_SIZE - 1 downto 0);

    constant ITYPE_ALU : instruction_type := (
        ITYPE_ADDI, ITYPE_ADDUI, ITYPE_SUBI, ITYPE_SUBUI, ITYPE_ANDI, ITYPE_ORI,
        ITYPE_XORI, ITYPE_SLLI, ITYPE_SRLI, ITYPE_SRAI, ITYPE_SEQI, ITYPE_SNEI,
        ITYPE_SLTI, ITYPE_SGTI, ITYPE_SLEI, ITYPE_SGEI, ITYPE_SLTUI, ITYPE_SGTUI,
        ITYPE_SLEUI, ITYPE_SGEUI, ITYPE_LHI
    );

    constant ITYPE_LOAD : instruction_type := (
        ITYPE_LB, ITYPE_LH, ITYPE_LW, ITYPE_LBU, ITYPE_LHU
    );

    constant ITYPE_STORE : instruction_type := (
        ITYPE_SB, ITYPE_SH, ITYPE_SW
    );

    constant ITYPE_BRANCH : instruction_type := (
        ITYPE_BEQZ, ITYPE_BNEZ
    );

    constant JTYPE : instruction_type := (
        JTYPE_J, JTYPE_JAL, JTYPE_JR, JTYPE_JALR
    );

    -- functions to check instruction type
    function is_in_set(op : std_logic_vector; set_list : instruction_type) return boolean;
    function is_itype_alu(op : std_logic_vector) return boolean;
    function is_load(op      : std_logic_vector) return boolean;
    function is_store(op     : std_logic_vector) return boolean;
    function is_branch(op    : std_logic_vector) return boolean;
    function is_itype(op     : std_logic_vector) return boolean;
    function is_jump(op      : std_logic_vector) return boolean;
    function is_jump_reg(op  : std_logic_vector) return boolean;
    function is_jump_lr(op   : std_logic_vector) return boolean;

    procedure report_slv (
        constant msg : in string;
        constant slv : in std_logic_vector
    );
end DLX_types;
package body DLX_types is

    function is_in_set(op : std_logic_vector; set_list : instruction_type) return boolean is
    begin
        for i in set_list'range loop
            if op = set_list(i) then
                return true;
            end if;
        end loop;
        return false;
    end function;

    function is_itype_alu(op : std_logic_vector) return boolean is
    begin
        return is_in_set(op, ITYPE_ALU);
    end function;

    function is_load(op : std_logic_vector) return boolean is
    begin
        return is_in_set(op, ITYPE_LOAD);
    end function;

    function is_store(op : std_logic_vector) return boolean is
    begin
        return is_in_set(op, ITYPE_STORE);
    end function;

    function is_branch(op : std_logic_vector) return boolean is
    begin
        return is_in_set(op, ITYPE_BRANCH);
    end function;

    function is_itype(op : std_logic_vector) return boolean is
    begin
        return (is_itype_alu(op) or is_load(op) or is_store(op) or is_branch(op));
    end function;

    function is_jump(op : std_logic_vector) return boolean is
    begin
        return is_in_set(op, JTYPE);
    end function;

    function is_jump_reg(op : std_logic_vector) return boolean is
    begin
        return (op = JTYPE_JR or op = JTYPE_JALR);
    end function;

    function is_jump_lr(op : std_logic_vector) return boolean is
    begin
        return (op = JTYPE_JAL or op = JTYPE_JALR);
    end function;

    procedure report_slv (
        constant msg : in string;
        constant slv : in std_logic_vector
    ) is
        variable slv_str : string(1 to slv'length);
        variable idx     : integer := 1;
    begin
        for i in slv'range loop
            -- std_logic'image gives e.g. "'0'", "'1'", "'U'", so take middle char
            slv_str(idx) := std_logic'image(slv(i))(2);
            idx          := idx + 1;
        end loop;
        report msg & " " & slv_str;
    end procedure;
end DLX_types;