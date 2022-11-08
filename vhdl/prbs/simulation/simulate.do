# Clearing the transcript window:
.main clear

echo "Setting up parameters"

  set DEFAULT_LIB work

echo "Clean up libraries"

  if {[file exists $DEFAULT_LIB]} {vdel -all -lib $DEFAULT_LIB}

echo "Compiling design"

  proc proc_ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
  proc_ensure_lib $DEFAULT_LIB

  proc proc_compile_core { directory } {
    echo " IP core compilation called for : $directory"
    set path_core $directory
    do $path_core/scripts/modelsim/core.do
  }

  proc_compile_core ../../prbs


echo "Compiling test bench"

  vcom  -quiet -work work ../simulation/tb_prbs.vhd

echo "start simulation"

  vsim -gui -novopt work.tb_prbs

echo "adding waves"

  add wave  -expand             -group bench       /tb_prbs/*

echo "opening wave forms"

  view wave
  run -all