library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SIGN_EXTENDER is
    generic(
        N_BITS_BEFORE: natural := 16;
        N_BITS_AFTER: natural := 32
    );
    port(
        i: in std_logic_vector(N_BITS_BEFORE-1 downto 0);
        o: out std_logic_vector(N_BITS_AFTER-1 downto 0)
    );
end SIGN_EXTENDER;

architecture DATAFLOW of SIGN_EXTENDER is

constant DIFFERENCE: integer := N_BITS_AFTER - N_BITS_BEFORE;
signal extension: std_logic_vector(DIFFERENCE-1 downto 0);

begin

    extension <= (others => i(N_BITS_BEFORE - 1));
    o <= extension & i;
    
end DATAFLOW;
