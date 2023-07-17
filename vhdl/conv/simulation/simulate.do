# Clearing the transcript window:
.main clear

echo "Setting up parameters"

  set DEFAULT_LIB work

echo "Clean up libraries"

  #if {[file isdirectory $DEFAULT_LIB]} {vdel -all lib $DEFAULT_LIB}
  if {[file isdirectory $DEFAULT_LIB]} {file delete -force $DEFAULT_LIB}

echo "Compiling design"

  proc proc_ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
  proc_ensure_lib $DEFAULT_LIB

  proc proc_compile_core { directory } {
    echo " IP core compilation called for : $directory"
    do $directory/scripts/modelsim/core.do $directory
  }

  proc_compile_core ../../conv


echo "Compiling test bench"

  vcom  -quiet -work work ../simulation/tb_conv.vhd

echo "start simulation"

  vsim -gui -novopt work.tb_conv

echo "adding waves"

  add wave  -expand             -group bench       /tb_conv/*
  add wave  -expand             -group dut         /tb_conv/i_conv_enc/*

echo "opening wave forms"

  view wave
  run -all