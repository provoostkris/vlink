
  add wave  -expand             -group bench       /tb_nco/*
  add wave  -expand             -group dut         /tb_nco/i_nco/*

  add wave  -radix unsigned -format analog   -min      0   -max 4096    -height 100  /tb_nco/i_nco/phase_a
  add wave  -radix unsigned -format analog   -min      0   -max 4096    -height 100  /tb_nco/i_nco/phase_b
  add wave  -radix decimal  -format analog   -min  -4096   -max 4096    -height 100  /tb_nco/i_nco/nco_a
  add wave  -radix decimal  -format analog   -min  -4096   -max 4096    -height 100  /tb_nco/i_nco/nco_b
  add wave  -radix decimal  -format analog   -min  -4096   -max 4096    -height 100  /tb_nco/i_nco/nco_m