library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity DATA_MEMORY is
	generic(
			FILE_PATH: string;
			FILE_PATH_INIT: string;
			D_MEM_DEPTH: natural := 128; -- #words in memory
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
end DATA_MEMORY;

architecture BEHAVIORAL of DATA_MEMORY is
	type DRAM is array (0 to D_MEM_DEPTH - 1) of std_logic_vector(31 downto 0);
	signal DM : DRAM;
	signal int_data_ready,mem_ready: std_logic;
	signal counter, nextCounter: natural:=0;
    
	procedure rewrite_content(data: in DRAM; path_file: string) is
        variable index   : natural range 0 to D_MEM_DEPTH;
        file wr_file     : text;
        variable line_in : line;
        variable addr    : integer := 0;
    
        -- function to convert integer to 8-digit hex string
        function to_hex8(val: integer) return string is
            constant hex_chars : string := "0123456789ABCDEF";
            variable result    : string(1 to 8);
            variable v         : integer := val;
        begin
            for i in 8 downto 1 loop
                result(i) := hex_chars((v mod 16) + 1);
                v := v / 16;
            end loop;
            return result;
        end function;
    begin
        file_open(wr_file, path_file, WRITE_MODE);
    
        -- write header
        write(line_in, string'("address        content"));
        writeline(wr_file, line_in);
    
        for index in 0 to D_MEM_DEPTH-1 loop
            line_in := null;
    
            -- write address in hex with 0x prefix
            write(line_in, string'("0x" & to_hex8(addr)));
            write(line_in, string'("     "));  -- separator
    
            -- write content
            hwrite(line_in, data(index));
    
            writeline(wr_file, line_in);
    
            addr := addr + 4;
        end loop;
    
        file_close(wr_file);
    end procedure;


    
    
begin  
    
    COUNTER_UPDATE:
    process(CLK, RST, READNOTWRITE, ADDR, IN_DATA, ENABLE)
    begin
        if (RST = '1') then
            counter <= 0;
        elsif (rising_edge(CLK)) then
            counter <= nextCounter;
        end if;
    end process;
    
	--write_process
	WR_PROCESS:
	process (CLK, RST, READNOTWRITE, ADDR, counter)
		file mem_fp: text;
		variable index: integer range 0 to D_MEM_DEPTH-1;
		variable file_line : line;
		variable tmp_data_u : std_logic_vector(31 downto 0);
		variable word_addr: std_logic_vector(29 downto 0);
		variable unsigned_data: std_logic_vector(31 downto 0);
	begin  -- process
	   if RST = '1' then
	        -- default = set everything to zero
	        DM <= (others => (others => '0'));
	        
            index := 0;
            file_open(mem_fp,FILE_PATH_INIT,READ_MODE);
            while (not endfile(mem_fp)) loop
                readline(mem_fp,file_line);
                hread(file_line,tmp_data_u);
                DM(index/4) <= tmp_data_u;       
                index := index + 4;
            end loop;
            file_close(mem_fp);
	   elsif(ENABLE = '1') then
		    word_addr := ADDR(31 downto 2);
		      
			nextCounter <= counter + 1;
			if (counter = DATA_DELAY) then
				nextCounter <= 0;
				if (to_integer(unsigned(ADDR)) >= 0 and to_integer(unsigned(ADDR)) < D_MEM_DEPTH) then    --do not read nor write if ADDR is out of bounds
                    if (READNOTWRITE = '0' and falling_edge(CLK)) then	
                        -- WRITE  (only in the middle of the Clk cycle to avoid unexpected errors)
                        DM(to_integer(unsigned(word_addr))) <= IN_DATA;
                        mem_ready <= '1';
                    elsif (READNOTWRITE = '1') then
                        -- READ 
                        OUT_DATA <= DM(to_integer(unsigned(word_addr)));
                        int_data_ready <= '1';    
                    end if;
                end if;
			else
				mem_ready <= '0';
				int_data_ready <= '0';
			end if;
		else
			nextCounter <= 0;
		end if;
	end process;
	
	
    rewrite_content(DM,FILE_PATH);
    
	data_ready <= int_data_ready or mem_ready;     --delay add

end BEHAVIORAL;
