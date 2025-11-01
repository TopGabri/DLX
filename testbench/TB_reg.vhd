library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity REG_TB is

end REG_TB;

architecture TB_ARCH of REG_TB is

    component REG is
        generic (
            N : natural
        );
        port (
            d            : in std_logic_vector(N - 1 downto 0);
            Clk, rst, en : in std_logic;
            q            : out std_logic_vector(N - 1 downto 0)
        );
    end component REG;

    constant N                         : natural   := 32;
    signal en_s, rst_s, clk_s          : std_logic := '0';
    signal d_s, q_normal, q_clk_gating : std_logic_vector(N - 1 downto 0);

begin
    reg_normal     : REG generic map(N => N) port map(d => d_s, Clk => clk_s, en => en_s, rst => rst_s, q => q_normal);
    reg_clk_gating : REG generic map(N => N) port map(d => d_s, Clk => clk_s, en => en_s, rst => rst_s, q => q_clk_gating);

    test_process : process
    begin
        for index in 0 to 63 loop
            d_s <= std_logic_vector(to_unsigned(index, d_s'length));
            wait for 10 ns;
        end loop;
        wait;
    end process;

    clk_process : process
    begin
        wait for 2 ns;
        clk_s <= not clk_s;
    end process;

    en_process : process
    begin
        wait for 5 ns;
        en_s <= not en_s;
    end process;

    rst_process : process
    begin
        rst_s <= '1';
        wait for 5 ns;
        rst_s <= '0';
        wait for 30 ns;
    end process;
end TB_ARCH;

configuration CFG_REG_TB of REG_TB is
    for TB_ARCH
        for reg_normal : REG
            use configuration WORK.CFG_NORMAL;
        end for;
        for reg_clk_gating : REG
            use configuration WORK.CFG_CLK_GATING;
        end for;
    end for;
end configuration;