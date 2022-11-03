
echo "Compiling design"
vlib work

vcom  -quiet -work work ../rtl/pckg_lfsr.vhd
vcom  -quiet -work work ../rtl/lfsr_ser_cfg.vhd

echo "Compiling test bench" 

vcom  -quiet -work work ../simulation/tb_lfsr.vhd

echo "start simulation"

vsim -gui -novopt work.tb_lfsr

echo "adding waves"

add wave  -expand             -group bench       /tb_lfsr/*
add wave  -expand             -group dut         /tb_lfsr/i_lfsr_ser_cfg/*

echo "opening wave forms"

view wave

run -all