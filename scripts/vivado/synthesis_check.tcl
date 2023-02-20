# ------------------------------------------------------------------------------
# --  synthesis script to run all vivado builds
# --  rev. 1.0 : 2022 Provoost Kris
# ------------------------------------------------------------------------------

# Typical usage: vivado -mode tcl -source build.tcl

set root_script [file normalize [info script]]
set root_folder [file dirname $root_script]
puts $root_folder
cd $root_folder

# go to the source code folder
cd ../../vhdl

# list all cores , and run the vivado build script
foreach fileName [glob -type d *] {
  set file_src $root_folder/../../vhdl/$fileName/scripts/vivado/build.tcl
  puts ""
  puts "Running synthesis script : $file_src"
  source $file_src
  puts "Running synthesis completed : closing project"
  if { [catch {current_project}] } {
    # nothing
  } else {
    close_project
  }
}