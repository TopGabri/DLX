library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity COMPARATOR is
  port (
    Z    : in std_logic; -- Zero flag
    Cout : in std_logic; -- Carry out flag
    S    : in std_logic; -- Sign flag
    SA   : in std_logic; -- First operand sign bit
    SB   : in std_logic; -- Second operand sign bit
    SnU  : in std_logic; -- Selection of signed/unsigned comparison
    LT   : out std_logic;
    GT   : out std_logic;
    LE   : out std_logic;
    GE   : out std_logic
  );
end COMPARATOR;

architecture behavioral of COMPARATOR is
  signal OVF : std_logic; -- overflow flag
  signal LTU, GTU, LEU, GEU : std_logic; -- unsigned comparison results
  signal LTS, GTS, LES, GES : std_logic; -- signed comparison results

begin

  -- UNSIGNED COMPARISON
  -- A<B if Cout is '0' 
  -- A>B if Cout is '1' and Z is '0'
  -- A<=B if Z is '1' or Cout is '0'
  -- A>=B if Cout is '1'

  LTU <= not(Cout);
  GTU <= Cout and (not(Z));
  LEU <= (not Cout) or Z;
  GEU <= Cout;


  --SIGNED COMPARISON

  OVF <= (SA xor SB) and (SA xor S);    -- Overflow detection

  LTS <= S xor OVF;
  GTS <= not((S xor OVF) or Z);
  LES <= (S xor OVF) or Z;
  GES <= (not (S xor OVF)) or Z;

  -- SELECTION BETWEEN SIGNED AND UNSIGNED COMPARISON
  LT <= (SnU and LTS) or (not SnU and LTU);
  GT <= (SnU and GTS) or (not SnU and GTU);
  LE <= (SnU and LES) or (not SnU and LEU);
  GE <= (SnU and GES) or (not SnU and GEU); 


end behavioral;