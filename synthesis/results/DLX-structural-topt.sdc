###################################################################

# Created by write_sdc on Tue Nov 11 16:06:49 2025

###################################################################
set sdc_version 2.1

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current mA
create_clock [get_ports Clk]  -name CLK  -period 2  -waveform {0 1}
