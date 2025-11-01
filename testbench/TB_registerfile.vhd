library IEEE;

use IEEE.std_logic_1164.all;

entity TBREGISTERFILE is
end TBREGISTERFILE;

architecture TESTA of TBREGISTERFILE is

	constant NBIT_ADD  : integer   := 8;
	constant NBIT_DATA : integer   := 8;
	signal Clk         : std_logic := '0';
	signal reset       : std_logic;
	signal enable      : std_logic;
	signal rd1         : std_logic;
	signal rd2         : std_logic;
	signal wr          : std_logic;
	signal add_wr      : std_logic_vector(NBIT_ADD - 1 downto 0);
	signal add_rd1     : std_logic_vector(NBIT_ADD - 1 downto 0);
	signal add_rd2     : std_logic_vector(NBIT_ADD - 1 downto 0);
	signal datain      : std_logic_vector(NBIT_DATA - 1 downto 0);
	signal out1        : std_logic_vector(NBIT_DATA - 1 downto 0);
	signal out2        : std_logic_vector(NBIT_DATA - 1 downto 0);
	component register_file is
		generic (
			NBIT_ADD  : integer := 5;
			NBIT_DATA : integer := 64);
		port (
			Clk     : in std_logic;
			reset   : in std_logic;
			enable  : in std_logic;
			rd1     : in std_logic;
			rd2     : in std_logic;
			wr      : in std_logic;
			add_wr  : in std_logic_vector(NBIT_ADD - 1 downto 0);
			add_rd1 : in std_logic_vector(NBIT_ADD - 1 downto 0);
			add_rd2 : in std_logic_vector(NBIT_ADD - 1 downto 0);
			datain  : in std_logic_vector(NBIT_DATA - 1 downto 0);
			out1    : out std_logic_vector(NBIT_DATA - 1 downto 0);
			out2    : out std_logic_vector(NBIT_DATA - 1 downto 0)
		);
	end component;

begin

	RG : register_file

	generic map(NBIT_ADD, NBIT_DATA)

	port map(Clk, reset, enable, rd1, rd2, wr, add_wr, add_rd1, add_rd2, datain, out1, out2);
	reset   <= '1', '0' after 5 ns;
	enable  <= '0', '1' after 3 ns, '0' after 10 ns, '1' after 15 ns;
	wr      <= '0', '1' after 6 ns, '0' after 7 ns, '1' after 10 ns, '0' after 20 ns;
	rd1     <= '1', '0' after 5 ns, '1' after 13 ns, '0' after 20 ns;
	rd2     <= '0', '1' after 17 ns;
	add_wr  <= x"1F", x"10" after 9 ns;
	add_rd1 <= x"1F", x"01" after 9 ns;
	add_rd2 <= x"1F", x"10" after 9 ns;
	datain  <= x"0A", x"0F" after 8 ns;

	PCLOCK : process (Clk)
	begin
		Clk <= not(Clk) after 0.5 ns;
	end process;

end TESTA;

---
configuration CFG_TESTRF of TBREGISTERFILE is
	for TESTA
		for RG : register_file
			use configuration WORK.CFG_RF_BEH;
		end for;
	end for;
end CFG_TESTRF;