-- ********************************************************************************
-- *  copyright (c) thorsten gaertner, oststeinbek / germany 2004                 *
-- ********************************************************************************
-- *  this source file may be used and distributed without restriction            *
-- *  provided that this copyright statement is not removed from the file and     *
-- *  that any derivative work contains the original copyright notice and the     *
-- *  associated disclaimer.                                                      *
-- ********************************************************************************
-- *  this source file is provided "as is" and without any express or implied     *
-- *  warranties, that this source file is                                        *
-- *  1. free from any claims of infringement,                                    *
-- *  2. the merchantability or fitness for a particular purpose.                 *
-- ********************************************************************************
--
-- ********************************************************************************
-- *  file        : prbs_pck.vhd                                                  *
-- *  version     : 1.1                                                           *
-- *  target      : plain vhdl                                                    *
-- *  description : package for prbs-sequence & bit-pattern transmitter/receiver  *
-- ********************************************************************************

library ieee;
use     ieee.std_logic_1164.all;

package prbs_pck is

-- ********************************************************************************
--
-- prbs_set    : the new prbs_type is assumed when prbs_set goes from '0' to '1'
--
-- prbs vector :
--
-- prbs_type    transmitted prbs sequence or bit pattern
-- -------------------------------------------------------
--  0 0 0 0     2 ^  9  -1     itu-t o.150 / o.153
--  0 0 0 1     2 ^ 11  -1     itu-t o.150 / o.152 / o.153
--  0 0 1 0     2 ^ 15  -1     itu-t o.150 / o.151
--  0 0 1 1     2 ^ 20  -1     itu-t o.150 / o.151
--  0 1 0 0     2 ^ 20  -1     itu-t o.150 / o.153
--  0 1 0 1     2 ^ 23  -1     itu-t o.150 / o.151
--  0 1 1 0     2 ^ 29  -1     itu-t o.150
--  0 1 1 1     2 ^ 31  -1     itu-t o.150
--  1 0 0 0     all '0'                   : "00000000"
--  1 0 0 1     all '1'                   : "11111111"
--  1 0 1 0     alternating '0'  and '1'  : "01010101"
--  1 0 1 1     alternating '00' and '11' : "00110011"
--  1 1 0 0     one '0' and seven '1'     : "01111111"
--  1 1 0 1     one '1' and seven '0'     : "10000000"
--  1 1 1 0     two '0' and six   '1'     : "01110111"
--  1 1 1 1     two '1' and six   '0'     : "10001000"
--
-- ********************************************************************************
--
--  pattern               :  2^9 - 1        2^11 - 1       2^15 - 1       2^20 - 1       2^20 - 1       2^23 - 1       2^29 - 1       2^31 - 1
--  sequence length (bit) :  511            2047           32767          1.048.575      1.048.575      8.388.607      536.870.911    2.147.483.647
--  standard              :  itu-t o.150    itu-t o.150    itu-t o.150    itu-t o.150    itu-t o.150    itu-t o.150    itu-t o.150    itu-t o.150    
--                           itu-t o.153    itu-t o.152    itu-t o.151    itu-t o.151    itu-t o.153    itu-t o.151
--                                          itu-t o.153
--  bit rate (kbit/s)     :  up to 14.4     64,            1544,  2048,   1544,  6312,   up to 72       34368, 44736,
--                                          n*64 (n=1..31) 6312,  8448,   32064, 44736                  139264
--                                          48 to 168      32064, 44736
--  register              :  9              11             15             20             20             23             29             31
--  feedback              :  5th + 9th      9th + 11th     14th + 15th    17th + 20th    3rd + 20th     18th + 23rd    27th + 29th    28th + 31th
--  longest zero seqence  :  8 (non inv.)   10 (non inv.)  15 (inverted)  14             19 (non inv.)  23 (inverted)  29 (inverted)  31 (inverted)
--  note                                                                  1
--
--  notes :
--  1 = an output bit is forced to be a one whenever the previous 14 bits are all zero.
--
-- ********************************************************************************

constant  prbs_2_09_1    : std_logic_vector (3 downto 0) := "0000";
constant  prbs_2_11_1    : std_logic_vector (3 downto 0) := "0001";
constant  prbs_2_15_1    : std_logic_vector (3 downto 0) := "0010";
constant  prbs_2_20_1    : std_logic_vector (3 downto 0) := "0011";
constant  prbs_2_20_2    : std_logic_vector (3 downto 0) := "0100";
constant  prbs_2_23_1    : std_logic_vector (3 downto 0) := "0101";
constant  prbs_2_29_1    : std_logic_vector (3 downto 0) := "0110";
constant  prbs_2_31_1    : std_logic_vector (3 downto 0) := "0111";

constant  pat_all_0      : std_logic_vector (3 downto 0) := "1000";
constant  pat_all_1      : std_logic_vector (3 downto 0) := "1001";
constant  pat_alt_s      : std_logic_vector (3 downto 0) := "1010";
constant  pat_alt_d      : std_logic_vector (3 downto 0) := "1011";
constant  pat_one_0      : std_logic_vector (3 downto 0) := "1100";
constant  pat_one_1      : std_logic_vector (3 downto 0) := "1101";
constant  pat_two_0      : std_logic_vector (3 downto 0) := "1110";
constant  pat_two_1      : std_logic_vector (3 downto 0) := "1111";

constant  pattern_all_0  : std_logic_vector (7 downto 0) := "00000000";
constant  pattern_all_1  : std_logic_vector (7 downto 0) := "11111111";
constant  pattern_alt_s  : std_logic_vector (7 downto 0) := "01010101";
constant  pattern_alt_d  : std_logic_vector (7 downto 0) := "00110011";
constant  pattern_one_0  : std_logic_vector (7 downto 0) := "01111111";
constant  pattern_one_1  : std_logic_vector (7 downto 0) := "10000000";
constant  pattern_two_0  : std_logic_vector (7 downto 0) := "01110111";
constant  pattern_two_1  : std_logic_vector (7 downto 0) := "10001000";

constant  err_type_none  : std_logic_vector (3 downto 0) := "0000";
constant  err_type_10_01 : std_logic_vector (3 downto 0) := "0001";
constant  err_type_10_02 : std_logic_vector (3 downto 0) := "0010";
constant  err_type_10_03 : std_logic_vector (3 downto 0) := "0011";
constant  err_type_10_04 : std_logic_vector (3 downto 0) := "0100";
constant  err_type_10_05 : std_logic_vector (3 downto 0) := "0101";
constant  err_type_10_06 : std_logic_vector (3 downto 0) := "0110";
constant  err_type_10_07 : std_logic_vector (3 downto 0) := "0111";
constant  err_type_10_08 : std_logic_vector (3 downto 0) := "1000";
constant  err_type_10_09 : std_logic_vector (3 downto 0) := "1001";
constant  err_type_10_10 : std_logic_vector (3 downto 0) := "1010";
constant  err_type_10_11 : std_logic_vector (3 downto 0) := "1011";
constant  err_type_10_12 : std_logic_vector (3 downto 0) := "1100";
constant  err_type_var_1 : std_logic_vector (3 downto 0) := "1101";
constant  err_type_var_2 : std_logic_vector (3 downto 0) := "1110";
constant  err_type_var_3 : std_logic_vector (3 downto 0) := "1111";

-- ********************************************************************************

end prbs_pck;

-- ********************************************************************************

package body prbs_pck is

end prbs_pck;

-- ********************************************************************************
-- list of changes
-- ===============
-- date        version  name  change
-- 06.06.2004  1.0      thg   creation
-- 26.06.2004  1.1      thg   addition : new header
-- ********************************************************************************
