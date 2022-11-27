# Typical usage: vivado -mode tcl -source build.tcl

set loc_script [file normalize [info script]]
set loc_folder [file dirname $loc_script]
puts $loc_folder
cd $loc_folder

# Create the project and directory structure
create_project -force lfsr ./lfsr -part xc7z010clg400-1

#
# Add various sources to the project
add_files {
  $loc_folder/../../rtl/pckg_lfsr.vhd     /
  $loc_folder/../../rtl/lfsr_ser_cfg.vhd  /
}

#
# Now import/copy the files into the project
import_files -force

#
# Set VHDL library property on some files
set_property library work [get_files {*.vhdl}]

#
# Update to set top and file compile order
update_compile_order -fileset sources_1

#
# Launch Synthesis
launch_runs synth_1
wait_on_run synth_1
open_run synth_1 -name netlist_1

#
# Generate a timing and power reports and write to disk
# Can create custom reports as required
report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose \
-max_paths 10 -input_pins -file syn_timing.rpt
report_power -file syn_power.rpt

#
# Launch Implementation
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

#
# Generate a timing and power reports and write to disk
# comment out the open_run for batch mode
open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained \
-check_timing_verbose -max_paths 10 -input_pins -file imp_timing.rpt
report_power -file imp_power.rpt

#
# Can open the graphical environment if visualization desired
# comment out the for batch mode
#start_gui