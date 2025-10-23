library IEEE;
use IEEE.STD_LOGIC_1164.all;
use WORK.DLX_Types.all;

entity ALU is
    port (
        A, B    : in std_logic_vector(31 downto 0);
        Sel     : in aluOp;
        ALU_OUT : out std_logic_vector(31 downto 0)
    );
end ALU;

architecture STRUCTURAL of ALU is

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
    end component;

    component LOGICALS is
        generic (N : integer := 32);
        port (
            op1        : in std_logic_vector(N - 1 downto 0);
            op2        : in std_logic_vector(N - 1 downto 0);
            s0, s1, s2 : in std_logic;
            o          : out std_logic_vector(N - 1 downto 0)
        );
    end component;

    component T2_SHIFTER is
        port (
            data         : in std_logic_vector(31 downto 0); -- 32 bit data
            shift_amount : in std_logic_vector(4 downto 0);  -- shift amount
            left_not_right  : in std_logic; --  1: shift left
            arith_not_logic : in std_logic; -- 1: arithmetic shift (if left shift, no effect)
            o               : out std_logic_vector(31 downto 0)
        );
    end component;

    component EQUAL0 is
        generic (N : integer := 32);
        port (
            x : in std_logic_vector(N - 1 downto 0);
            o : out std_logic
        );
    end component;

    component COMPARATOR is
        port (
            Z    : in std_logic; -- Zero flag
            Cout : in std_logic; -- Carry out flag
            S    : in std_logic; -- Sign flag
            SA   : in std_logic; -- First operand sign bit
            SB   : in std_logic; -- Second operand sign bit
            SnU  : in std_logic; -- Selection of signed/unsigned comparison
            LT   : out std_logic;
            GT   : out std_logic;
            LE   : out std_logic;
            GE   : out std_logic
        );
    end component;

    component MUX_2_1_1bit is
       port (
            A : in std_logic;
            B : in std_logic;
            S : in std_logic;
            Y : out std_logic
       );
    end component;
    
    component IV is
        port (
            A : in std_logic;
            Y : out std_logic);
    end component;
        
    component MUX_8_1 is
        generic (
            N : natural
        );
        port (
            a1, a2, a3, a4, a5, a6, a7, a8 : in std_logic_vector(N - 1 downto 0);
            sel                            : std_logic_vector(2 downto 0);
            o                              : out std_logic_vector(N - 1 downto 0)
        );
    end component;

    signal ADD_SUB_OUT, LOGIC_OUT, SHIFT_OUT         : std_logic_vector(31 downto 0);
    signal Cout, Zero, NE, GE, LE, LT, GT, EQ_NE     : std_logic;
    signal GE_ext, LE_ext, GT_ext, LT_ext, EQ_NE_ext : std_logic_vector(31 downto 0); -- extended version (to 32 bits)

    -- ALU selection signals
    signal S_OUT                                                                     : std_logic_vector(2 downto 0);
    signal Cin, S_LOGIC_0, S_LOGIC_1, S_LOGIC_2, LEFT_RIGHT, LOGIC_ARITH, SnU, EQnNE : std_logic;
begin

    S_OUT       <= Sel(10 downto 8);
    Cin         <= Sel(7);
    SnU         <= Sel(6);
    EQnNE       <= Sel(5);
    S_LOGIC_0   <= Sel(4);
    S_LOGIC_1   <= Sel(3);
    S_LOGIC_2   <= Sel(2);
    LEFT_RIGHT  <= Sel(1);
    LOGIC_ARITH <= Sel(0);

    -- ADD_SUB: perform addition and subtraction operations
    ADD_SUB : P4_ADDER generic map(32, 4)
    port map(
        A    => A,
        B    => B,
        Ci   => Cin,
        S    => ADD_SUB_OUT,
        Cout => Cout
    );

    -- LOGIC_BLOCK: perform logic operations AND, OR, XOR
    LOGIC_BLOCK : LOGICALS generic map(32)
    port map(
        op1 => A,
        op2 => B,
        s0  => S_LOGIC_0,
        s1  => S_LOGIC_1,
        s2  => S_LOGIC_2,
        o   => LOGIC_OUT
    );

    -- SHIFTER: 32 bit shifter based on T2 shifter
    SHIFTER : T2_SHIFTER port map(
        data            => A,
        shift_amount    => B(4 downto 0),
        left_not_right  => LEFT_RIGHT,
        arith_not_logic => LOGIC_ARITH,
        o               => SHIFT_OUT
    );

    -- IS_ZERO: =0 ?
    IS_ZERO : EQUAL0 generic map(32) port map(x => ADD_SUB_OUT, o => Zero);

    -- COMP: generic comparator, signed and unsigned
    COMP : COMPARATOR
    port map(
        Z    => Zero,
        Cout => Cout,
        S    => ADD_SUB_OUT(31),
        SA   => A(31),
        SB   => B(31),
        SnU  => SnU, -- 1 for signed comparison, 0 for unsigned comparison
        LT   => LT,
        GT   => GT,
        LE   => LE,
        GE   => GE
    );
    
    GE_ext    <= "0000000000000000000000000000000" & GE;    -- extend (unsigned) to 32 bits
    LE_ext    <= "0000000000000000000000000000000" & LE;    -- extend (unsigned) to 32 bits
    LT_ext    <= "0000000000000000000000000000000" & LT;    -- extend (unsigned) to 32 bits
    GT_ext    <= "0000000000000000000000000000000" & GT;    -- extend (unsigned) to 32 bits
        
    -- INV: inverts Zero (EQ), producing NE
    INV: IV port map (A => Zero, Y => NE);

    -- MUX_EQNE: chooses between EQ (Zero) and NE signals
    MUX_EQNE : MUX_2_1_1bit port map(
        A  => NE,
        B  => Zero,
        S  => EQnNE,
        Y  => EQ_NE
    );
    
    EQ_NE_ext <= "0000000000000000000000000000000" & EQ_NE; -- extend (unsigned) to 32 bits

    -- MUX_OUT: chooses the output of the ALU
    MUX_OUT : MUX_8_1 generic map(
        32) port map (
        a1  => ADD_SUB_OUT,     --000
        a2  => GE_ext,          --001
        a3  => LE_ext,          --010
        a4  => GT_ext,          --011
        a5  => LT_ext,          --100
        a6  => EQ_NE_ext,       --101
        a7  => LOGIC_OUT,       --110
        a8  => SHIFT_OUT,       --111
        sel => S_OUT,
        o   => ALU_OUT
    );

end STRUCTURAL;

configuration CFG_ALU of ALU is
    for STRUCTURAL
        for ADD_SUB : P4_ADDER
            use configuration WORK.CFG_P4_ADD;
        end for;
        for MUX_OUT : MUX_8_1
            use configuration WORK.CFG_MUX_8_1_STRUCTURAL;
        end for;
    end for;
end CFG_ALU;