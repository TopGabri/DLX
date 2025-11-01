library IEEE;
use IEEE.std_logic_1164.all;
use WORK.DLX_Types.all;

entity DLX_TB is
end DLX_TB;

architecture TBARCH of DLX_TB is

    component DLX is
        port (
            Clk : in std_logic;
            Rst : in std_logic
        );
    end component DLX;

    constant Clkperiod : time := 10 ns;
    signal Clk, Rst : std_logic;

begin

    uut : DLX port map(
        Clk => Clk,
        Rst => Rst
    );

    clock_process : process
    begin
        clk <= '0';
        wait for Clkperiod/2;
        clk <= '1';
        wait for Clkperiod/2;
    end process;

    tb_process : process
    begin

        Rst <= '1';
        wait for Clkperiod;
        wait for 1 ns;
        Rst <= '0';

        wait;
    end process;

end TBARCH;