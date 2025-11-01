library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MUX_16_1_TB is

end MUX_16_1_TB;

architecture TB_ARCH of MUX_16_1_TB is

constant N: natural := 16;
signal a1_s, a2_s, a3_s, a4_s, a5_s, a6_s, a7_s, a8_s, a9_s, a10_s, a11_s, a12_s, a13_s, a14_s, a15_s, a16_s: std_logic_vector(N-1 downto 0);
signal o_s: std_logic_vector(N-1 downto 0);
signal sel_s: std_logic_vector(3 downto 0);

component MUX_16_1 is
    generic(
        N: natural
    );
    port(
        a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16: in std_logic_vector(N-1 downto 0);
        sel: std_logic_vector(3 downto 0);
        o: out std_logic_vector(N-1 downto 0)
    );
end component MUX_16_1;

begin
    
    a1_s <= "0000000000000001";
    a2_s <= "0000000000000010";
    a3_s <= "0000000000000100";
    a4_s <= "0000000000001000";
    a5_s <= "0000000000010000";
    a6_s <= "0000000000100000";
    a7_s <= "0000000001000000";
    a8_s <= "0000000010000000";
    a9_s <= "0000000100000000";
    a10_s <= "0000001000000000";
    a11_s <= "0000010000000000";
    a12_s <= "0000100000000000";
    a13_s <= "0001000000000000";
    a14_s <= "0010000000000000";
    a15_s <= "0100000000000000";
    a16_s <= "1000000000000000";
    
    mux_i: MUX_16_1 generic map (N => N)
        port map (a1 => a1_s, a2 => a2_s, a3 => a3_s, a4 => a4_s, a5 => a5_s, a6 => a6_s, a7 => a7_s, a8 => a8_s, a9 => a9_s, a10 => a10_s, a11 => a11_s, a12 => a12_s, a13 => a13_s, a14 => a14_s, a15 => a15_s, a16 => a16_s, sel => sel_s, o => o_s);
    
    test_process: process
        begin
            for index in 0 to 15 loop
                sel_s <= std_logic_vector(to_unsigned(index, sel_s'length));
                wait for 5 ns;
            end loop;
        wait;
    end process;

end TB_ARCH;

configuration CFG_MUX_16_1_TB of MUX_16_1_TB is
  for TB_ARCH
    for all : MUX_16_1
        use configuration WORK.CFG_MUX_16_1_STRUCTURAL;
    end for;
  end for;
end CFG_MUX_16_1_TB;