library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use WORK.DLX_Types.all;

entity DATA_CACHE is
generic (
    FILE_PATH: string;
    MEMORY_ACCESS_CYCLES: integer := 0;    
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
end DATA_CACHE;

architecture BEHAVIOURAL of DATA_CACHE is

type CACHELINE is array (0 to (2**W)-1) of std_logic_vector(DATA_WIDTH-1 downto 0); 
type CACHEMEMORY is array (0 to (2**R)-1) of CACHELINE;
type CACHETAGS is array (0 to (2**R)-1) of std_logic_vector(K-R-W-1 downto 0);
type CACHEDIRTYBITS is array (0 to (2**R)-1) of std_logic;

type StateType is (NormalOp, WriteToMemory, ReadFromMemory);
signal currState, nextState: StateType;
signal counter, nextCounter: unsigned(W-1 downto 0);
signal memoryDelayCounter, nextMemoryDelayCounter: integer;
signal savedAddress: std_logic_vector(ADDR_WIDTH-1 downto 0);
signal wordBuffer: std_logic_vector(DATA_WIDTH-1 downto 0);

signal dc: CACHEMEMORY;
signal tags: CACHETAGS;
signal dirty_bits: CACHEDIRTYBITS;
signal reset_bits: CACHEDIRTYBITS;

procedure rewrite_content(data: in CACHEMEMORY; path_file: string) is
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
    
        for index in 0 to 2**R-1 loop
            line_in := null;
    
            -- write content
            hwrite(line_in, tags(index));
            for word in 0 to 2**W-1 loop
                write(line_in, string'("     "));  -- separator
                hwrite(line_in, dc(index)(word));
            end loop;
            write(line_in, string'("     "));  -- separator
            if (dirty_bits(index) = '1') then
                write(line_in, string'("    dirty"));
            end if;   
            writeline(wr_file, line_in);
    
        end loop;
    
        file_close(wr_file);
    end procedure;

begin

stateProcess: process(clk, rst)
begin
    if(rst = '1') then
        currState <= NormalOp;
        counter <= (others => '0');
        memoryDelayCounter <= 0;
    elsif(rising_edge(clk)) then
        currState <= nextState;
        counter <= nextCounter;
        memoryDelayCounter <= nextMemoryDelayCounter;
    end if;
end process;

combLogic: process(clk, rst, addr, data_in, RnW, currState, counter)
    -- addr = tag & line_index & word_offset
    -- tag: (K-R-W-1 downto 0)
    -- line_index: (R-1 downto 0)
    -- word_offset: (W-1 downto 0)
    
    variable tag, old_tag, new_tag: std_logic_vector(K-R-W-1 downto 0);
    variable line_index, word_offset, byte_index, half_word_index: integer;
    variable aligned_addr: std_logic_vector(ADDR_WIDTH-1 downto 0);
    variable unsigned_data: std_logic_vector(DATA_WIDTH-1 downto 0);
begin

    -- default behaviour
    nextState <= currState;
    nextCounter <= counter;
    nextMemoryDelayCounter <= memoryDelayCounter;
    miss <= '0';
    enable_memory <= '0';
    RnW_memory <= '1';
    addr_to_memory <= (others => '0');
    data_out_to_memory <= (others => '0');
    -- data_out does not have a default behaviour => it is a buffer
    if(rst = '1') then
        dc <= (others => (others => (others => '0')));
        tags <= (others => (others => '0'));
        dirty_bits <= (others => '0');
        reset_bits <= (others => '1');
    else
        case currState is
            when NormalOp =>
                tag := addr(K+1 downto W+R+2);
                line_index := to_integer( unsigned(addr(W+R+1 downto W+2) ) );
                word_offset := to_integer( unsigned(addr(W+1 downto 2) ) );
                byte_index := to_integer(unsigned(addr(1 downto 0)));
                half_word_index := to_integer(unsigned(addr(1 downto 1)));
                
--                report_slv("Tag", tag);
--                report_slv("Word offset", addr(W+1 downto 2));
--                report_slv("Line index", addr(W+R+1 downto W+2));
--                report_slv("Cache tag", tags(line_index));
                
                if (enable = '1') then
                    if( tag = tags(line_index) and reset_bits(line_index) = '0' ) then
                        -- hit
                        if(RnW = '1') then
                            -- read
                            case to_integer(unsigned(ctrl)) is
                                when 0 =>    --1 byte
                                    unsigned_data := (31 downto 8 => '0') & 
                                            DC(line_index)(word_offset)(8*byte_index+7 downto 8*byte_index);
                                    if(is_signed = '1') then
                                        data_out <= (31 downto 8 => unsigned_data(7)) & 
                                            unsigned_data(7 downto 0);
                                    else
                                        data_out <= unsigned_data;
                                    end if;
                                when 1 =>    --2 bytes (HALF WORD)
                                    unsigned_data := (31 downto 16 => '0') &
                                        DC(line_index)(word_offset)(16*half_word_index+15 downto 16*half_word_index);
                                    if(is_signed = '1') then
                                        data_out <= (31 downto 16 => unsigned_data(15)) & 
                                            unsigned_data(15 downto 0);
                                    else
                                        data_out <= unsigned_data;
                                    end if;
                                when others =>  --4 bytes (WORD)    
                                    data_out <= DC(line_index)(word_offset);
                            end case;
                        else
                            -- write

                            if(falling_edge(clk)) then
                                dirty_bits(line_index) <= '1';
                         
                                case to_integer(unsigned(ctrl)) is
                                    when 0 =>    --1 byte
                                        DC(line_index)(word_offset)(8*byte_index+7 downto 8*byte_index) <= data_in(7 downto 0);
                                    when 1 =>    --2 bytes (HALF WORD)
                                        DC(line_index)(word_offset)(16*half_word_index+15 downto 16*half_word_index) <= data_in(15 downto 0);
                                    when others =>  --4 bytes (WORD)    
                                        DC(line_index)(word_offset) <= data_in;
                                end case;
                                -- report_slv("Data written:", dc(line_index)(word_offset));
                            end if;
                        end if;                  
                    else
                        -- miss
                        
                        -- check if miss, far from the clock rising edges
                        if(falling_edge(clk)) then
                            nextCounter <= (others => '0');
                            nextMemoryDelayCounter <= 0;
                            savedAddress <= addr;
                            miss <= '1';
                            
                            if(dirty_bits(line_index) = '1') then
                                nextState <= WriteToMemory;     -- write-back policy
                            else
                                nextState <= ReadFromMemory;
                            end if;
                        end if;
                    end if;
                end if;
                
            when WriteToMemory =>
                line_index := to_integer( unsigned(savedAddress(W+R+1 downto W+2) ) );
                old_tag := tags(line_index);
                RnW_memory <= '0';
                miss <= '1';
                enable_memory <= '1';
                
                nextMemoryDelayCounter <= memoryDelayCounter + 1;
                if (memoryDelayCounter = MEMORY_ACCESS_CYCLES) then
                    nextCounter <= counter + 1;
                    nextMemoryDelayCounter <= 0;
                    
                    if (counter = 2**W-1) then
                        nextCounter <= (others => '0');
                        nextState <= ReadFromMemory;
                        dirty_bits(line_index) <= '0';
                    end if;
                end if;
                
                -- addr_to_memory = old_tag & line_index & word offset & 00
                addr_to_memory <= (ADDR_WIDTH-1 downto K+2 => '0') & std_logic_vector(old_tag) & addr(W+R+1 downto W+2) & std_logic_vector(counter) & "00";
                data_out_to_memory <= dc(line_index)(to_integer(counter));
                
                
                
            when ReadFromMemory =>
                new_tag := savedAddress(K+1 downto W+R+2);
                line_index := to_integer( unsigned(savedAddress(W+R+1 downto W+2) ) );
                RnW_memory <= '1';
                miss <= '1';
                enable_memory <= '1';
                
                nextMemoryDelayCounter <= memoryDelayCounter + 1;
                if (memoryDelayCounter = MEMORY_ACCESS_CYCLES) then
                    nextCounter <= counter + 1;
                    nextMemoryDelayCounter <= 0;
                    
                    if (counter = 2**W-1) then
                        tags(line_index) <= new_tag;
                        nextState <= NormalOp;
                        reset_bits(line_index) <= '0';
                    end if;    
                end if;
                
                addr_to_memory <= savedAddress(DATA_WIDTH-1 downto W+2) & std_logic_vector(counter) & "00";
                if(falling_edge(clk)) then
                    dc(line_index)(to_integer(counter)) <= data_in_from_memory;
                end if; 
        end case;
    end if;
    
    rewrite_content(dc, FILE_PATH);
    
end process;

-- debug
state_p <= "00" when currState = NormalOp else
           "01" when currState = WriteToMemory else
           "10";

nextState_p <= "00" when nextState = NormalOp else
                "01" when nextState = WriteToMemory else
                "10";


end BEHAVIOURAL;


