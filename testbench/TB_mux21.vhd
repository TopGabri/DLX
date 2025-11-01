library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity MUX_2_1_TB is

end MUX_2_1_TB;

architecture TB_ARCH of MUX_2_1_TB is

    constant N        : natural := 8;
    signal a1_s, a2_s : std_logic_vector(N - 1 downto 0);
    signal o_s        : std_logic_vector(N - 1 downto 0);
    signal sel_s      : std_logic;

    component MUX_2_1 is
        generic (
            N : natural
        );
        port (
            a1, a2 : in std_logic_vector(N - 1 downto 0);
            sel    : std_logic;
            o      : out std_logic_vector(N - 1 downto 0)
        );
    end component MUX_2_1;

begin

    a1_s <= "00000001";
    a2_s <= "00000010";

    mux_i : MUX_2_1 generic map(N => N)
    port map(a1 => a1_s, a2 => a2_s, sel => sel_s, o => o_s);

    test_process : process
    begin
        sel_s <= '0';
        wait for 5 ns;
        sel_s <= '1';
        wait;
    end process;

end TB_ARCH;

configuration CFG_MUX_4_1_TB of MUX_4_1_TB is
    for TB_ARCH
        for all : MUX_4_1
            use configuration WORK.CFG_MUX_4_1_STRUCTURAL;
        end for;
    end for;
end CFG_MUX_4_1_TB;