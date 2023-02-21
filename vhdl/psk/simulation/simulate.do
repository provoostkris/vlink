# Clearing the transcript window:
.main clear

echo "Setting up parameters"

  set DEFAULT_LIB work

echo "Clean up old workspace"

  if {[file isdirectory $DEFAULT_LIB]} {file delete -force $DEFAULT_LIB}
  
  #if {[file exists sim_results.txt]} {file delete -force sim_results.txt}

echo "Compiling design"

  proc proc_ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
  proc_ensure_lib $DEFAULT_LIB

  proc proc_compile_core { directory } {
    echo " IP core compilation called for : $directory"
    do $directory/scripts/modelsim/core.do $directory
  }

  proc_compile_core ../../psk


echo "Compiling test bench"

  vcom  -quiet -work work ../simulation/tb_bpsk.vhd

echo "start simulation"
  
  vsim  -gui  \
        -novopt \
        work.tb_bpsk

echo "adding waves"

  add wave  -expand             -group bench       /tb_bpsk/*
  add wave  -expand             -group bpsk_mod    /tb_bpsk/i_bpsk_mod/*
  add wave  -expand             -group bpsk_demod  /tb_bpsk/i_bpsk_demod/*

echo "opening wave forms"

  view wave
  run -all