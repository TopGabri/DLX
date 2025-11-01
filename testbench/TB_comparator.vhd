library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity tb_comparator is
end tb_comparator;

architecture TEST of tb_comparator is
    component comparator is
        port (
            Z    : in std_logic; -- Zero flag
            Cout : in std_logic; -- Carry out flag
            S    : in std_logic; -- Sign flag
            SA   : in std_logic; -- First operand sign bit
            SB   : in std_logic; -- Second operand sign bit
            SnU  : in std_logic; -- Selection of signed/unsigned comparison
            LT   : out std_logic;
            GT   : out std_logic;
            LE   : out std_logic;
            GE   : out std_logic
        );
    end component;

    signal Z, S, SA, SB, Cout, SnU : std_logic := '0';
    signal LT, GT, LE, GE          : std_logic;

begin

    dut : comparator
    port map(
        Z    => Z,
        Cout => Cout,
        S    => S,
        SA   => SA,
        SB   => SB,
        SnU  => SnU,
        LT   => LT,
        GT   => GT,
        LE   => LE,
        GE   => GE
    );

    process
    begin

        --CHECK UNSIGNED COMPARISONS
        SnU <= '0'; --unsigned comparison

        --check LT
        --U1
        Cout <= '0';
        wait for 1 ns;
        assert (LT = '1' and GT = '0' and LE = '1' and GE = '0')
        report "U1 not correct";
        wait for 2 ns;

        --check GT
        --U2
        Cout <= '1';
        Z    <= '0';
        wait for 1 ns;
        assert (LT = '0' and GT = '1' and LE = '0' and GE = '1')
        report "U2 not correct";
        wait for 2 ns;
        --check LE
        --U3
        Cout <= '1';
        Z    <= '1';
        wait for 1 ns;
        assert (LT = '0' and GT = '0' and LE = '1' and GE = '1')
        report "U3 not correct";
        wait for 2 ns;
        -- CHECK SIGNED COMPARISONS

        SnU <= '1';

        -- S1
        Z  <= '0'; S  <= '0'; SA <= '0'; SB <= '0';
        wait for 1 ns;
        assert (LT = '0' and GT = '1' and LE = '0' and GE = '1')
        report "S1 not correct";
        wait for 2 ns;

        -- S2
        Z  <= '0'; S  <= '0'; SA <= '0'; SB <= '1';
        wait for 1 ns;
        assert (LT = '0' and GT = '1' and LE = '0' and GE = '1')
        report "S2 not correct";
        wait for 2 ns;

        -- S3
        Z  <= '0'; S  <= '0'; SA <= '1'; SB <= '0';
        wait for 1 ns;
        assert (LT = '1' and GT = '0' and LE = '1' and GE = '0')
        report "S3 not correct";
        wait for 2 ns;

        -- S4
        Z  <= '0'; S  <= '0'; SA <= '1'; SB <= '1';
        wait for 1 ns;
        assert (LT = '0' and GT = '1' and LE = '0' and GE = '1')
        report "S4 not correct";
        wait for 2 ns;

        -- S5
        Z  <= '0'; S  <= '1'; SA <= '0'; SB <= '0';
        wait for 1 ns;
        assert (LT = '1' and GT = '0' and LE = '1' and GE = '0')
        report "S5 not correct";
        wait for 2 ns;

        -- S6
        Z  <= '0'; S  <= '1'; SA <= '0'; SB <= '1';
        wait for 1 ns;
        assert (LT = '0' and GT = '1' and LE = '0' and GE = '1')
        report "S6 not correct";
        wait for 2 ns;

        -- S7
        Z  <= '0'; S  <= '1'; SA <= '1'; SB <= '0';
        wait for 1 ns;
        assert (LT = '1' and GT = '0' and LE = '1' and GE = '0')
        report "S7 not correct";
        wait for 2 ns;

        -- S8
        Z  <= '0'; S  <= '1'; SA <= '1'; SB <= '1';
        wait for 1 ns;
        assert (LT = '1' and GT = '0' and LE = '1' and GE = '0')
        report "S8 not correct";
        wait for 2 ns;

        -- S9
        Z  <= '1'; S  <= '0'; SA <= '0'; SB <= '0';
        wait for 1 ns;
        assert (LT = '0' and GT = '0' and LE = '1' and GE = '1')
        report "S9 not correct";
        wait for 2 ns;

        -- S10
        Z  <= '1'; S  <= '0'; SA <= '0'; SB <= '1';
        wait for 1 ns;
        assert (LT = '0' and GT = '0' and LE = '1' and GE = '1')
        report "S10 not correct";
        wait for 2 ns;

        -- S11
        Z  <= '1'; S  <= '0'; SA <= '1'; SB <= '0';
        wait for 1 ns;
        assert (LT = '1' and GT = '0' and LE = '1' and GE = '1')
        report "S11 not correct";
        wait for 2 ns;

        -- S12
        Z  <= '1'; S  <= '0'; SA <= '1'; SB <= '1';
        wait for 1 ns;
        assert (LT = '0' and GT = '0' and LE = '1' and GE = '1')
        report "S12 not correct";
        wait for 2 ns;

        -- S13
        Z  <= '1'; S  <= '1'; SA <= '0'; SB <= '0';
        wait for 1 ns;
        assert (LT = '1' and GT = '0' and LE = '1' and GE = '1')
        report "S13 not correct";
        wait for 2 ns;

        -- S14
        Z  <= '1'; S  <= '1'; SA <= '0'; SB <= '1';
        wait for 1 ns;
        assert (LT = '0' and GT = '0' and LE = '1' and GE = '1')
        report "S14 not correct";
        wait for 2 ns;

        -- S15
        Z  <= '1'; S  <= '1'; SA <= '1'; SB <= '0';
        wait for 1 ns;
        assert (LT = '1' and GT = '0' and LE = '1' and GE = '1')
        report "S15 not correct";
        wait for 2 ns;

        -- S16
        Z  <= '1'; S  <= '1'; SA <= '1'; SB <= '1';
        wait for 1 ns;
        assert (LT = '1' and GT = '0' and LE = '1' and GE = '1')
        report "S16 not correct";
        wait for 2 ns;

        wait;
    end process;
end TEST;