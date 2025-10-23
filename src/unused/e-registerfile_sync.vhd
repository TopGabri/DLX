library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use WORK.all;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;

entity REGISTER_FILE is
    generic (
        NBIT_ADD  : integer := 5;
        NBIT_DATA : integer := 32;
        FILE_PATH : string
    );
    port (
        Clk     : in std_logic;
        reset   : in std_logic;
        enable  : in std_logic;
        rd1     : in std_logic;
        rd2     : in std_logic;
        wr      : in std_logic;
        add_wr  : in std_logic_vector(NBIT_ADD - 1 downto 0);
        add_rd1 : in std_logic_vector(NBIT_ADD - 1 downto 0);
        add_rd2 : in std_logic_vector(NBIT_ADD - 1 downto 0);
        datain  : in std_logic_vector(NBIT_DATA - 1 downto 0);
        out1    : out std_logic_vector(NBIT_DATA - 1 downto 0);
        out2    : out std_logic_vector(NBIT_DATA - 1 downto 0)
    );
end REGISTER_FILE;

architecture A of REGISTER_FILE is

    -- suggested structures
    subtype REG_ADDR is natural range 0 to (2 ** NBIT_ADD) - 1; -- using natural type
    type REG_ARRAY is array(REG_ADDR) of std_logic_vector(NBIT_DATA - 1 downto 0);
    signal REGISTERS : REG_ARRAY;

    procedure rewrite_regfile(data : in REG_ARRAY; path_file : string) is
        file wr_file       : text;
        variable line_in   : line;
        variable i, j      : integer;
        variable nibble    : std_logic_vector(3 downto 0);
        constant hex_chars : string := "0123456789ABCDEF";
        variable hex_str   : string(1 to 8);
    begin
        file_open(wr_file, path_file, WRITE_MODE);

        -- write header
        write(line_in, string'("reg   content"));
        writeline(wr_file, line_in);

        for i in 0 to 31 loop
            line_in := null;

            -- write register name
            write(line_in, string'("r" & integer'image(i)));
            if (i < 10) then
                write(line_in, string'("    "));
            else
                write(line_In, string'("   "));
            end if;

            -- convert each 4-bit nibble to hex
            for j in 0 to 7 loop
                nibble         := data(i)(31 - j * 4 downto 28 - j * 4);
                hex_str(j + 1) := hex_chars(to_integer(unsigned(nibble)) + 1);
            end loop;

            -- write hex content
            write(line_in, string'(hex_str));
            writeline(wr_file, line_in);
        end loop;

        file_close(wr_file);
    end procedure;

begin
    -- write your RF code 

    RF : process (Clk) -- all operations are synchronous

        variable add_wr_int  : REG_ADDR;
        variable add_rd1_int : REG_ADDR;
        variable add_rd2_int : REG_ADDR;

    begin
        -- asynchronous reset        
        if (reset = '1') then
            REGISTERS <= (others => (others => '0')); -- erase all registers
        elsif (enable = '1') then
            if (wr = '1' and falling_edge(Clk)) then -- write at rising edge
                add_wr_int := to_integer(unsigned(add_wr));
                REGISTERS(add_wr_int) <= datain;
            end if;

            -- read continuously
            if (rd1 = '1') then -- read 1
                add_rd1_int := to_integer(unsigned(add_rd1));
                out1 <= REGISTERS(add_rd1_int);
            end if;

            if (rd2 = '1') then -- read 2
                add_rd2_int := to_integer(unsigned(add_rd2));
                out2 <= REGISTERS(add_rd2_int);
            end if;
        end if;

    end process RF;

    rewrite_regfile(REGISTERS, FILE_PATH);

end A;

----
configuration CFG_RF_BEH of REGISTER_FILE is
    for A
    end for;
end configuration;