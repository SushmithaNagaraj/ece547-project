## Do confidentiality check on imported netlist

## setup stuff
set top_module aes_netlist
set synthesized_files [list ./aes_netlist.v]
set cell_lib  ../NangateOpenCellLibrary/Front_End/Verilog/NangateOpenCellLibrary.v
set stil_file [list ./aes_test_protocol.spf]
#################################################
#### read in standard cells and user's design ###
#################################################
# remove any other designs from design compiler's memory
read_netlist -delete
# read in standard cell library
read_netlist $cell_lib -library
# read in scan cell library
#read_netlist $scan_lib -library
# read in user's synthesized verilog code
read_netlist $synthesized_files
#################################################
#### BUILD and DRC test model

#ECE 128 – Synopsys Tutorial: Using DFT Compiler & TetraMax - 19 / 20

#################################################
run_build_model
# ignoring warnings like N20 or B10
# Set STIL file from DFT Compiler
set_drc $stil_file
# run check to see if synthesized code violates any testing rules
run_drc
#################################################
#### Generate ATPG (patterns)- full sequential
#################################################
# capture all faults, 9 capture cycles
set_atpg -capture_cycles 9 -full_seq_atpg
remove_faults -all



### CONFIDENTIALITY ALGO BELOW ####


#set assets [join] ## list of key pins

set asset "rst"

set FanoutFinal ""
redirect -file FanoutFinal.temp {report_fanout -from $asset}
sh python process_fanout.py
set fanout_file_handle [open FanoutFinal_out.temp r]
while { [gets $fanout_file_handle each_line] != -1} {
	lappend FanoutFinal $each_line
}
set FanoutFinal [join $FanoutFinal]

#redirect -variable FanoutFinal [gets $fanout_file_handle]

# mask capture registers
# first change to DRC mode or add_capture_mask won't work
drc

foreach FO $FanoutFinal {
	add_capture_mask $FO
}

#change back to TEST mode for this (redirect to null bc lots of verbose stuff otherwise)
#test > /dev/null

while 1 {
	foreach FO $FanoutFinal {
		drc -force
		remove_capture_masks $FO
		test > /dev/null
		add_faults $asset -stuck 01
		run_atpg FUll_sequential_only
		analyze_faults $asset -stuck 0
		analyze_faults $asset -stuck 1
		
		##if (detectedFaults > 1) {
			## logic here
		##}

	}
	# temporary
	break

}

exit
