library ieee;
use ieee.std_logic_1164.all;

entity G_BLOCK is
	port (
		Gik, Pik, Gk1j : in std_logic;
		Gij            : out std_logic
	);
end G_BLOCK;

architecture dataflow of G_BLOCK is

begin

	Gij <= Gik or (Pik and Gk1j);

end dataflow;