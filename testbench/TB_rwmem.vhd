library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RWMEM_TB is
end RWMEM_TB;

architecture TB_ARCH of RWMEM_TB is

component RWMEM is
	generic(
			FILE_PATH: string;
			FILE_PATH_INIT: string;
			D_MEM_DEPTH: natural := 128;
			DATA_DELAY: natural := 0
		);
	port (
			CLK   				: in std_logic;
			RST					: in std_logic;
			CTRL                : in std_logic_vector(1 downto 0);
			IS_SIGNED           : in std_logic;
			ADDR				: in std_logic_vector(31 downto 0);
			ENABLE				: in std_logic;
			READNOTWRITE		: in std_logic;
			DATA_READY			: out std_logic;
			IN_DATA: in std_logic_vector(31 downto 0);
			OUT_DATA: out std_logic_vector(31 downto 0)
		);
end component RWMEM;

constant DATA_SIZE: integer := 32;
constant CLK_PERIOD: time := 2ns;

signal clk_s, rst_s, enable_s, readnotwrite_s, data_ready_s, is_signed_s: std_logic;
signal addr_s, in_data_s, out_data_s: std_logic_vector(DATA_SIZE-1 downto 0);
signal ctrl_s: std_logic_vector(1 downto 0);

begin

DUT: RWMEM generic map(
        FILE_PATH => "data_mem.mem",
        FILE_PATH_INIT => "data_mem_init.mem",
        D_MEM_DEPTH => 128,
        DATA_DELAY => 0
)
port map(
    	CLK => clk_s,
        RST => rst_s,
        CTRL => ctrl_s,
        IS_SIGNED => is_signed_s,
        ADDR => addr_s,
        ENABLE => enable_s,
        READNOTWRITE => readnotwrite_s,
        DATA_READY => data_ready_s,
        IN_DATA => in_data_s,
        OUT_DATA => out_data_s
);

clk_process: process
begin
    clk_s <= '0';
    wait for CLK_PERIOD/2;
    clk_s <= '1';
    wait for CLK_PERIOD/2;
end process;

test_process: process
begin
    rst_s <= '0';
    addr_s <= (others => '0');
    enable_s <= '0';
    readnotwrite_s <= '0';
    in_data_s <= (others => '0');
    ctrl_s <= "00";
    is_signed_s <= '0';
    
    wait for 2 ns;
    
    --RESET
    rst_s <= '1';
    wait for CLK_PERIOD;
    
    rst_s <= '0';
    wait for CLK_PERIOD;
    
    enable_s <= '1';
    
    ctrl_s <= "00";
    --READ INIT VALUES
    for i in 0 to 15 loop
        readnotwrite_s <= '1';
        addr_s <= std_logic_vector(to_unsigned(i, addr_s'length));
        wait for CLK_PERIOD;
    end loop;
    
    ctrl_s <= "01";
    --READ INIT VALUES
    for i in 0 to 15 loop
        readnotwrite_s <= '1';
        addr_s <= std_logic_vector(to_unsigned(i, addr_s'length));
        wait for CLK_PERIOD;
    end loop;
    
    ctrl_s <= "10";
    --READ INIT VALUES
    for i in 0 to 15 loop
        readnotwrite_s <= '1';
        addr_s <= std_logic_vector(to_unsigned(i, addr_s'length));
        wait for CLK_PERIOD;
    end loop;
    
    ctrl_s <= "00";
    --WRITE
    for i in 0 to 31 loop
        readnotwrite_s <= '0';
        addr_s <= std_logic_vector(to_unsigned(i, addr_s'length));
        in_data_s <= std_logic_vector(to_unsigned(i*16, addr_s'length));
        wait for CLK_PERIOD;
    end loop;
    
    --UNSIGNED
    is_signed_s <= '0';
    
    ctrl_s <= "00";
    --READ BYTE
    for i in 0 to 31 loop
        readnotwrite_s <= '1';
        addr_s <= std_logic_vector(to_unsigned(i, addr_s'length));
        wait for CLK_PERIOD;
    end loop;
    
    ctrl_s <= "01";
    --READ HALF WORD
    for i in 0 to 31 loop
        readnotwrite_s <= '1';
        addr_s <= std_logic_vector(to_unsigned(i, addr_s'length));
        wait for CLK_PERIOD;
    end loop;
    
    ctrl_s <= "10";
    --READ WORD
    for i in 0 to 31 loop
        readnotwrite_s <= '1';
        addr_s <= std_logic_vector(to_unsigned(i, addr_s'length));
        wait for CLK_PERIOD;
    end loop;
    
    --SIGNED
    is_signed_s <= '1';
    
    ctrl_s <= "00";
    --READ BYTE
    for i in 0 to 31 loop
        readnotwrite_s <= '1';
        addr_s <= std_logic_vector(to_unsigned(i, addr_s'length));
        wait for CLK_PERIOD;
    end loop;
    
    ctrl_s <= "01";
    --READ HALF WORD
    for i in 0 to 31 loop
        readnotwrite_s <= '1';
        addr_s <= std_logic_vector(to_unsigned(i, addr_s'length));
        wait for CLK_PERIOD;
    end loop;
    
    ctrl_s <= "10";
    --READ WORD
    for i in 0 to 31 loop
        readnotwrite_s <= '1';
        addr_s <= std_logic_vector(to_unsigned(i, addr_s'length));
        wait for CLK_PERIOD;
    end loop;
    
    wait;
end process;

end TB_ARCH;
