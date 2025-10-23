LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- entity NAND3:
-- a 3-input NAND gate on N-bit inputs
ENTITY NAND3 IS
    GENERIC (N : INTEGER := 32);
    PORT (
        a : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
        b : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
        c : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
        o : OUT STD_LOGIC_VECTOR(N - 1 DOWNTO 0)
    );
END NAND3;

ARCHITECTURE DATAFLOW OF NAND3 IS

BEGIN

    gen_nand : FOR i IN 0 TO N - 1 GENERATE
        o(i) <= (a(i) AND b(i)) NAND c(i); -- NAND(a,b,c)
    END GENERATE;

END DATAFLOW;