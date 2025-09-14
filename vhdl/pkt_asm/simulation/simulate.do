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

  proc_compile_core ../../pkt_asm


echo "Compiling test bench"

  vcom  -2008 -quiet -work work ../simulation/tb_pkt_asm.vhd

echo "start simulation"

  vsim -gui -novopt work.tb_pkt_asm

echo "adding waves"

  add wave  -expand             -group bench       /tb_pkt_asm/*
  add wave  -expand             -group dut         /tb_pkt_asm/uut/*

echo "opening wave forms"

  view wave
  run -all

  configure wave -namecolwidth  280
  configure wave -valuecolwidth 120
  configure wave -justifyvalue right
  configure wave -signalnamewidth 1
  configure wave -snapdistance 10
  configure wave -datasetprefix 0
  configure wave -rowmargin 4
  configure wave -childrowmargin 2
  configure wave -gridoffset 0
  configure wave -gridperiod 1
  configure wave -griddelta 40
  configure wave -timeline 1
  configure wave -timelineunits us
  update

  wave zoom full