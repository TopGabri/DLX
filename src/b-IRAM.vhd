library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.DLX_types.all;


-- Instruction memory for DLX
-- Memory filled by a process which reads from a file
entity IRAM is
  generic (
    I_MEM_DEPTH : integer := 128;
    I_SIZE : integer := 32;
    FILE_PATH: string;
    FILE_PATH_INIT: string
    );
  port (
    Rst  : in  std_logic;
    Addr : in  std_logic_vector(I_SIZE - 1 downto 0);
    Dout : out std_logic_vector(I_SIZE - 1 downto 0)
    );
end IRAM;

architecture BEHAVIORAL of IRAM is

  type IRAM is array (0 to I_MEM_DEPTH - 1) of std_logic_vector(I_SIZE - 1 downto 0);
  signal IM : IRAM;
  
  procedure rewrite_content(data: in IRAM; path_file: string) is
          variable index   : natural range 0 to I_MEM_DEPTH;
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
      
          for index in 0 to I_MEM_DEPTH-1 loop
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

begin  -- IRam_Bhe

  Dout <= IM(to_integer(unsigned(Addr)/4)) when (Rst = '0' and to_integer(unsigned(Addr)/4) < I_MEM_DEPTH)
           else (others => '0');

  -- purpose: This process is in charge of filling the Instruction RAM with the firmware
  -- type   : combinational
  -- inputs : Rst
  -- outputs: IRAM_mem
  FILL_MEM_P: process (Rst)
    file mem_fp: text;
    variable file_line : line;
    variable index : integer := 0;
    variable tmp_data_u : std_logic_vector(I_SIZE-1 downto 0);
  begin  -- process FILL_MEM_P
    if (Rst = '1') then
      file_open(mem_fp,FILE_PATH_INIT,READ_MODE);
      while (not endfile(mem_fp)) loop
        readline(mem_fp,file_line);
        hread(file_line,tmp_data_u);
        IM(index) <= tmp_data_u;       
        index := index + 1;
      end loop;

      for i in index to I_MEM_DEPTH-1 loop
        IM(i) <= (others => '0');  -- fill the rest of the instruction memory with NOP
      end loop;
    end if;
  end process FILL_MEM_P;
  
  --rewrite_content(IM, FILE_PATH);  -- write the content of the instruction IRAM inside a file 

end BEHAVIORAL;
