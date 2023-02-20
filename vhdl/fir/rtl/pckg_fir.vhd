------------------------------------------------------------------------------
--  package for the fir designs
--  rev. 1.0 : 2023 Provoost Kris
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package pckg_fir is

type t_taps  is array(0 to 15) of integer;

constant c_16_taps_lpf_1 : t_taps := (
1381   ,
3033   ,
2827   ,
-217   ,
-3161  ,
-1198  ,
6190   ,
13188  ,
13188  ,
6190   ,
-1198  ,
-3161  ,
-217   ,
2827   ,
3033   ,
1381
);

constant c_16_taps_lpf_2 : t_taps := (
-427   ,
75     ,
1478   ,
1087   ,
-2007  ,
-2261  ,
5178   ,
14309  ,
14309  ,
5178   ,
-2261  ,
-2007  ,
1087   ,
1478   ,
75     ,
-427
);


end pckg_fir;

package body pckg_fir is


end pckg_fir;