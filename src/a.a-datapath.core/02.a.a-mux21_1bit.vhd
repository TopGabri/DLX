library ieee;
use ieee.std_logic_1164.all;
entity MUX_2_1_1bit is
    port (
        A : in std_logic;
        B : in std_logic;
        S : in std_logic;
        Y : out std_logic);
end MUX_2_1_1bit;

architecture STRUCTURAL of MUX_2_1_1bit is

    signal Y1 : std_logic;
    signal Y2 : std_logic;
    signal NS : std_logic;

    component ND2
        port (
            A : in std_logic;
            B : in std_logic;
            Y : out std_logic);
    end component;

    component IV
        port (
            A : in std_logic;
            Y : out std_logic);
    end component;

begin

    UIV : IV
    port map(S, NS);

    UND1 : ND2
    port map(A, NS, Y1);

    UND2 : ND2
    port map(B, S, Y2);

    UND3 : ND2
    port map(Y1, Y2, Y);
    
end STRUCTURAL;