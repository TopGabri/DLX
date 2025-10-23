library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUX_2_1 is
    generic(
        N: natural
    );
    port(
        a1,a2: in std_logic_vector(N-1 downto 0);
        sel: std_logic;
        o: out std_logic_vector(N-1 downto 0)
    );
end MUX_2_1;

architecture DATAFLOW of MUX_2_1 is

begin

    o <= a1 when (sel = '0') else a2;

end DATAFLOW;

architecture STRUCTURAL of MUX_2_1 is

component MUX_2_1_1bit is
    port (
        A : in std_logic;
        B : in std_logic;
        S : in std_logic;
        Y : out std_logic);
end component MUX_2_1_1bit;

signal o_s: std_logic_vector(N-1 downto 0);

begin

    gen_mux: for i in 0 to N-1 generate
        mux_inst: MUX_2_1_1bit
        port map(
            A => a1(i),
            B => a2(i),
            S => sel,
            Y => o_s(i)
        );
    end generate;

    o <= o_s;

end STRUCTURAL;

configuration CFG_MUX_2_1_DATAFLOW of MUX_2_1 is
  for DATAFLOW 
  end for;
end CFG_MUX_2_1_DATAFLOW;

configuration CFG_MUX_2_1_STRUCTURAL of MUX_2_1 is
  for STRUCTURAL
  end for;
end CFG_MUX_2_1_STRUCTURAL;