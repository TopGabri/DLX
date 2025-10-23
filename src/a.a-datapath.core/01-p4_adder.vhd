library ieee;
use ieee.std_logic_1164.all;

entity P4_ADDER is
	generic (
		NBIT           : integer := 32;
		NBIT_PER_BLOCK : integer := 4
	);
	port (
		A    : in std_logic_vector(NBIT - 1 downto 0);
		B    : in std_logic_vector(NBIT - 1 downto 0);
		Ci   : in std_logic;
		S    : out std_logic_vector(NBIT - 1 downto 0);
		Cout : out std_logic
	);
end P4_ADDER;

architecture STRUCT of P4_ADDER is

	component SUM_GENERATOR is
		generic (
			NBIT_PER_BLOCK : integer := 4;
			NBLOCKS        : integer := 8);
		port (
			A  : in std_logic_vector(NBIT_PER_BLOCK * NBLOCKS - 1 downto 0);
			B  : in std_logic_vector(NBIT_PER_BLOCK * NBLOCKS - 1 downto 0);
			Ci : in std_logic_vector(NBLOCKS - 1 downto 0);
			S  : out std_logic_vector(NBIT_PER_BLOCK * NBLOCKS - 1 downto 0));
	end component;

	component CARRY_GENERATOR is
		generic (
			NBIT           : integer := 32;
			NBIT_PER_BLOCK : integer := 4);
		port (
			A   : in std_logic_vector(NBIT - 1 downto 0);
			B   : in std_logic_vector(NBIT - 1 downto 0);
			Cin : in std_logic;
			Co  : out std_logic_vector((NBIT/NBIT_PER_BLOCK) - 1 downto 0));
	end component;

	signal Co_s    : std_logic_vector((NBIT/NBIT_PER_BLOCK) - 1 downto 0);
	signal Ci_sg   : std_logic_vector((NBIT/NBIT_PER_BLOCK) - 1 downto 0);
	signal Ci_NBIT : std_logic_vector(NBIT - 1 downto 0);
	signal B_XOR   : std_logic_vector(NBIT - 1 downto 0);

begin
	-- the output of the carry generator (vector of carries) is connected to the respective carry ins of the sum generator
	Ci_NBIT <= (others => Ci);
	B_XOR   <= B xor Ci_NBIT;
	CARRY_GEN : CARRY_GENERATOR generic map(NBIT => NBIT, NBIT_PER_BLOCK => NBIT_PER_BLOCK)
	port map
		(A => A, B => B_XOR, Cin => Ci, Co => Co_s);

	SUM_GEN : SUM_GENERATOR generic map(NBIT_PER_BLOCK => NBIT_PER_BLOCK, NBLOCKS => NBIT/NBIT_PER_BLOCK)
	port map(A => A, B => B_XOR, Ci => Ci_sg, S => S);

	-- the most significant carry produced by the carry generator becomes the carry out of the P4 adder
	Cout <= Co_s(NBIT/NBIT_PER_BLOCK - 1);
	-- the sum generator needs Ci as first carry in
	Ci_sg <= Co_s(NBIT/NBIT_PER_BLOCK - 2 downto 0) & Ci;

end STRUCT;

configuration CFG_P4_ADD of P4_ADDER is
	for STRUCT
		for CARRY_GEN : CARRY_GENERATOR
			use configuration WORK.CFG_CG_STRUCT;
		end for;
		for SUM_GEN : SUM_GENERATOR
			use configuration WORK.CFG_SUM_GEN_STRUCT;
		end for;
	end for;
end CFG_P4_ADD;