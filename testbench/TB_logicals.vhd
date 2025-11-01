library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_LOGICALS is
end TB_LOGICALS;

architecture TBARCH of TB_LOGICALS is

    component LOGICALS is 
        generic(N: integer := 32);
        port(op1: in std_logic_vector(N-1 downto 0);
             op2: in std_logic_vector(N-1 downto 0);
             s0,s1,s2: in std_logic;
             o: out std_logic_vector(N-1 downto 0)
             );
    end component;
    
    constant N: integer := 32;
    signal op1_s, op2_s, o_s: std_logic_vector(N-1 downto 0);
    signal s0_s,s1_s,s2_s: std_logic;

begin

    UUT: LOGICALS generic map(N) port map(op1_s,op2_s,s0_s,s1_s,s2_s,o_s);
    
    process
    begin
        op1_s <= X"ABCD1234"; op2_s <= X"F0E541BC";
        s0_s <= '0'; s1_s <= '0'; s2_s <= '1'; --AND
        wait for 1 ns;
        assert o_s = X"A0C50034" report "AND returns wrong result";
        wait for 5 ns;
        s0_s <= '1'; s1_s <= '1'; s2_s <= '1'; --OR
        wait for 1 ns;
        assert o_s = X"FBED53BC" report "OR returns wrong result";
        wait for 5 ns;
        s0_s <= '1'; s1_s <= '1'; s2_s <= '0'; --XOR
        wait for 1 ns;
        assert o_s = X"5B285388" report "XOR returns wrong result";
        wait;        
    end process;

end TBARCH;
