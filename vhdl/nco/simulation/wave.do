onerror resume

  add wave               -group bench              /tb_nco/*

  add wave               -group dut     -ports     /tb_nco/i_nco/*

  add wave               -group nco_a              /tb_nco/i_nco/gen_real/i_nco_a/*
  add wave               -group nco_a              /tb_nco/i_nco/gen_flt32/i_nco_a/*
  add wave               -group nco_a              /tb_nco/i_nco/gen_lut/i_nco_a/*

  add wave               -group nco_b              /tb_nco/i_nco/gen_real/i_nco_b/*
  add wave               -group nco_b              /tb_nco/i_nco/gen_flt32/i_nco_b/*
  add wave               -group nco_b              /tb_nco/i_nco/gen_lut/i_nco_b/*

  add wave  -radix unsigned -format analog   -min      0   -max 4096    -height 100  /tb_nco/i_nco/gen_real/i_nco_a/accum
  add wave  -radix unsigned -format analog   -min      0   -max 4096    -height 100  /tb_nco/i_nco/gen_flt32/i_nco_a/accum
  add wave  -radix unsigned -format analog   -min      0   -max 4096    -height 100  /tb_nco/i_nco/gen_lut/i_nco_a/accum

  add wave  -radix unsigned -format analog   -min      0   -max 4096    -height 100  /tb_nco/i_nco/gen_real/i_nco_b/accum
  add wave  -radix unsigned -format analog   -min      0   -max 4096    -height 100  /tb_nco/i_nco/gen_flt32/i_nco_b/accum
  add wave  -radix unsigned -format analog   -min      0   -max 4096    -height 100  /tb_nco/i_nco/gen_lut/i_nco_b/accum

  add wave  -radix decimal  -format analog   -min  -4096   -max 4096    -height 100  /tb_nco/i_nco/gen_real/i_nco_a/nco
  add wave  -radix decimal  -format analog   -min  -4096   -max 4096    -height 100  /tb_nco/i_nco/gen_flt32/i_nco_a/nco
  add wave  -radix decimal  -format analog   -min  -4096   -max 4096    -height 100  /tb_nco/i_nco/gen_lut/i_nco_a/nco

  add wave  -radix decimal  -format analog   -min  -4096   -max 4096    -height 100  /tb_nco/i_nco/gen_real/i_nco_b/nco
  add wave  -radix decimal  -format analog   -min  -4096   -max 4096    -height 100  /tb_nco/i_nco/gen_flt32/i_nco_b/nco
  add wave  -radix decimal  -format analog   -min  -4096   -max 4096    -height 100  /tb_nco/i_nco/gen_lut/i_nco_b/nco

  add wave  -radix decimal  -format analog   -min  -4096   -max 4096    -height 100  /tb_nco/i_nco/nco_m