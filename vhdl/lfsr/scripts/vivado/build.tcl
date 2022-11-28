# Typical usage: vivado -mode tcl -source build.tcl

set loc_script [file normalize [info script]]
set loc_folder [file dirname $loc_script]
puts $loc_folder
cd $loc_folder

# Create the project and directory structure
create_project -force lfsr ./lfsr -part xc7z010clg400-1

set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]

#
# Add various sources to the project
add_files -norecurse {
  ../../rtl/pckg_lfsr.vhd     /
  ../../rtl/lfsr_ser_cfg.vhd  /
}

#
# Update to set top and file compile order
update_compile_order -fileset sources_1

#
# Launch Synthesis
launch_runs synth_1
wait_on_run synth_1
open_run synth_1 -name netlist_1

#
# Launch Implementation
launch_runs impl_1 -to_step route_design
wait_on_run impl_1

