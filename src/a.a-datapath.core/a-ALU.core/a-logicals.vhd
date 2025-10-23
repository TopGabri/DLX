LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
-- entity LOGICALS:
-- to be inserted in the ALU of the DLX
-- implements logical operations: bitwise AND, OR, XOR on 2 N-bit inputs
-- implemented using only 3-input NAND gates and 3 selection signals

--    s0   s1   s2 |    o
-----------------------
--    0    0    1  |  op1op2  (AND)
--    1    1    1  |  op1 + op2 (OR)
--    1    1    0  |  !op1op2 + op1!op2  (XOR)

ENTITY LOGICALS IS
    GENERIC (N : INTEGER := 32);
    PORT (
        op1 : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
        op2 : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
        s0, s1, s2 : IN STD_LOGIC;
        o : OUT STD_LOGIC_VECTOR(N - 1 DOWNTO 0)
    );
END LOGICALS;

ARCHITECTURE STRUCTURAL OF LOGICALS IS

    COMPONENT NAND3 IS
        GENERIC (N : INTEGER := 32);
        PORT (
            a : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
            b : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
            c : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
            o : OUT STD_LOGIC_VECTOR(N - 1 DOWNTO 0)
        );
    END COMPONENT;

    --extended version of s0,s1,s2 to N bits
    SIGNAL s0_ext : STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
    SIGNAL s1_ext : STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
    SIGNAL s2_ext : STD_LOGIC_VECTOR(N - 1 DOWNTO 0);

    --negated operators
    SIGNAL op1_n : STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
    SIGNAL op2_n : STD_LOGIC_VECTOR(N - 1 DOWNTO 0);

    --intermediate signals
    SIGNAL L0, L1, L2 : STD_LOGIC_VECTOR(N - 1 DOWNTO 0);

BEGIN

    s0_ext <= (OTHERS => s0);
    s1_ext <= (OTHERS => s1);
    s2_ext <= (OTHERS => s2);

    op1_n <= NOT(op1);
    op2_n <= NOT(op2);

    --NAND3 instances
    ND0 : NAND3 GENERIC MAP(N) PORT MAP(a => op1_n, b => op2, c => s0_ext, o => L0);
    ND1 : NAND3 GENERIC MAP(N) PORT MAP(a => op1, b => op2_n, c => s1_ext, o => L1);
    ND2 : NAND3 GENERIC MAP(N) PORT MAP(a => op1, b => op2, c => s2_ext, o => L2);
    NDO : NAND3 GENERIC MAP(N) PORT MAP(a => L0, b => L1, c => L2, o => o);
END STRUCTURAL;