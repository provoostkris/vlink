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

  #related ip cores
  proc_compile_core ../../lfsr
  proc_compile_core ../../prbs
  proc_compile_core ../../sei

  #top level file
  proc_compile_core ../../vlink


echo "Compiling test bench"

  vcom  -quiet -work work ../simulation/tb_vlink.vhd

echo "start simulation"

  vsim -t ns -gui -novopt work.tb_vlink

echo "adding waves"

  add wave  -expand             -group bench       /tb_vlink/*
  
  add wave  -expand -r           -group DUT  -ports /tb_vlink/*
  

echo "opening wave forms"

  view wave
  WaveRestoreCursors {{Cursor 1} {0 ps} 0}
  quietly wave cursor active 0
  configure wave -namecolwidth 300
  configure wave -valuecolwidth 100
  configure wave -justifyvalue left
  configure wave -signalnamewidth 2
  configure wave -snapdistance 10
  configure wave -datasetprefix 0
  configure wave -rowmargin 4
  configure wave -childrowmargin 2
  configure wave -gridoffset 0
  configure wave -gridperiod 1
  configure wave -griddelta 40
  configure wave -timeline 0
  configure wave -timelineunits ns
  update
  WaveRestoreZoom {0 ps} {100 ns}

  
  
  
  
  
  
  run -all