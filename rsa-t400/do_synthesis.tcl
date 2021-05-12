### Design Compilation Script for RSA-T400

### Setup library paths ###

set link_library "../NangateOpenCellLibrary/Front_End/Liberty/CCS/NangateOpenCellLibrary.db"
set target_library "../NangateOpenCellLibrary/Front_End/Liberty/CCS/NangateOpenCellLibrary.db"
set symbol_library "/usr/synopsys/syn/libraries/syn/generic.sdb"
set synthetic_library "/usr/synopsys/syn/libraries/syn/dw_foundation.sldb"

set SOURCE_DIR "./src"

## analyze all source files for rsa module

analyze -format vhdl -library work "$SOURCE_DIR/modmult.vhd"
analyze -format vhdl -library work  "$SOURCE_DIR/rsacypher.vhd"
analyze -format vhdl -library work "$SOURCE_DIR/rsatest16.vhd"

## elaborate the  entity and the architecture
elaborate modmult -arch modmult1 -update

## link to the target library
link

## flatten hierarchy
uniquify

## no area constraints for compilation
max_area 0

## compile the design before configuring the DFT
compile

## configure muxed-D scan cells (adding test structure/scan cells), set the clock, test period, type of scan cells, the reset, scan input and output, scan enable and test mode.
set_scan_configuration -style multiplexed_flip_flop
set_dft_configuration -fix_clock enable
set test_default_period 100
set_dft_signal -view existing_dft -type ScanClock -timing {45 55} -port clk
set_dft_signal -view existing_dft -type Reset -active_state 0 -port reset
set_dft_signal -view spec -type ScanDataIn -port SERIAL_IN
set_dft_signal -view spec -type ScanDataOut -port SERIAL_OUT
create_test_protocol -infer_clock -infer_asynch


## compilation after placing the sequential elements by scan equivalent
compile -scan

## check for DFT violations
dft_drc
 

## specify the scan chain
set_scan_configuration -chain_count 1
set_scan_configuration -clock_mixing no_mix
set_scan_path chain1 -scan_data_in SERIAL_IN -scan_data_out SERIAL_OUT
-complete 


## insert the scan chain
preview_dft
insert_dft

## check if the scan chain is fully implemented
set_scan_state scan_existing

## estimate the error coverage
dft_drc -coverage_estimate

## report the scan chain and instances in each chain
##report_scan_path -view existing_dft -chain all > reports/chain.rep
##report_scan_path -view existing_dft -cell all > reports/cell.rep

## write out a top-level netlist for the top-level design
change_names -hierarchy -rule verilog 
write -format verilog -hierarchy -output rsa_netlist.vg
write -format ddc -hierarchy -output rsa_netlist.ddc
write_scan_def -output rsa_netlist.def

## identify the netlist format that is exported to the Tetramax
set test_stil_netlist_format verilog

## write out test protocol file in STIL (Standard Test Interface Language) format 
write_test_protocol -output rsa_test_protocol.spf

quit


