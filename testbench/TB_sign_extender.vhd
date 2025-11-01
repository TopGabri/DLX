library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SIGN_EXTENDER_TB is

end SIGN_EXTENDER_TB;

architecture TB_ARCH of SIGN_EXTENDER_TB is

component SIGN_EXTENDER is
    generic(
        N_BITS_BEFORE, N_BITS_AFTER: natural
    );
    port(
        i: in std_logic_vector(N_BITS_BEFORE-1 downto 0);
        o: out std_logic_vector(N_BITS_AFTER-1 downto 0)
    );
end component SIGN_EXTENDER;

constant BEFORE1: natural := 16;
constant BEFORE2: natural := 24;
constant AFTER1: natural := 32;
constant AFTER2: natural := 64;

signal i_s1: std_logic_vector(BEFORE1-1 downto 0);
signal i_s2: std_logic_vector(BEFORE2-1 downto 0); 
signal o_s1: std_logic_vector(AFTER1-1 downto 0); 
signal o_s2: std_logic_vector(AFTER2-1 downto 0);

begin

    extender_1: SIGN_EXTENDER generic map(N_BITS_BEFORE => BEFORE1, N_BITS_AFTER => AFTER1)
        port map(i => i_s1, o => o_s1);
    extender_2: SIGN_EXTENDER generic map(N_BITS_BEFORE => BEFORE2, N_BITS_AFTER => AFTER2)
        port map(i => i_s2, o => o_s2);

    input_1_process: process
    begin
        i_s1 <= "0101010101010101";
        wait for 5 ns;
        i_s1 <= "1010101010101010";
        wait;
    end process;
    
    input_2_process: process
    begin
        i_s2 <= "010101010101010101010101";
        wait for 5 ns;
        i_s2 <= "101010101010101010101010";
        wait;
    end process;

end TB_ARCH;
