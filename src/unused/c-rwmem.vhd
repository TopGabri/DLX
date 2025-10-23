library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity RWMEM is
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
end RWMEM;

architecture BEHAVIORAL of RWMEM is
	type DRAM is array (0 to D_MEM_DEPTH - 1) of std_logic_vector(7 downto 0); --memory is an array of bytes
	signal DM : DRAM;
	signal int_data_ready,mem_ready: std_logic;
	signal counter: natural:=0;
    
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
    
            addr := addr + 1;
        end loop;
    
        file_close(wr_file);
    end procedure;


    
    
begin  


	--write_process
	WR_PROCESS:
	process (CLK, RST, READNOTWRITE, ADDR)
		file mem_fp: text;
		variable index: integer range 0 to D_MEM_DEPTH-1;
		variable file_line : line;
		variable tmp_data_u : std_logic_vector(31 downto 0);
		variable aligned_addr: std_logic_vector(31 downto 0);
		variable unsigned_data: std_logic_vector(31 downto 0);
	begin  -- process
		if RST = '1' then  	 -- asynchronous reset (active low)
--			while index < D_MEM_DEPTH loop
--				DDRAM_mem(index) <= std_logic_vector(to_unsigned(index,DATA_SIZE));
--				index := index + 1;
--			end loop;

			file_open(
				mem_fp,
				FILE_PATH_INIT,
				READ_MODE
			);
            
            index:=0;
			while (not endfile(mem_fp)) loop	--read file line by line and write content inside DDRAM_mem
				readline(mem_fp,file_line);
				hread(file_line,tmp_data_u);
				DM(index) <= tmp_data_u(31 downto 24);
                DM(index+1) <= tmp_data_u(23 downto 16);
                DM(index+2) <= tmp_data_u(15 downto 8);
                DM(index+3) <= tmp_data_u(7 downto 0);
				index := index + 4;
			end loop;

			file_close(mem_fp);

			int_data_ready <= '0';
			mem_ready <= '0';
			
		elsif(ENABLE = '1') then
			counter <= counter + 1;
			if (counter = DATA_DELAY) then
				counter <= 0;
				if (to_integer(unsigned(ADDR)) >= 0 and to_integer(unsigned(ADDR)) < D_MEM_DEPTH) then    --do not read nor write if ADDR is out of bounds
                    if (READNOTWRITE = '0' and falling_edge(CLK)) then	
                        -- WRITE  (only in the middle of the Clk cycle to avoid unexpected errors)
                        case to_integer(unsigned(CTRL)) is
                            when 0 =>    --1 byte
                                aligned_addr := ADDR;
                                DM(to_integer(unsigned(aligned_addr))) <= IN_DATA(7 downto 0);
                            when 1 =>    --2 bytes (HALF WORD)
                                aligned_addr := ADDR(31 downto 1) & '0';    -- address multiple of 2
                                DM(to_integer(unsigned(aligned_addr))) <= IN_DATA(15 downto 8);
                                DM(to_integer(unsigned(aligned_addr))+1) <= IN_DATA(7 downto 0);
                            when others =>  --4 bytes (WORD)    
                                aligned_addr := ADDR(31 downto 2) & "00";   -- address multiple of 4
                                DM(to_integer(unsigned(aligned_addr))) <= IN_DATA(31 downto 24);
                                DM(to_integer(unsigned(aligned_addr))+1) <= IN_DATA(23 downto 16);
                                DM(to_integer(unsigned(aligned_addr))+2) <= IN_DATA(15 downto 8);
                                DM(to_integer(unsigned(aligned_addr))+3) <= IN_DATA(7 downto 0);
                        end case;
                        mem_ready <= '1';
                    elsif (READNOTWRITE = '1') then
                        -- READ
                        case to_integer(unsigned(CTRL)) is
                            when 0 =>    --1 byte
                                aligned_addr := ADDR;
                                unsigned_data := (31 downto 8 => '0') & 
                                        DM(to_integer(unsigned(aligned_addr)));
                                if(IS_SIGNED = '1') then
                                    OUT_DATA <= (31 downto 8 => unsigned_data(7)) & 
                                        unsigned_data(7 downto 0);
                                else
                                    OUT_DATA <= unsigned_data;
                                end if;
                            when 1 =>    --2 bytes (HALF WORD)
                                aligned_addr := ADDR(31 downto 1) & '0';    -- address multiple of 2
                                unsigned_data := (31 downto 16 => '0') &
                                    DM(to_integer(unsigned(aligned_addr))) &
                                    DM(to_integer(unsigned(aligned_addr))+1);
                                if(IS_SIGNED = '1') then
                                    OUT_DATA <= (31 downto 16 => unsigned_data(15)) & 
                                        unsigned_data(15 downto 0);
                                else
                                    OUT_DATA <= unsigned_data;
                                end if;
                            when others =>  --4 bytes (WORD)    
                                aligned_addr := ADDR(31 downto 2) & "00";   -- address multiple of 4
                                OUT_DATA <= DM(to_integer(unsigned(aligned_addr))) &
                                    DM(to_integer(unsigned(aligned_addr))+1) &
                                    DM(to_integer(unsigned(aligned_addr))+2) &
                                    DM(to_integer(unsigned(aligned_addr))+3);
                        end case;
                        int_data_ready <= '1';    
                    end if;
                end if;
			else
				mem_ready <= '0';
				int_data_ready <= '0';
			end if;
		else
			counter <= 0;
		end if;
	end process;
	
	
    rewrite_content(DM,FILE_PATH);
	data_ready <= int_data_ready or mem_ready;--delay add

end BEHAVIORAL;
