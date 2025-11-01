library IEEE;
use IEEE.std_logic_1164.all;
use WORK.DLX_Types.all;

entity DATA_CACHE_TB is
end DATA_CACHE_TB;

architecture TB_ARCH of DATA_CACHE_TB is

component DATA_CACHE is
    generic (
        FILE_PATH: string := "cache.mem"; 
        MEMORY_ACCESS_CYCLES: integer := 1;
        K: integer;         -- log2 MAINSIZE (#words in memory)
        R: integer;         -- log2 NLINES (#lines in the cache)
        W: integer          -- log2 LINESIZE (#words in a cache line)
    );
    port (
        clk, rst: in std_logic;
        enable: in std_logic;
        ctrl: in std_logic_vector(1 downto 0);
        is_signed: in std_logic;
        addr: in std_logic_vector(ADDR_WIDTH-1 downto 0);
        data_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out: out std_logic_vector(DATA_WIDTH-1 downto 0);
        RnW: in std_logic;
        addr_to_memory: out std_logic_vector(ADDR_WIDTH-1 downto 0);
        data_in_from_memory: in std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_to_memory: out std_logic_vector(DATA_WIDTH-1 downto 0);
        RnW_memory: out std_logic;
        miss: out std_logic;
        enable_memory: out std_logic;
        --debug signals
        state_p, nextState_p: out std_logic_vector(1 downto 0)
    );
end component DATA_CACHE;

component DATA_MEMORY is
	generic(
			FILE_PATH: string;
			FILE_PATH_INIT: string;
			D_MEM_DEPTH: natural := 128;
			DATA_DELAY: natural := 0
		);
	port (
			CLK   				: in std_logic;
			RST					: in std_logic;
			ADDR				: in std_logic_vector(31 downto 0);
			ENABLE				: in std_logic;
			READNOTWRITE		: in std_logic;
			DATA_READY			: out std_logic;
			IN_DATA: in std_logic_vector(31 downto 0);
			OUT_DATA: out std_logic_vector(31 downto 0)
		);
end component DATA_MEMORY;

signal clk_s, rst_s: std_logic;
signal addr_s, addr_to_memory_s: std_logic_vector(ADDR_WIDTH-1 downto 0);
signal data_in_s, data_out_s, data_in_from_memory_s, data_out_to_memory_s: std_logic_vector(DATA_WIDTH-1 downto 0);
signal RnW_s, RnW_memory_s, data_ready_s, miss_s, enable_s: std_logic;
signal state_s, nextState_s: std_logic_vector(1 downto 0);

constant ClkPeriod: time := 4ns;

begin

-- addr = tag & line & offset & alignment
-- addr = 1010 & 10 & 01 & 00   -> 2^8 words in memory, 2^2 cache lines, 2^2 words in cache line
cache: DATA_CACHE generic map(MEMORY_ACCESS_CYCLES => 4, K => 8, R => 2, W => 2)
    port map(
        clk => clk_s,
        rst => rst_s,
        enable => '1',
        ctrl => "11",
        is_signed => '0',
        addr => addr_s,
        data_in => data_in_s,
        data_out => data_out_s,
        RnW => RnW_s,
        addr_to_memory => addr_to_memory_s,
        data_in_from_memory => data_in_from_memory_s,
        data_out_to_memory => data_out_to_memory_s,
        RnW_memory => RnW_memory_s,
        miss => miss_s,
        enable_memory => enable_s,
        state_p => state_s,
        nextState_p => nextState_s
    );
memory: DATA_MEMORY generic map(
            FILE_PATH => "data_mem.mem",
			FILE_PATH_INIT => "data_mem_init.mem",
			D_MEM_DEPTH => 256,
			DATA_DELAY => 4
		)
	port map(
			CLK => clk_s,
			RST => rst_s,
			ADDR => addr_to_memory_s,
			ENABLE => enable_s,
			READNOTWRITE => RnW_memory_s,
			DATA_READY => data_ready_s,
			IN_DATA => data_out_to_memory_s,
			OUT_DATA => data_in_from_memory_s
		);

clkProcess: process
begin
    clk_s <= '1';
    wait for ClkPeriod/2;
    clk_s <= '0';
    wait for ClkPeriod/2;
end process;

tbProcess: process
begin
    rst_s <= '1';
    wait for ClkPeriod;
    rst_s <= '0';
    
    RnW_s <= '0'; -- writing
    addr_s <= (31 downto 10 => '0') & "0000" & "00" & "00" & "00";
    data_in_s <= X"00000001";
    wait for ClkPeriod;
    addr_s <= (31 downto 10 => '0') & "0000" & "00" & "01" & "00";
    data_in_s <= X"00001234";
    wait for ClkPeriod;
    addr_s <= (31 downto 10 => '0') & "0000" & "01" & "00" & "11";
    data_in_s <= X"00005678";
    wait for ClkPeriod;
    
    RnW_s <= '1'; -- reading
    addr_s <= (31 downto 10 => '0') & "0001" & "00" & "00" & "00";
    wait for 3*ClkPeriod;
    
    wait;
end process;

end TB_ARCH;