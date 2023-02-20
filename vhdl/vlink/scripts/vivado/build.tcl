# Typical usage: vivado -mode tcl -source build.tcl

set loc_script [file normalize [info script]]
set loc_folder [file dirname $loc_script]
puts $loc_folder
cd $loc_folder

set CompilationStart [clock seconds]


set duration [expr [clock seconds]-$CompilationStart]
set LastCompilationTime $CompilationStart
puts [format "Compilation duration: %d:%02d" [expr $duration/60] [expr $duration%60]]
puts [clock format $LastCompilationTime -format {Reporting last compilation time: %A, %d of %B, %Y - %H:%M:%S}]