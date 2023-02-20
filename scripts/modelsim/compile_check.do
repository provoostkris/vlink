# ------------------------------------------------------------------------------
# --  simulation script to check syntax with modelsim
# --  rev. 1.0 : 2022 Provoost Kris
# ------------------------------------------------------------------------------

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
    do $directory/scripts/modelsim/core.do $directory
  }

  #related ip cores
  proc_compile_core ../../vhdl/fir
  proc_compile_core ../../vhdl/lfsr
  proc_compile_core ../../vhdl/prbs
  proc_compile_core ../../vhdl/psk
  proc_compile_core ../../vhdl/sei

  #top level file
  proc_compile_core ../../vhdl/vlink
