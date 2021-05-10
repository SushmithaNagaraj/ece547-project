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

set asset "key[127]"
set ObservePoints ""

# enable scan for all flip-flops
drc -force
set_scan_ability on -all

#loop up here for assets


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

set FanoutTemp ""
set isNewNets [expr 0]
set FF_Level [expr 1]

while 1 {
	foreach FO $FanoutFinal {
		echo ---------Processing new fanout $FO -------------
		set detectedFaults [expr 0]
		drc -force

		# Removing the capture mask is not as easy as the paper makes it seem
		# Need to remove mask from current register AND capture masks from all previous fanin registers
		# Otherwise, fault propogation will be blocked at first masked register in the Asset fanout
		# This loop unmasks the full fanin for a given net until it reaches the Asset pin
		remove_capture_masks $FO
		set propagation_path ""
		set unmask_gate_name $FO
		set do_break [expr 0]
		while 1 {
			report_fanin -to ${unmask_gate_name}/D > FanIn.temp
			sh python process_unmask_fanin.py $asset
			set fanin_file_handle [open FanIn_out.temp r]
               		#should only be one line I'm just reusing this while loop cause its been working
			while { [gets $fanin_file_handle each_line] != -1} {
                        	if { [regexp -all "STOP" $each_line] == 1 } {
                                	set do_break [expr 1]
					break
                        	}
				if { [regexp -all "STOP" $each_line] == 0} {
					set unmask_gate_name $each_line
                        	}
        	        }

			# check if we've reached the Asset pin yet
			if ([expr $do_break == 1]) {
				break
			}
			
			lappend propagation_path $unmask_gate_name
			echo Unmasking $unmask_gate_name
			remove_capture_masks $unmask_gate_name
	                close $fanin_file_handle
	
		}
		set propagation_path [join $propagation_path]

		test > /dev/null
		add_faults $asset -stuck 01
		run_atpg FUll_sequential_only

		# need to get primitive gate ID for a given named net...annoying
		report_primitives $FO > Primitive.temp
		sh python process_gate_primitive.py
		set primitive_file_handle [open Primitive_out.temp r]
                while { [gets $primitive_file_handle each_line] != -1} {
			set gate_id $each_line
                }
		close $primitive_file_handle


		analyze_faults $asset -stuck 0 -observe $gate_id > fault0.temp
		analyze_faults $asset -stuck 1 -observe $gate_id > fault1.temp
		sh python process_fault0.py
		sh python process_fault1.py

		set fault_file_handle [open fault0_out.temp r]
		while { [gets $fault_file_handle each_line] != -1} {
        		if { [regexp -all "detected" $each_line] == 1 } {
				set detectedFaults [expr $detectedFaults + 1]
			}
		}
		close $fault_file_handle

		set fault_file_handle [open fault1_out.temp r]
		while { [gets $fault_file_handle each_line] != -1} {
                        if { [regexp -all "detected" $each_line] == 1 } {
                                set detectedFaults [expr $detectedFaults + 1]
                        }
                }
		close $fault_file_handle
		
		if ([expr $detectedFaults > 1]) {
			lappend ObservePoints $FO

			# append to FanoutTemp
			set pinPath ${FO}/Q
			redirect -file FanoutFinal.temp {report_fanout -from $pinPath}
			sh python process_fanout.py
			set fanout_file_handle [open FanoutFinal_out.temp r]
			while { [gets $fanout_file_handle each_line] != -1} {
			        lappend FanoutTemp $each_line
				set isNewNets [expr 1]
			}
			close $fanout_file_handle

			set pinPath ${FO}/QN
                        redirect -file FanoutFinal.temp {report_fanout -from $pinPath}
                        sh python process_fanout.py
                        set fanout_file_handle [open FanoutFinal_out.temp r]
                        while { [gets $fanout_file_handle each_line] != -1} {
                                lappend FanoutTemp $each_line
				set isNewNets [expr 1]
                        }
			close $fanout_file_handle
			
			drc -force
			set_scan_ability off $FO

			# need to re-add the capture masks from the previously calculated propagation path
			foreach net $propagation_path {
				echo Adding mask for $net
				add_capture_mask $net
			}
			echo Adding mask for $FO
			add_capture_mask $FO
		}

	}

	# check break condition
	set FanoutTemp [join $FanoutTemp]	
	if ([expr $isNewNets == 1]) {
		set FanoutFinal $FanoutTemp
		set FF_Level [expr $FF_Level + 1]	
	}
	if ([expr $isNewNets == 0]) {
		echo Done
		break
	}
	if ([expr $FF_Level == 3]) {
		break
	}
}

#exit
