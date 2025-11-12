library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;


entity BHT is
    generic (
        BHT_SIZE : integer := 16; -- number of entries in the BHT
        ADDR_SIZE : integer := 4;  -- number of bits used for indexing the
        FILE_PATH : string
    );
    port (
        Clk : in std_logic;
        Rst : in std_logic;
        -- inputs
        PC_1    : in std_logic_vector(31 downto 0); -- ID stage PC (for prediction)
        PC_2    : in std_logic_vector(31 downto 0); -- EX stage PC  (for update)
        Taken : in std_logic;                     -- actual branch outcome from EX stage
        Update: in std_logic;                     -- update prediction 
        -- outputs
        Prediction_1 : out std_logic; -- predicted branch outcome 
        Prediction_2 : out std_logic  -- predicted branch outcome 
    );
end BHT;
architecture BEHAVIORAL of BHT is

    type BHT_type is array (0 to BHT_SIZE - 1) of std_logic_vector(1 downto 0);
    signal BHT : BHT_type;

    procedure rewrite_content(data : in BHT_type; path_file : string) is
        variable index   : natural range 0 to BHT_SIZE - 1;
        file wr_file     : text;
        variable line_in : line;
        variable addr    : integer := 0;

    begin
        file_open(wr_file, path_file, WRITE_MODE);

        -- write header
        write(line_in, string'("address        content"));
        writeline(wr_file, line_in);

        for index in 0 to BHT_SIZE - 1 loop
            line_in := null;

            -- write address in hex with 0x prefix
            write(line_in, addr);
            write(line_in, string'("     ")); -- separator

            -- write content
            write(line_in, data(index));

            writeline(wr_file, line_in);

            addr := addr + 1;
        end loop;

        file_close(wr_file);
    end procedure;


begin


    process (Clk, Rst, Update, Taken, PC_1, PC_2, BHT)

    variable index_1, index_2 : integer range 0 to BHT_SIZE - 1;

    begin

        index_1 := to_integer(unsigned(PC_1(ADDR_SIZE - 1 + 2 downto 2))); -- index for prediction 1
        index_2 := to_integer(unsigned(PC_2(ADDR_SIZE - 1 + 2 downto 2))); -- index for prediction 2

        -- write in BHT
        if Rst = '1' then
            -- Initialize BHT entries to weakly not taken (01)
            for i in 0 to BHT_SIZE - 1 loop
                BHT(i) <= "01";
            end loop;
        elsif (Update = '1' and rising_edge(Clk)) then   
            -- Update BHT entry based on actual branch outcome
            if Taken = '1' then
                -- Update BHT entry for taken branch
                case BHT(index_2) is
                    when "00"   => BHT(index_2) <= "01"; -- Strongly not taken -> Weakly not taken
                    when "01"   => BHT(index_2) <= "10"; -- Weakly not taken -> Weakly taken
                    when "10"   => BHT(index_2) <= "11"; -- Weakly taken -> Strongly taken
                    when "11"   => BHT(index_2) <= "11"; -- Strongly taken -> Remain strongly taken
                    when others => BHT(index_2) <= "01"; -- Default case (should not occur)
                end case;
            else
                -- Update BHT entry for not taken branch
                case BHT(index_2) is
                    when "00"   => BHT(index_2) <= "00"; -- Strongly not taken -> Remain strongly not taken
                    when "01"   => BHT(index_2) <= "00"; -- Weakly not taken -> Strongly not taken
                    when "10"   => BHT(index_2) <= "01"; -- Weakly taken -> Weakly not taken
                    when "11"   => BHT(index_2) <= "10"; -- Strongly taken -> Weakly taken
                    when others => BHT(index_2) <= "01"; -- Default case (should not occur)
                end case;
            end if;
        end if;

        -- Predict branch outcome 1 (for ID stage)
        case BHT(index_1) is
            when "00"   => Prediction_1   <= '0'; -- Strongly not taken
            when "01"   => Prediction_1   <= '0'; -- Weakly not taken
            when "10"   => Prediction_1   <= '1'; -- Weakly taken
            when "11"   => Prediction_1   <= '1'; -- Strongly taken
            when others => Prediction_1 <= '0';   -- Default case (should not occur)
        end case;

        -- Predict branch outcome 2 (for EX stage)
        case BHT(index_2) is
            when "00"   => Prediction_2   <= '0'; -- Strongly not taken
            when "01"   => Prediction_2   <= '0'; -- Weakly not taken
            when "10"   => Prediction_2   <= '1'; -- Weakly taken
            when "11"   => Prediction_2   <= '1'; -- Strongly taken
            when others => Prediction_2 <= '0';   -- Default case (should not occur)
        end case;
    end process;


    -- Write BHT content to file
    rewrite_content(BHT, FILE_PATH);


end BEHAVIORAL;
