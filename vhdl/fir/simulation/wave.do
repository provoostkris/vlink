
  add wave  -expand             -group bench       /tb_fir/*
  add wave  -expand             -group dut         /tb_fir/i_fir/*

  add wave  -radix decimal -format analog   -min -127   -max 128    -height 100  /tb_fir/i_fir/data_i
  add wave  -radix decimal -format analog   -min -32768 -max 32768  -height 100  /tb_fir/i_fir/data_o