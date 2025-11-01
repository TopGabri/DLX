library ieee;
use ieee.std_logic_1164.all;
entity TB_BHT is
end TB_BHT;

architecture BEHAVIORAL of TB_BHT is

    -- Component Declaration for the Unit Under Test (UUT)
    component BHT
        generic (
            BHT_SIZE  : integer := 16; -- number of entries in the BHT
            ADDR_SIZE : integer := 4;  -- number of bits used for indexing the
            FILE_PATH : string
        );
        port (
            Clk : in std_logic;
            Rst : in std_logic;
            -- inputs
            PC_1   : in std_logic_vector(31 downto 0); -- ID stage PC (for prediction)
            PC_2   : in std_logic_vector(31 downto 0); -- EX stage PC  (for update)
            Taken  : in std_logic;                     -- actual branch outcome from EX stage
            Update : in std_logic;                     -- update prediction 
            -- outputs
            Prediction_1 : out std_logic; -- predicted branch outcome 
            Prediction_2 : out std_logic -- predicted branch outcome 
        );
    end component;

    -- Inputs
    signal Clk    : std_logic                     := '0';
    signal Rst    : std_logic                     := '0';
    signal PC_1   : std_logic_vector(31 downto 0) := (others => '0');
    signal PC_2   : std_logic_vector(31 downto 0) := (others => '0');
    signal Taken  : std_logic                     := '0';
    signal Update : std_logic                     := '0';

    -- Clock period definition
    constant Clk_period : time := 10 ns;

    -- Outputs
    signal Prediction_1 : std_logic;
    signal Prediction_2 : std_logic;
begin

    UUT : BHT
    generic map(
        BHT_SIZE  => 16,
        ADDR_SIZE => 4,
        FILE_PATH => "bht.mem"
    )
    port map(
        Clk          => Clk,
        Rst          => Rst,
        PC_1         => PC_1,
        PC_2         => PC_2,
        Taken        => Taken,
        Update       => Update,
        Prediction_1 => Prediction_1,
        Prediction_2 => Prediction_2
    );

    Clk_process : process
    begin
        Clk <= '0';
        wait for Clk_period / 2;
        Clk <= '1';
        wait for Clk_period / 2;
    end process;


    TESTPROC : process
    begin
        Rst <= '1';
        wait for Clk_period;
        wait for 3 ns;
        Rst <= '0';

        -- Test Case 1: Predict not taken, actual not taken
        PC_1 <= x"00000000"; -- 0: 01
        wait for Clk_period;
        assert (Prediction_1 = '0')
        report "Test Case 1 Failed: Should be not taken";
        PC_2 <= x"00000000"; -- 0: 01
        Update       <= '1';
        Taken    <= '0'; -- not taken -- 01 -> 00
        wait for Clk_period;
        Update <= '0';
        assert (Prediction_2 = '0')
        report "Test Case 1 Failed: Should be not taken";

        -- Test Case 2: Predict not taken, actual taken
        PC_1 <= x"00000001"; -- 1: 01
        wait for Clk_period;
        assert (Prediction_1 = '0')
        report "Test Case 2 Failed: Should be not taken";
        PC_2 <= x"00000001"; -- 1: 01 
        Taken    <= '1'; -- not taken -- 01 -> 10
        Update       <= '1';  
        wait for Clk_period;
        Update <= '0';
        assert (Prediction_2 = '1')
        report "Test Case 2 Failed: Should be taken";

        -- Test Case 3: Predict taken, actual taken
        PC_1 <= x"000000F1"; -- 1: 10
        wait for Clk_period;
        assert (Prediction_1 = '1')
        report "Test Case 3 Failed: Should be taken";
        PC_2 <= x"000000F1"; -- 1: 10
        Taken    <= '1'; -- taken -- 10 -> 11
        Update       <= '1';  
        wait for Clk_period;
        Update <= '0';
        assert (Prediction_2 = '1')
        report "Test Case 3 Failed: Should be taken";

        -- Test Case 4: Predict taken, actual not taken
        PC_1 <= x"00000001"; -- 1: 11
        wait for Clk_period;
        assert (Prediction_1 = '1')
        report "Test Case 4 Failed: Should be taken";
        PC_2 <= x"000045F1"; -- 1: 11
        Taken    <= '0'; -- taken -- 11 -> 10
        Update       <= '1';  
        wait for Clk_period;
        Update <= '0';
        assert (Prediction_2 = '1')
        report "Test Case 4 Failed: Should be still taken";

        -- Test Case 5
        PC_1 <= x"0000000F"; -- 15: 01
        wait for Clk_period;
        assert (Prediction_1 = '0')
        report "Test Case 5 Failed: Should be not taken";
        PC_2 <= x"0000000F"; -- 15: 01
        Taken    <= '1'; -- taken -- 01 -> 10
        Update       <= '1';  
        wait for Clk_period;
        Update <= '0';
        assert (Prediction_2 = '1')
        report "Test Case 5 Failed: Should be taken";
        wait for Clk_period;
        PC_1 <= x"00000000"; -- 0: 00
        Update       <= '1';    -- 10 -> 11
        wait for Clk_period;
        assert (Prediction_1 = '0')
        report "Test Case 5 Failed: Should be not taken";
        wait for Clk_period;
        assert (Prediction_2 = '1')
        report "Test Case 5 Failed: Should be taken";
        Update <= '0';


        -- End simulation
        wait;
    end process;

end BEHAVIORAL;