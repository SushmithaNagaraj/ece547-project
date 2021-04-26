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


### Add test structures (scan cells)
set test_default_scan_style multiplexed_flip_flop
set_scan_configuration -chain_count 1
create_test_protocol -infer_async -infer_clock

## check design constraints
dft_drc

## compile design to target library (OpenPDK45)
compile -scan

# connects all scan-enabled ff's together into scan-chain
# note, it creates two new ports: test_si & test_se
preview_dft
insert_dft

# Report stuff
report_port
dft_drc -coverage_estimate

# write out test protocol (also needed by tetramax)
write_test_protocol -output aes_test_protocol.spf

## write out gate level netlist
write -hierarchy -f verilog -o aes_netlist.v

quit
