library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity RCA_GENERIC is
	generic (N : integer := 6);
	port (
		A  : in std_logic_vector(N - 1 downto 0);
		B  : in std_logic_vector(N - 1 downto 0);
		Ci : in std_logic;
		S  : out std_logic_vector(N - 1 downto 0);
		Co : out std_logic
	);
end RCA_GENERIC;

architecture STRUCTURAL of RCA_GENERIC is

signal STMP : std_logic_vector(N - 1 downto 0);
signal CTMP : std_logic_vector(N downto 0);

component FA
	port (
		A  : in std_logic;
		B  : in std_logic;
		Ci : in std_logic;
		S  : out std_logic;
		Co : out std_logic);
end component;

begin

CTMP(0) <= Ci;
S       <= STMP;
Co      <= CTMP(N);

ADDER1 : for I in 1 to N generate
	FAI : FA port map(A(I - 1), B(I - 1), CTMP(I - 1), STMP(I - 1), CTMP(I));
end generate;

end STRUCTURAL;

architecture BEHAVIORAL of RCA_GENERIC is

begin

process (A, B)
	variable temp : std_logic_vector(N downto 0);
begin
	temp := (('0' & A) + ('0' & B) + ((N-1 downto 0 => '0') & Ci));

	co <= temp(N);
	S  <= temp(N - 1 downto 0);
end process;

end BEHAVIORAL;

configuration CFG_RCA_STRUCTURAL of RCA_GENERIC is
for STRUCTURAL
	for ADDER1
		for all : FA
			use configuration WORK.CFG_FA_BEHAVIORAL;
		end for;
	end for;
end for;
end CFG_RCA_STRUCTURAL;

configuration CFG_RCA_BEHAVIORAL of RCA_GENERIC is
for BEHAVIORAL
end for;
end CFG_RCA_BEHAVIORAL;