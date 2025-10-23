library ieee;
use ieee.std_logic_1164.all;

entity PG_LOGIC is
	generic (
		NBIT : integer := 32
	);
	port (
		a, b : in std_logic_vector(NBIT - 1 downto 0);
		Cin  : in std_logic;
		p, g : out std_logic_vector(NBIT - 1 downto 0)
	);
end PG_LOGIC;

architecture behavioral_or of PG_LOGIC is

begin
	process (a, b)
	begin
		bitwise : for i in 0 to NBIT - 1 loop
			p(i) <= a(i) or b(i);
			g(i) <= a(i) and b(i);
		end loop;
		--g0 + p0 * cin
		g(0) <= (a(0) and b(0)) or ((a(0) or b(0)) and Cin);
	end process;

end behavioral_or;

architecture behavioral_xor of PG_LOGIC is

begin
	process (a, b)
	begin
		bitwise : for i in 0 to NBIT - 1 loop
			p(i) <= a(i) xor b(i);
			g(i) <= a(i) and b(i);
		end loop;
		--g0 + p0 * cin
		g(0) <= (a(0) and b(0)) or ((a(0) xor b(0)) and Cin);
	end process;
	
end behavioral_xor;

configuration CFG_PG_LOGIC_OR of PG_LOGIC is
	for behavioral_or
	end for;
end CFG_PG_LOGIC_OR;

configuration CFG_PG_LOGIC_XOR of PG_LOGIC is
	for behavioral_or
	end for;
end CFG_PG_LOGIC_XOR;