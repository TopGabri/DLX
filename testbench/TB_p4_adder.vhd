library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity TB_P4_ADDER is
end TB_P4_ADDER;

architecture TEST of TB_P4_ADDER is
	
	-- P4 component declaration
	component P4_ADDER is
		generic (
			NBIT :		integer := 32;
		  NBIT_PER_BLOCK: integer := 4);
		port (
			A :		in	std_logic_vector(NBIT-1 downto 0);
			B :		in	std_logic_vector(NBIT-1 downto 0);
			Ci :	in	std_logic;
			S :		out	std_logic_vector(NBIT-1 downto 0);
			Cout :	out	std_logic);
	end component;
	

	constant NBIT: integer := 32;
	constant NBIT_PER_BLOCK : integer := 4;
	signal A,B,S: std_logic_vector(NBIT-1 downto 0);
	signal Cin,Cout: std_logic;

	
begin
	-- P4 instantiation
		
	UUT: P4_ADDER generic map (NBIT, NBIT_PER_BLOCK)
								port map(A,B,Cin,S,Cout);


	TestProcess: process
	begin
		A <= x"00000001"; B <= x"00000002"; Cin <= '0';
		wait for 5 ns;
		A <= x"00000005"; B <= x"00000003"; Cin <= '0';
		wait for 5 ns;
		A <= x"00000002"; B <= x"00000001"; Cin <= '1';
		wait for 5 ns;
		A <= x"2349ABCD"; B <= x"000111FF"; Cin <= '1';
		wait for 5 ns;
		A <= x"AAAAAAAA"; B <= x"55555555"; Cin <= '1';
		wait for 5 ns;
		A <= x"FFFFFFFF"; B <= x"00000001"; Cin <= '0';
		wait;
  end process TestProcess;
	
	
end TEST;


configuration CFG_TEST_P4 of TB_P4_ADDER is
	for TEST
		for UUT: P4_ADDER
			use configuration WORK.CFG_P4_ADD;
		end for;
	end for;
end CFG_TEST_P4;
	



