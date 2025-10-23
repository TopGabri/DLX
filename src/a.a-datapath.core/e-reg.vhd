library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity REG is
    generic (
        N : natural := 32
    );
    port (
        d            : in std_logic_vector(N - 1 downto 0);
        Clk, Rst, en : in std_logic;
        q            : out std_logic_vector(N - 1 downto 0)
    );
end REG;

architecture BEH of REG is

begin
    reg_process : process (Clk, Rst, en)
    begin
        if (Rst = '1') then
            q <= (others => '0');
        elsif (rising_edge(Clk)) then
            if (en = '1') then
                q <= d;
            end if;
        end if;
    end process;
end BEH;

configuration CFG_REG of REG is
    for BEH
    end for;
end configuration;