library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- entity EQUAL0:
    -- checks if input (on N-bits) is equal to 0:
        -- outputs '1' if input is 0, '0' otherwise
entity EQUAL0 is
    generic(N: integer := 32);
    port(x: in std_logic_vector(N-1 downto 0);
         o: out std_logic
         ); 
end EQUAL0;

architecture BEHAVIORAL of EQUAL0 is

    signal zeros: std_logic_vector(N-1 downto 0) := (others => '0');

begin

    with x select
        o <= '1' when zeros,
             '0' when others;
             
end BEHAVIORAL;
