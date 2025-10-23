library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity T2_SHIFTER is
    port(
        data: in std_logic_vector(31 downto 0); -- 32 bit data
        shift_amount: in std_logic_vector(4 downto 0); -- shift amount                                          
        left_not_right: in std_logic; --  1: shift left
        arith_not_logic: in std_logic; -- 1: arithmetic shift (if left shift, no effect)
        o: out std_logic_vector(31 downto 0)
    );
end T2_SHIFTER;

architecture STRUCTURAL of T2_SHIFTER is

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

component MUX_4_1 is
    generic(
        N: natural
    );
    port(
        a1,a2,a3,a4: in std_logic_vector(N-1 downto 0);
        sel: std_logic_vector(1 downto 0);
        o: out std_logic_vector(N-1 downto 0)
    );
end component MUX_4_1;

component MUX_8_1 is
    generic(
        N: natural
    );
    port(
        a1,a2,a3,a4,a5,a6,a7,a8: in std_logic_vector(N-1 downto 0);
        sel: std_logic_vector(2 downto 0);
        o: out std_logic_vector(N-1 downto 0)
    );
end component MUX_8_1;

function repeat_bit(b : std_logic; N : natural) return std_logic_vector is
    variable result : std_logic_vector(N-1 downto 0);
    begin
        for i in 0 to N-1 loop
            result(i) := b;
        end loop;
        return result;
end function;


signal mask_mux_00_sl, mask_mux_08_sl, mask_mux_16_sl, mask_mux_24_sl: std_logic_vector(38 downto 0);
signal mask_mux_00_srl, mask_mux_08_srl, mask_mux_16_srl, mask_mux_24_srl: std_logic_vector(38 downto 0);
signal mask_mux_00_sra, mask_mux_08_sra, mask_mux_16_sra, mask_mux_24_sra: std_logic_vector(38 downto 0);
signal mask_sl, mask_sr, mask_srl, mask_sra: std_logic_vector(38 downto 0);
signal selected_mask: std_logic_vector(38 downto 0);
signal shift_amount_lsb, shift_amount_lsb_negated, selected_shift_amount: std_logic_vector(2 downto 0);

begin
    --mask_generation
    mask_mux_00_sl <= (data(31 downto 0) & repeat_bit('0', 7));
    mask_mux_00_srl <= (repeat_bit('0', 7) & data(31 downto 0));
    mask_mux_00_sra <= (repeat_bit(data(31), 7) & data(31 downto 0));
    
    mask_mux_08_sl <= (data(23 downto 0) & repeat_bit('0', 15));
    mask_mux_08_srl <= (repeat_bit('0', 15) & data(31 downto 8));
    mask_mux_08_sra <= (repeat_bit(data(31), 15) & data(31 downto 8));
    
    mask_mux_16_sl <= (data(15 downto 0) & repeat_bit('0', 23));
    mask_mux_16_srl <= (repeat_bit('0', 23) & data(31 downto 16));
    mask_mux_16_sra <= (repeat_bit(data(31), 23) & data(31 downto 16));
    
    mask_mux_24_sl <= (data(7 downto 0) & repeat_bit('0', 31));
    mask_mux_24_srl <= (repeat_bit('0', 31) & data(31 downto 24));
    mask_mux_24_sra <= (repeat_bit(data(31), 31) & data(31 downto 24));     
    
    -- coarse-grained shift
    mux_sl: MUX_4_1 generic map(N => 39) 
        port map(a1 => mask_mux_00_sl, a2 => mask_mux_08_sl, a3 => mask_mux_16_sl, a4 => mask_mux_24_sl, sel => shift_amount(4 downto 3), o => mask_sl);
    mux_srl: MUX_4_1 generic map(N => 39) 
        port map(a1 => mask_mux_00_srl, a2 => mask_mux_08_srl, a3 => mask_mux_16_srl, a4 => mask_mux_24_srl, sel => shift_amount(4 downto 3), o => mask_srl);
    mux_sra: MUX_4_1 generic map(N => 39) 
        port map(a1 => mask_mux_00_sra, a2 => mask_mux_08_sra, a3 => mask_mux_16_sra, a4 => mask_mux_24_sra, sel => shift_amount(4 downto 3), o => mask_sra);
    
    -- mask selection
    mux_arith_logic: MUX_2_1 generic map(N => 39)
        port map(a1 => mask_srl, a2 => mask_sra, sel => arith_not_logic, o => mask_sr);
    mux_left_right: MUX_2_1 generic map(N => 39)
        port map(a1 => mask_sr, a2 => mask_sl, sel => left_not_right, o => selected_mask);
    
    shift_amount_lsb <= shift_amount(2 downto 0);
    shift_amount_lsb_negated <= not shift_amount_lsb;
    mux_shift_amount: MUX_2_1 generic map(N => 3)
        port map(a1 => shift_amount_lsb, a2 => shift_amount_lsb_negated, sel => left_not_right, o => selected_shift_amount);
    
    -- fine-grained shift
    mux_fine_grained: MUX_8_1 generic map(N => 32)
        port map(
            a1 => selected_mask(31 downto 0), 
            a2 => selected_mask(32 downto 1), 
            a3 => selected_mask(33 downto 2), 
            a4 => selected_mask(34 downto 3),
            a5 => selected_mask(35 downto 4), 
            a6 => selected_mask(36 downto 5), 
            a7 => selected_mask(37 downto 6), 
            a8 => selected_mask(38 downto 7),
            sel => selected_shift_amount,
            o => o
        );
            
end STRUCTURAL;
