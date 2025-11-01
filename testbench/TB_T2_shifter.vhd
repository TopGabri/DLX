library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity T2_SHIFTER_TB is

end T2_SHIFTER_TB;

architecture TB_ARCH of T2_SHIFTER_TB is

component T2_SHIFTER is
    port(
        data: in std_logic_vector(31 downto 0);
        shift_amount: in std_logic_vector(4 downto 0);
        left_not_right: in std_logic; 
        arith_not_logic: in std_logic; 
        o: out std_logic_vector(31 downto 0)
 );
end component T2_SHIFTER;

signal data_s: std_logic_vector(31 downto 0);
signal shift_amount_s: std_logic_vector(4 downto 0);
signal left_not_right_s: std_logic; 
signal arith_not_logic_s: std_logic; 
signal o_s: std_logic_vector(31 downto 0);

begin

DUT: T2_SHIFTER port map(
    data => data_s,
    shift_amount => shift_amount_s,
    left_not_right => left_not_right_s,
    arith_not_logic => arith_not_logic_s,
    o => o_s
);

test_process: process
begin
    data_s <= X"00000000"; shift_amount_s <= "00000";
    left_not_right_s <= '0'; arith_not_logic_s <= '0';
    wait for 1 ns;
    
    for index in 0 to 31 loop
        data_s <= X"87654321";
        shift_amount_s <= std_logic_vector(to_unsigned(index, shift_amount_s'length));
        wait for 5 ns;
    end loop;
    
    left_not_right_s <= '0'; arith_not_logic_s <= '1';
    for index in 0 to 31 loop
        data_s <= X"87654321";
        shift_amount_s <= std_logic_vector(to_unsigned(index, shift_amount_s'length));
        wait for 5 ns;
    end loop;
    
    left_not_right_s <= '1'; arith_not_logic_s <= '0';
    for index in 0 to 31 loop
        data_s <= X"87654321";
        shift_amount_s <= std_logic_vector(to_unsigned(index, shift_amount_s'length));
        wait for 5 ns;
    end loop;
    wait;
end process;

end TB_ARCH;
