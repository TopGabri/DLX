library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALU_TB is

end ALU_TB;

architecture TB_ARCH of ALU_TB is

component ALU is
    port (
        A, B    : in std_logic_vector(31 downto 0);
        Sel     : in std_logic_vector(10 downto 0);
        ALU_OUT : out std_logic_vector(31 downto 0)
    );
end component ALU;

signal a_s, b_s, o_s: std_logic_vector(31 downto 0);
signal sel_s: std_logic_vector(10 downto 0);

signal sel_logicals, sel_out: std_logic_vector(2 downto 0) := "000";
signal sh_left, sh_arith, cin, SnU, sel_eq: std_logic := '0';

begin

sel_s <= sel_out & cin & SnU & sel_eq & sel_logicals & sh_left & sh_arith;

DUT: ALU port map(
    A => a_s, B => b_s, SEL => sel_s, ALU_OUT => o_s
);

test_process: process
begin
    a_s <= (others => '0'); b_s <= (others => '0');
    sel_logicals <= "000"; sel_out <= "000";
    sh_left <= '0'; sh_arith <= '0'; cin <= '0'; Snu <= '0'; sel_eq <= '0';
    
    wait for 2 ns;
    a_s <= X"C49BF30D"; b_s <= X"140A3567";
    
    --add
    sel_out <= "000";
    cin <= '0';
    wait for 1 ns;
    assert(o_s = X"D8A62874") 
    report ("add not correct");
    wait for 2 ns;
    
    --sub
    sel_out <= "000";
    cin <= '1';
    wait for 1 ns;
    assert(o_s = X"B091BDA6")
    report ("sub not correct");
    wait for 2 ns;
    
    a_s <= X"80000000"; b_s <= X"0FFFFFFF";
    
    --ge unsigned
    sel_out <= "001";
    cin <= '1'; SnU <= '0';
    wait for 1 ns;
    assert(o_s = X"00000001")
    report ("GE unsigned not correct");
    wait for 2 ns;
    
    --ge signed
    SnU <= '1';
    wait for 1 ns;
    assert(o_s = X"00000000")
    report("GE signed not correct");
    wait for 2 ns;
    
    --le unsigned
    sel_out <= "010";
    cin <= '1'; SnU <= '0';
    wait for 1 ns;
    assert(o_s = X"00000000")
    report("LE unsigned not correct");
    wait for 2 ns;
    
    --le signed
    cin <= '1'; SnU <= '1';
    wait for 1 ns;
    assert(o_s = X"00000001")
    report("LE signed not correct");
    wait for 2 ns;
    
    --gt unsigned
    sel_out <= "011";
    cin <= '1'; SnU <= '0';
    wait for 1 ns;
    assert(o_s = X"00000001")
    report ("GT unsigned not correct");
    wait for 2 ns;
    
    --gt signed
    SnU <= '1';
    wait for 1 ns;
    assert(o_s = X"00000000")
    report("GT signed not correct");
    wait for 2 ns;
    
    --lt unsigned
    sel_out <= "100";
    cin <= '1'; SnU <= '0';
    wait for 1 ns;
    assert(o_s = X"00000000")
    report("LT unsigned not correct");
    wait for 2 ns;
    
    --lt signed
    cin <= '1'; SnU <= '1';
    wait for 1 ns;
    assert(o_s = X"00000001")
    report("LT signed not correct");
    wait for 2 ns;
    
    --ne
    sel_out <= "101";
    cin <= '1'; sel_eq <= '0';
    wait for 1 ns;
    assert(o_s = X"00000001")
    report("NE not correct");
    wait for 2 ns;
    
    
    a_s <= X"11111111"; b_s <= X"11111111";
    
    --eq
    sel_out <= "101";
    cin <= '1'; sel_eq <= '1';
    wait for 1 ns;
    assert(o_s = X"00000001")
    report("EQ not correct");
    wait for 2 ns;
    
    a_s <= X"00001111"; b_s <= X"11110000";    
        
    --and
    sel_out <= "110";
    sel_logicals <= "001";
    wait for 1 ns;
    assert(o_s = X"00000000")
    report("AND not correct");
    wait for 2 ns;
    
        
    --xor
    sel_out <= "110";
    sel_logicals <= "110";
    wait for 1 ns;
    assert(o_s = X"11111111")
    report("XOR not correct");
    wait for 2 ns;
    
     --or
    sel_out <= "110";
    sel_logicals <= "111";
    assert(o_s = X"11111111")
    report("OR not correct");
    wait for 2 ns;
    
    a_s <= X"F2A4C678";
    b_s <= X"00000005";
    
    --shift_right_logic
    sel_out <= "111";
    sh_left <= '0';
    sh_arith <= '0';
    wait for 1 ns;
    assert(o_s = X"07952633")
    report("SRL not correct");
    wait for 2 ns;
    
    
    --shift_right_arith
    sel_out <= "111";
    sh_left <= '0';
    sh_arith <= '1';
    wait for 1 ns;
    assert(o_s = X"FF952633")
    report("SRA not correct");
    wait for 2 ns;

    
    --shift_left
    sel_out <= "111";
    sh_left <= '1';
    wait for 1 ns;
    assert(o_s = X"5498CF00")
    report("SRL not correct");
    wait for 2 ns;
    
    
    a_s <= X"AAAAAAAA"; b_s <= X"00000000";
    
    --add
    sel_out <= "000";
    cin <= '0';
    wait for 2 ns;
    
    --sub
    sel_out <= "000";
    cin <= '1';
    wait for 2 ns;
    
    --shift_left
    sel_out <= "101";
    sh_left <= '1';
    wait for 2 ns;
    
    --shift_right_arith
    sel_out <= "101";
    sh_left <= '0';
    sh_arith <= '1';
    wait for 2 ns;
    
    --shift_right_logic
    sel_out <= "101";
    sh_left <= '0';
    sh_arith <= '0';
    wait for 2 ns;
    
    --and
    sel_out <= "100";
    sel_logicals <= "001";
    wait for 2 ns;
    
    --or
    sel_out <= "100";
    sel_logicals <= "111";
    wait for 2 ns;
    
    --xor
    sel_out <= "100";
    sel_logicals <= "110";
    wait for 2 ns;
    
    --ge
    cin <= '1';
    sel_out <= "001";
    wait for 2 ns;
    
    --le
    cin <= '1';
    sel_out <= "010";
    wait for 2 ns;
    
    --ne
    cin <= '1';
    sel_out <= "011";
    wait for 2 ns;
    
    a_s <= X"01230123"; b_s <= X"00040004";
    
    --add
    sel_out <= "000";
    cin <= '0';
    wait for 2 ns;
    
    --sub
    sel_out <= "000";
    cin <= '1';
    wait for 2 ns;
    
    --shift_left
    sel_out <= "101";
    sh_left <= '1';
    wait for 2 ns;
    
    --shift_right_arith
    sel_out <= "101";
    sh_left <= '0';
    sh_arith <= '1';
    wait for 2 ns;
    
    --shift_right_logic
    sel_out <= "101";
    sh_left <= '0';
    sh_arith <= '0';
    wait for 2 ns;
    
    --and
    sel_out <= "100";
    sel_logicals <= "001";
    wait for 2 ns;
    
    --or
    sel_out <= "100";
    sel_logicals <= "111";
    wait for 2 ns;
    
    --xor
    sel_out <= "100";
    sel_logicals <= "110";
    wait for 2 ns;
    
    --ge
    cin <= '1';
    sel_out <= "001";
    wait for 2 ns;
    
    --le
    cin <= '1';
    sel_out <= "010";
    wait for 2 ns;
    
    --ne
    cin <= '1';
    sel_out <= "011";
    wait for 2 ns;
    
    wait;
end process;

end TB_ARCH;

configuration CFG_ALU_TB of ALU_TB is
    for TB_ARCH
        for DUT : ALU
            use configuration WORK.CFG_ALU;
        end for;
    end for;
end CFG_ALU_TB;