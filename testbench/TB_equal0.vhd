library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity tb_equal0 is
end tb_equal0;

architecture Behavioral of tb_equal0 is

component EQUAL0 is 
    generic(N: integer := 32);
    port(x: in std_logic_vector(N-1 downto 0);
         o: out std_logic
         );
end component;

constant N: integer := 32;
signal x_s: std_logic_vector(N-1 downto 0);
signal o_s: std_logic;

begin

UUT: EQUAL0 generic map (N => N) port map(x=> x_s, o=> o_s);

    process 
    begin   
        x_s <= x"11111111";
        wait for 1 ns;
        x_s <= x"00000001";
        wait for 1 ns;
        x_s <= (others => '0');
        wait;
    end process;


end Behavioral;
