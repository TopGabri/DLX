library ieee;
use ieee.std_logic_1164.all;

entity IV is
    port (
        A : in std_logic;
        Y : out std_logic);
end IV;

architecture DATAFLOW of IV is

begin
    Y <= not(A);

end DATAFLOW;