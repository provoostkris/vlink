
echo "Compiling design"
vlib work

vcom  -quiet -work work ../rtl/prbs_pck.vhd
vcom  -quiet -work work ../rtl/prbs_rx_ser.vhd
vcom  -quiet -work work ../rtl/prbs_tx_ser.vhd

echo "Compiling test bench" 

vcom  -quiet -work work ../simulation/tb_prbs.vhd

echo "start simulation"

vsim -gui -novopt work.tb_prbs

echo "adding waves"

add wave  -expand             -group bench       /tb_prbs/*

echo "opening wave forms"

view wave

run -all