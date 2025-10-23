library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity EQUALITY_COMPARATOR is
    generic (
        N : integer := 8   -- width of input vectors
    );
    port (
        A, B  : in  std_logic_vector(N-1 downto 0);
        EQ    : out std_logic
    );
end entity EQUALITY_COMPARATOR;

architecture STRUCTURAL of EQUALITY_COMPARATOR is

    -- Internal signals
    signal xnor_out : std_logic_vector(N-1 downto 0);

begin

    -- Generate N XNOR gates
    gen_xnor: for i in 0 to N-1 generate
        xnor_out(i) <= A(i) xnor B(i);
    end generate;

    -- AND all XNOR results together
    process(xnor_out)
        variable and_result : std_logic := '1';
    begin
        and_result := '1';
        for i in 0 to N-1 loop
            and_result := and_result and xnor_out(i);
        end loop;
        EQ <= and_result;
    end process;

end architecture STRUCTURAL;
