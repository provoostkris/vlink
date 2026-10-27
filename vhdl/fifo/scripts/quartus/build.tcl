# Run with: quartus_sh -t build.tcl

load_package flow

set script_path [file normalize [info script]]
set script_dir [file dirname $script_path]
set project_name "fifo"
set project_path [file join $script_dir $project_name]

cd $script_dir

# Remove Quartus-generated data before creating a fresh project.
foreach generated_dir {db incremental_db output_files} {
    set generated_path [file join $script_dir $generated_dir]
    if {[file exists $generated_path]} {
        file delete -force $generated_path
    }
}

project_new -overwrite -revision $project_name $project_path

set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE 5CSEBA6U23I7
set_global_assignment -name TOP_LEVEL_ENTITY axis_dual_port_fifo
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name MIN_CORE_JUNCTION_TEMP "-40"
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top

set rtl_dir [file normalize [file join $script_dir .. .. rtl]]
set_global_assignment -name VHDL_FILE [file join $rtl_dir axis_dual_port_fifo.vhd]
set_global_assignment -name VHDL_FILE [file join $rtl_dir pckg_fifo.vhd]
set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top

set compilation_start [clock seconds]
execute_flow -compile
project_close

set duration [expr {[clock seconds] - $compilation_start}]
puts [format "Quartus compilation complete in %d:%02d" \
    [expr {$duration / 60}] [expr {$duration % 60}]]
