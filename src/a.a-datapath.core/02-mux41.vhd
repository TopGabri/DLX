library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUX_4_1 is
    generic(
        N: natural
    );
    port(
        a1,a2,a3,a4: in std_logic_vector(N-1 downto 0);
        sel: std_logic_vector(1 downto 0);
        o: out std_logic_vector(N-1 downto 0)
    );
end MUX_4_1;

architecture DATAFLOW of MUX_4_1 is

begin

    with sel select
        o <= a1 when "00",
             a2 when "01",
             a3 when "10",
             a4 when others;

end DATAFLOW;

architecture STRUCTURAL of MUX_4_1 is

component MUX_2_1 is
    generic(
        N: natural
    );
    port(
        a1,a2: in std_logic_vector(N-1 downto 0);
        sel: std_logic;
        o: out std_logic_vector(N-1 downto 0)
    );
end component MUX_2_1;

signal o1, o2: std_logic_vector(N-1 downto 0);

begin
    
    mux1: MUX_2_1 generic map(N => N) port map (a1 => a1, a2 => a2, sel => sel(0), o => o1);
    mux2: MUX_2_1 generic map(N => N) port map (a1 => a3, a2 => a4, sel => sel(0), o => o2);
    mux3: MUX_2_1 generic map(N => N) port map (a1 => o1, a2 => o2, sel => sel(1), o => o);

end STRUCTURAL;

--CONFIGURATIONS

configuration CFG_MUX_4_1_DATAFLOW of MUX_4_1 is
  for DATAFLOW 
  end for;
end CFG_MUX_4_1_DATAFLOW;

configuration CFG_MUX_4_1_STRUCTURAL of MUX_4_1 is
  for STRUCTURAL
    for all : MUX_2_1
        use configuration WORK.CFG_MUX_2_1_STRUCTURAL;
    end for;
  end for;
end CFG_MUX_4_1_STRUCTURAL;
