library ieee;
use ieee.std_logic_1164.all;

entity PG_BLOCK is
	port (
		Gik, Pik, Gk1j, Pk1j : in std_logic;
		Gij, Pij             : out std_logic
	);
end PG_BLOCK;

architecture dataflow of PG_BLOCK is

begin

	Gij <= Gik or (Pik and Gk1j);
	Pij <= Pik and Pk1j;

end dataflow;