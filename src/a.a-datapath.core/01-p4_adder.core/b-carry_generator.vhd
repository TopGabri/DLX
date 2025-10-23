library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity CARRY_GENERATOR is
	generic (
		NBIT           : integer := 32;
		NBIT_PER_BLOCK : integer := 4);
	port (
		A   : in std_logic_vector(NBIT - 1 downto 0);
		B   : in std_logic_vector(NBIT - 1 downto 0);
		Cin : in std_logic;
		Co  : out std_logic_vector((NBIT/NBIT_PER_BLOCK) - 1 downto 0));
end entity;

architecture structural of CARRY_GENERATOR is

	function log2 (x : integer) return integer is
		variable temp    : integer := x;
		variable n       : integer := 0;
	begin
		while temp > 1 loop
			temp := temp / 2;
			n    := n + 1;
		end loop;
		return n;
	end function log2;

	function is_power2 (x : integer) return boolean is
		variable power        : integer := 1;
	begin
		while power < x loop
			power := 2 * power;
		end loop;
		if power = x then
			return true;
		else
			return false;
		end if;
	end function is_power2;

	component PG_BLOCK is
		port (
			Gik, Pik, Gk1j, Pk1j : in std_logic;
			Gij, Pij             : out std_logic
		);
	end component;

	component G_BLOCK is
		port (
			Gik, Pik, Gk1j : in std_logic;
			Gij            : out std_logic
		);
	end component;

	component PG_LOGIC is
		generic (
			NBIT : integer := 32
		);
		port (
			a, b : in std_logic_vector(NBIT - 1 downto 0);
			Cin  : in std_logic;
			p, g : out std_logic_vector(NBIT - 1 downto 0)
		);
	end component;

	constant n_steps : integer := log2(NBIT);
	type Matrix is array (n_steps downto 0) of std_logic_vector(NBIT downto 1);
	signal p, g : Matrix;

begin
	-- connect first row (0) to PG_LOGIC
	pgLogic : PG_LOGIC generic map(NBIT) port map(a => A, b => B, Cin => Cin, p => p(0), g => g(0));

	rowLoop : for i in 1 to n_steps generate
		columnLoop : for j in 1 to NBIT generate

			--start regular structure
			placingGBlocks : if (j = 2 ** i) generate
				gBlock_i : G_BLOCK port map(Gik => g(i - 1)(j), Pik => p(i - 1)(j), Gk1j => g(i - 1)(j - 2 ** (i - 1)), Gij => g(i)(j));
			end generate placingGBlocks;
			placingPGBlocks : if (j > 2 ** i) and (j mod (2 ** i)) = 0 generate
				pgBlock_i : PG_BLOCK port map(Gik => g(i - 1)(j), Pik => p(i - 1)(j), Gk1j => g(i - 1)(j - 2 ** (i - 1)), Pk1j => p(i - 1)(j - 2 ** (i - 1)), Gij => g(i)(j), Pij => p(i)(j));
			end generate placingPGBlocks;
			--end regular structure

			--MISSING EXTRA PG-BLOCKS
			placingExtraPGBlocks : if (j > 2 ** (i)) and (j mod NBIT_PER_BLOCK) = 0 and (j mod (2 ** i)) /= 0 and
				not(is_power2(j mod 2 ** i)) and (j mod 2 ** i) /= (j mod 2 ** (i - 1)) generate
					pgBlock_extra : PG_BLOCK port map(
						Gik => g(i - 1)(j), Pik => p(i - 1)(j),
						Gk1j => g(i - 1)(j - (j mod 2 ** (i - 1))),
						Pk1j => p(i - 1)(j - (j mod 2 ** (i - 1))),
						Gij => g(i)(j), Pij => p(i)(j));
				end generate placingExtraPGBlocks;

				placingExtraGBlocks : if (j > 2 ** (i - 1)) and (j < 2 ** (i)) and (j mod NBIT_PER_BLOCK) = 0 generate
					gBlock_extra : G_BLOCK port map(Gik => g(i - 1)(j), Pik => p(i - 1)(j), Gk1j => g(i - 1)(2 ** (i - 1)), Gij => g(i)(j));
				end generate placingExtraGBlocks;
				--no ELSE statement in this version of VHDL...
				connectRows : if
					(not(j = 2 ** i)) and
					(not((j > 2 ** i) and (j mod (2 ** i)) = 0)) and
					(not((j > 2 ** (i)) and (j mod (2 ** i)) /= 0 and (j mod NBIT_PER_BLOCK) = 0 and
					not(is_power2(j mod 2 ** i)) and (j mod 2 ** i) /= (j mod 2 ** (i - 1)))) and
					(not((j > 2 ** (i - 1)) and (j < 2 ** (i)) and (j mod NBIT_PER_BLOCK) = 0)) generate
						p(i)(j) <= p(i - 1)(j);
						g(i)(j) <= g(i - 1)(j);
					end generate connectRows;

				end generate columnLoop;
			end generate rowLoop;

			-- connect last row to output
			outLoop : for j in 0 to (NBIT/NBIT_PER_BLOCK) - 1 generate
				co(j) <= g(n_steps)((j + 1) * NBIT_PER_BLOCK);
			end generate outLoop;

		end structural;
		configuration CFG_CG_STRUCT of CARRY_GENERATOR is
			for structural
			end for;
		end CFG_CG_STRUCT;