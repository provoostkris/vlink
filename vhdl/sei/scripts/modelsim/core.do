
set CompilationStart [clock seconds]

echo " RTL level compilation started"

  set fp [open "$path_core/rtl.txt" r]
  while { [gets $fp data] >= 0 } {
       puts $data
       vcom -quiet -work work $path_core/$data
  }
  close $fp

echo " RTL level compilation stopped"

set duration [expr [clock seconds]-$CompilationStart]
set LastCompilationTime $CompilationStart
echo [format "Compilation duration: %d:%02d" [expr $duration/60] [expr $duration%60]]
puts [clock format $LastCompilationTime -format {Reporting last compilation time: %A, %d of %B, %Y - %H:%M:%S}]
