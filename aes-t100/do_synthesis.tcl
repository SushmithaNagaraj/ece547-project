### Setup library paths ###

set link_library "../NangateOpenCellLibrary/Front_End/Liberty/CCS/NangateOpenCellLibrary.db"
set target_library "../NangateOpenCellLibrary/Front_End/Liberty/CCS/NangateOpenCellLibrary.db"
set symbol_library "/usr/synopsys/syn/libraries/syn/generic.sdb"
set synthetic_library "/usr/synopsys/syn/libraries/syn/dw_foundation.sldb"

set SOURCE_DIR "./src/TjIn"

## clear and remake working directory
sh rm -r work
sh mkdir work

## set working directory and put the temp files there
define_design_lib work -path work

## analyze all source files for aes module
analyze -format verilog -lib work "$SOURCE_DIR/round.v"
analyze -format verilog -lib work "$SOURCE_DIR/lfsr.v"
analyze -format verilog -lib work "$SOURCE_DIR/table.v"
analyze -format verilog -lib work "$SOURCE_DIR/aes_128.v"
analyze -format verilog -lib work "$SOURCE_DIR/TSC.v"
analyze -format verilog -lib work "$SOURCE_DIR/top.v"

## elaborate the top level module
elaborate top

## link to target library
link

## flatten hierarchy
uniquify

## no area constraints for compilation
max_area 0

## clock creation
create_clock clk -period 10 -waveform {0 5.0}

## compile design to target library (OpenPDK45)
compile

## write out gate level netlist
write -hierarchy -f verilog -o aes_netlist.v

## report port counts
report_port

quit
