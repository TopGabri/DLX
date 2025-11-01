library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity MUX_4_1_TB is

end MUX_4_1_TB;

architecture TB_ARCH of MUX_4_1_TB is

    constant N                    : natural := 8;
    signal a1_s, a2_s, a3_s, a4_s : std_logic_vector(N - 1 downto 0);
    signal o_s                    : std_logic_vector(N - 1 downto 0);
    signal sel_s                  : std_logic_vector(1 downto 0);

    component MUX_4_1 is
        generic (
            N : natural
        );
        port (
            a1, a2, a3, a4 : in std_logic_vector(N - 1 downto 0);
            sel            : std_logic_vector(1 downto 0);
            o              : out std_logic_vector(N - 1 downto 0)
        );
    end component MUX_4_1;

begin

    a1_s <= "00000001";
    a2_s <= "00000010";
    a3_s <= "00000100";
    a4_s <= "00001000";

    mux_i : MUX_4_1 generic map(N => N)
    port map(a1 => a1_s, a2 => a2_s, a3 => a3_s, a4 => a4_s, sel => sel_s, o => o_s);

    test_process : process
    begin
        for index in 0 to 3 loop
            sel_s <= std_logic_vector(to_unsigned(index, sel_s'length));
            wait for 5 ns;
        end loop;
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