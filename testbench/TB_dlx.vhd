library IEEE;
use IEEE.std_logic_1164.all;
use WORK.DLX_Types.all;

entity DLX_TB is
end DLX_TB;

architecture TBARCH of DLX_TB is

    component DLX is
		port (
			-- # Clock and Reset Signals
			Clk : in std_logic;
			Rst : in std_logic;
			-- # Instruction Memory Interface
			PC_OUT        : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
			INSTR_MEM_OUT : in std_logic_vector(INSTRUCTION_WIDTH - 1 downto 0);
			-- # Data Memory Interface
			ADDR_TO_DM : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
			ENABLE_DM  : out std_logic;
			RnW_DM     : out std_logic;
			DATA_TO_DM : out std_logic_vector(DATA_WIDTH - 1 downto 0);
			DATA_FROM_DM : in std_logic_vector(DATA_WIDTH - 1 downto 0)
		);
    end component DLX;

    component IRAM is
        generic (
            I_MEM_DEPTH    : integer := 128;
            I_SIZE         : integer := 32;
            FILE_PATH      : string;
            FILE_PATH_INIT : string
        );
        port (
            Rst  : in std_logic;
            Addr : in std_logic_vector(I_SIZE - 1 downto 0);
            Dout : out std_logic_vector(I_SIZE - 1 downto 0)
        );
    end component;

    component DATA_MEMORY is
        generic (
            FILE_PATH      : string;
            FILE_PATH_INIT : string;
            D_MEM_DEPTH    : natural := 128; -- #words in memory
            DATA_DELAY     : natural := 0
        );
        port (
            CLK          : in std_logic;
            RST          : in std_logic;
            ADDR         : in std_logic_vector(31 downto 0);
            ENABLE       : in std_logic;
            READNOTWRITE : in std_logic;
            DATA_READY   : out std_logic;
            IN_DATA      : in std_logic_vector(31 downto 0);
            OUT_DATA     : out std_logic_vector(31 downto 0)
        );
    end component;

    constant Clkperiod   : time := 10 ns;
    signal Clk, Rst      : std_logic;
    signal PC_OUT        : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal INSTR_MEM_OUT : std_logic_vector(INSTRUCTION_WIDTH - 1 downto 0);
    signal ADDR_TO_DM    : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal ENABLE_DM     : std_logic;
    signal RnW_DM        : std_logic;
    signal DATA_TO_DM    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal DATA_FROM_DM  : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin

    UUT : DLX port map(
        Clk           => Clk,
        Rst           => Rst,
        PC_OUT        => PC_OUT,
        INSTR_MEM_OUT => INSTR_MEM_OUT,
		ADDR_TO_DM    => ADDR_TO_DM,
		ENABLE_DM     => ENABLE_DM,
		RnW_DM        => RnW_DM,
		DATA_TO_DM    => DATA_TO_DM,
		DATA_FROM_DM  => DATA_FROM_DM
    );

    IM : IRAM generic map(
        I_MEM_DEPTH    => I_MEM_DEPTH,
        I_SIZE         => INSTRUCTION_WIDTH,
        FILE_PATH      => "./memory_files/instr_mem.mem",
        FILE_PATH_INIT => "./memory_files/instr_mem_init.mem"
    )
    port map(
        Rst  => Rst,
        Addr => PC_OUT,
        Dout => INSTR_MEM_OUT
    );

    -- DATA_MEMORY    
    DM : DATA_MEMORY generic map(
        FILE_PATH      => "./memory_files/data_mem.mem",
        FILE_PATH_INIT => "./memory_files/data_mem_init.mem",
        D_MEM_DEPTH    => D_MEM_DEPTH,
        DATA_DELAY     => DATA_DELAY
    )
    port map(
        CLK          => clk,
        RST          => Rst,
        ADDR         => ADDR_TO_DM,
        ENABLE       => ENABLE_DM,
        READNOTWRITE => RnW_DM,
        IN_DATA      => DATA_TO_DM,
        OUT_DATA     => DATA_FROM_DM
    );
    
    clock_process : process
    begin
        clk <= '0';
        wait for Clkperiod/2;
        clk <= '1';
        wait for Clkperiod/2;
    end process;

    tb_process : process
    begin

        Rst <= '1';
        wait for Clkperiod;
        wait for 1 ns;
        Rst <= '0';

        wait;
    end process;

end TBARCH;