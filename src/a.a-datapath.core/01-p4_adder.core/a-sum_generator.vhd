library ieee;
use ieee.std_logic_1164.all;

entity SUM_GENERATOR is
	generic (
		NBIT_PER_BLOCK : integer := 4;
		NBLOCKS        : integer := 8
	);
	port (
		A  : in std_logic_vector(NBIT_PER_BLOCK * NBLOCKS - 1 downto 0);
		B  : in std_logic_vector(NBIT_PER_BLOCK * NBLOCKS - 1 downto 0);
		Ci : in std_logic_vector(NBLOCKS - 1 downto 0);
		S  : out std_logic_vector(NBIT_PER_BLOCK * NBLOCKS - 1 downto 0)
	);
end SUM_GENERATOR;

architecture STRUCT of SUM_GENERATOR is

	component CARRY_SELECT is
		generic (NBIT : integer := 4);
		port (
			a, b : in std_logic_vector(NBIT - 1 downto 0);
			cin  : in std_logic;
			s    : out std_logic_vector(NBIT - 1 downto 0)
		);
	end component;
begin

	generateLoop : for i in 0 to NBLOCKS - 1 generate
		CS : carry_select port map(
			a   => A(NBIT_PER_BLOCK * (i + 1) - 1 downto NBIT_PER_BLOCK * i),
			b   => B(NBIT_PER_BLOCK * (i + 1) - 1 downto NBIT_PER_BLOCK * i),
			cin => Ci(i),
			s   => S(NBIT_PER_BLOCK * (i + 1) - 1 downto NBIT_PER_BLOCK * i)
		);
	end generate generateLoop;

end STRUCT;

configuration CFG_SUM_GEN_STRUCT of SUM_GENERATOR is
	for STRUCT
		for generateLoop
			for all : CARRY_SELECT
				use configuration WORK.CFG_CS_STRUCT;
			end for;
		end for;
	end for;
end CFG_SUM_GEN_STRUCT;