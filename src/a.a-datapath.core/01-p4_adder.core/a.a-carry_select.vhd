library ieee;
use ieee.std_logic_1164.all;

entity CARRY_SELECT is
	generic (NBIT : integer := 4);
	port (
		a, b : in std_logic_vector(NBIT - 1 downto 0);
		cin  : in std_logic;
		s    : out std_logic_vector(NBIT - 1 downto 0)
	);
end CARRY_SELECT;

architecture STRUCT of CARRY_SELECT is
	component MUX_2_1 is
        generic(
            N: natural
        );
        port(
            a1,a2: in std_logic_vector(N-1 downto 0);
            sel: std_logic;
            o: out std_logic_vector(N-1 downto 0)
        );
    end component MUX_2_1;

	component rca_generic is
		generic (N : integer := 6);
		port (
			A  : in std_logic_vector(N - 1 downto 0);
			B  : in std_logic_vector(N - 1 downto 0);
			Ci : in std_logic;
			S  : out std_logic_vector(N - 1 downto 0);
			Co : out std_logic);
	end component;

	signal tmp_sum_0, tmp_sum_1 : std_logic_vector(NBIT - 1 downto 0);
	signal cout0, cout1         : std_logic;

begin

	ADD0 : rca_generic generic map(N => NBIT) port map(A => a, B => b, Ci => '0', S => tmp_sum_0, Co => cout0);
	ADD1 : rca_generic generic map(N => NBIT) port map(A => a, B => b, Ci => '1', S => tmp_sum_1, Co => cout1);
	MUX  : MUX_2_1 generic map(N => NBIT) port map(a1 => tmp_sum_0, a2 => tmp_sum_1, sel => cin, o => s);

end STRUCT;

configuration CFG_CS_STRUCT of CARRY_SELECT is
	for STRUCT
		for MUX : MUX_2_1
		  use configuration WORK.CFG_MUX_2_1_STRUCTURAL;
		end for;
		for ADD0 : rca_generic
			use configuration WORK.CFG_RCA_STRUCTURAL;
		end for;
		for ADD1 : rca_generic
			use configuration WORK.CFG_RCA_STRUCTURAL;
		end for;
	end for;
end CFG_CS_STRUCT;