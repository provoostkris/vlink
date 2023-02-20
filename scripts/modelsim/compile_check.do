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
    set path_core $directory
    do $path_core/scripts/modelsim/core.do
  }

  #related ip cores
  proc_compile_core ../vhdl/lfsr
  proc_compile_core ../vhdl/prbs

  #top level file
  proc_compile_core ../vhdl/vlink
