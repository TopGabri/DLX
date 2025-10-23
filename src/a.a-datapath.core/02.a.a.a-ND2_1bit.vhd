library ieee;
use ieee.std_logic_1164.all;

entity ND2 is
    port (
        A : in std_logic;
        B : in std_logic;
        Y : out std_logic);
end ND2;

architecture DATAFLOW of ND2 is

begin
    Y <= not(A and B);

end DATAFLOW;