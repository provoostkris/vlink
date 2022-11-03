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
-- *  file        : prbs_tx_ser.vhd                                               *
-- *  version     : 1.2                                                           *
-- *  target      : plain vhdl                                                    *
-- *  description : generator / transmitter for prbs-sequence and bit-pattern     *
-- ********************************************************************************

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_arith.all;
use     ieee.std_logic_unsigned.all;

library work;
use     work.prbs_pck.all;

-- ********************************************************************************

entity prbs_tx_ser is
  port (
    clk        : in  std_logic;                      -- synchron clock
    reset      : in  std_logic;                      -- asynchron reset
    clk_en     : in  std_logic;                      -- clock enable
    prbs_set   : in  std_logic;                      -- set new prbs / bit pattern
    prbs_type  : in  std_logic_vector (3 downto 0);  -- type of prbs / bit pattern
    prbs_inv   : in  std_logic;                      -- invert prbs pattern
    err_insert : in  std_logic;                      -- manual error insert
    err_set    : in  std_logic;                      -- set new error type
    err_type   : in  std_logic_vector (3 downto 0);  -- error type
    tx_bit     : out std_logic                       -- tx serial output
  );
end prbs_tx_ser;

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
--
-- err_insert : a bit error is inserted in the serial output data with a rising edge ('0' to '1') synchron to clk 
--
-- ********************************************************************************
--
-- err_set : the new err_type is assumed when prbs_set goes from '0' to '1'
--
-- error occurence vector :
--
-- err_type    transmitted error rate   error distance at 100 mbit/sec   error distance at 1 mbit/sec
-- --------------------------------------------------------------------------------------------------
--  0 0 0 0      0                      -                                -
--  0 0 0 1     10 ^ - 1                100 ns                            10 us
--  0 0 1 0     10 ^ - 2                  1 us                           100 us
--  0 0 1 1     10 ^ - 3                 10 us                             1 ms
--  0 1 0 0     10 ^ - 4                100 us                            10 ms
--  0 1 0 1     10 ^ - 5                  1 ms                           100 ms
--  0 1 1 0     10 ^ - 6                 10 ms                             1 sec
--  0 1 1 1     10 ^ - 7                100 ms                            10 sec
--  1 0 0 0     10 ^ - 8                  1 sec                          100 sec
--  1 0 0 1     10 ^ - 9                 10 sec                           17 min
--  1 0 1 0     10 ^ -10                100 sec                          167 min = 2,8 std
--  1 0 1 1     10 ^ -11                 17 min                           27,8 std
--  1 1 0 0     10 ^ -12                167 min = 2,8 std                 11,6 tage
--  1 1 0 1     variable : 10 ^ - 3  bis  10 ^ - 6  (at the moment not implemented)
--  1 1 1 0     variable : 10 ^ - 3  bis  10 ^ -12  (at the moment not implemented)
--  1 1 1 1     variable : 10 ^ - 9  bis  10 ^ -12  (at the moment not implemented)
--
-- ********************************************************************************

architecture prbs_tx_ser of prbs_tx_ser is

-- ********************************************************************************

signal   clk_en_i, prbs_set_i, prbs_set_pulse, prbs_sr_out, prbs_out, pat_sr_out, pat_out : std_logic;
signal   prbs_inv_i, err_insert_i, err_insert_pulse, err_set_i, err_set_pulse             : std_logic;
signal   prbs_type_i                                                                      : std_logic_vector ( 3 downto 0);
signal   pat_sr                                                                           : std_logic_vector ( 7 downto 0);
signal   prbs_sr                                                                          : std_logic_vector (31 downto 1);
signal   dl_cnt                                                                           : integer range 0 to 31;
signal   pat_cnt                                                                          : integer range 0 to 7;

signal   err_none, err_10_01, err_10_02, err_10_03, err_10_04, err_10_05, err_10_06       : std_logic;
signal             err_10_07, err_10_08, err_10_09, err_10_10, err_10_11, err_10_12       : std_logic;

signal   err_cnt_9, err_cnt_99, err_cnt_999, err_cnt_9999, err_cnt_99999, err_cnt_999999  : std_logic;
signal   err_cnt, err_cnt2                                                                : integer range 1 to 1000000;
signal   err_cnt2_1000000, err_inc, err_count_pulse, err_gen_out                          : std_logic;

-- ********************************************************************************

begin

-- ********************************************************************************
-- * latching of : pattern sequence or bit pattern                                *
-- ********************************************************************************

in_latch : process (clk, reset)
begin
  if (reset = '1') then

    clk_en_i       <= '0';
    prbs_set_i     <= '0';
    prbs_set_pulse <= '0';
    prbs_type_i    <= "0000";
    prbs_inv_i     <= '0';
                    
  elsif rising_edge (clk) then

    clk_en_i   <= clk_en;
    prbs_set_i <= prbs_set;

    if (prbs_set = '1') and (prbs_set_i = '0') then
      prbs_set_pulse <= '1';
      prbs_type_i    <= prbs_type;
      prbs_inv_i     <= prbs_inv;
    else
      prbs_set_pulse <= '0';
    end if;

  end if;
end process;

-- ********************************************************************************
-- * prbs sequence ring shift register                                            *
-- ********************************************************************************

prbs_ring_sr : process (clk, reset)
begin
  if (reset = '1') then

    prbs_sr     <= (others => '1');
    prbs_sr_out <= '1';
    prbs_out    <= '1';
    dl_cnt      <=  0 ;

  elsif rising_edge (clk) then

    if (prbs_set_pulse = '1') then
      prbs_sr <= "1111111111111111111111111111111";    -- init prbs shift register

    elsif (clk_en_i = '1') then

      prbs_sr (31 downto 2) <= prbs_sr (30 downto 1);  -- shift

      case prbs_type_i is
        when prbs_2_09_1 =>  prbs_sr (1) <= prbs_sr ( 5) xor prbs_sr ( 9);  prbs_sr_out <= prbs_sr ( 9) xor prbs_inv_i;
        when prbs_2_11_1 =>  prbs_sr (1) <= prbs_sr ( 9) xor prbs_sr (11);  prbs_sr_out <= prbs_sr (11) xor prbs_inv_i;
        when prbs_2_15_1 =>  prbs_sr (1) <= prbs_sr (14) xor prbs_sr (15);  prbs_sr_out <= prbs_sr (15) xor prbs_inv_i;
        when prbs_2_20_1 =>  prbs_sr (1) <= prbs_sr (17) xor prbs_sr (20);  prbs_sr_out <= prbs_sr (20) xor prbs_inv_i;
        when prbs_2_20_2 =>  prbs_sr (1) <= prbs_sr ( 3) xor prbs_sr (20);  prbs_sr_out <= prbs_sr (20) xor prbs_inv_i;
        when prbs_2_23_1 =>  prbs_sr (1) <= prbs_sr (18) xor prbs_sr (23);  prbs_sr_out <= prbs_sr (23) xor prbs_inv_i;
        when prbs_2_29_1 =>  prbs_sr (1) <= prbs_sr (27) xor prbs_sr (29);  prbs_sr_out <= prbs_sr (29) xor prbs_inv_i;
        when prbs_2_31_1 =>  prbs_sr (1) <= prbs_sr (28) xor prbs_sr (31);  prbs_sr_out <= prbs_sr (31) xor prbs_inv_i;
        when others      =>  prbs_sr (1) <= '1';
      end case;

    end if;

    -- special dealing for the sequence 2^20-1 (itu-t o.151) when already 14 similar bits were transmitted

    if (clk_en_i = '1') then
    
      if    (prbs_type_i = prbs_2_20_1) and (dl_cnt = 14)  then  dl_cnt <= 1;           -- 14 similar bits and the sequence 2^20 - 1 : counter reset
      elsif (dl_cnt = 31)                                  then  dl_cnt <= 1;           -- overflow (did normally not happen) : counter reset
      elsif (prbs_sr_out = prbs_out)                       then  dl_cnt <= dl_cnt + 1;  -- no bitchange : increment counter
      else                                                       dl_cnt <= 1;           -- bitchange : counter reset
      end if;

      if (prbs_type_i = prbs_2_20_1) and (dl_cnt = 14)  -- 14 similar bits and the sequence 2^20 - 1
        then  prbs_out <= not prbs_out;                 -- send now inverted bit
        else  prbs_out <= prbs_sr_out;                  -- normal case : transmit bit from shift register
      end if;

    end if;

  end if;
end process;

-- ********************************************************************************
-- * bit pattern generator                                                        *
-- ********************************************************************************

pat_gen : process (clk, reset)
begin
  if (reset = '1') then

    pat_cnt    <=  0 ;
    pat_sr     <= "11111111";
    pat_sr_out <= '1';
    pat_out    <= '1';

  elsif rising_edge (clk) then

    if (clk_en_i = '1') then

      if (pat_cnt = 7)
        then  pat_cnt <= 0;
        else  pat_cnt <= pat_cnt + 1;
      end if;

      if (pat_cnt = 7) then
        case prbs_type_i is
          when pat_all_0 =>  pat_sr <= pattern_all_0;
          when pat_all_1 =>  pat_sr <= pattern_all_1;
          when pat_alt_s =>  pat_sr <= pattern_alt_s;
          when pat_alt_d =>  pat_sr <= pattern_alt_d;
          when pat_one_0 =>  pat_sr <= pattern_one_0;
          when pat_one_1 =>  pat_sr <= pattern_one_1;
          when pat_two_0 =>  pat_sr <= pattern_two_0;
          when pat_two_1 =>  pat_sr <= pattern_two_1;
          when others    =>  pat_sr <= pattern_all_1;
        end case;
      end if;

      pat_sr_out <= pat_sr (pat_cnt);

    end if;

    if (clk_en_i <= '1') then
      pat_out <= pat_sr_out;
    end if;

  end if;
end process;

-- ********************************************************************************
-- * error occurence generation                                                   *
-- ********************************************************************************

counter : process (clk, reset)
begin
  if (reset = '1') then

    err_set_i        <= '0';
    err_set_pulse    <= '0';

    err_none         <= '1';
    err_10_01        <= '0';
    err_10_02        <= '0';
    err_10_03        <= '0';
    err_10_04        <= '0';
    err_10_05        <= '0';
    err_10_06        <= '0';
    err_10_07        <= '0';
    err_10_08        <= '0';
    err_10_09        <= '0';
    err_10_10        <= '0';
    err_10_11        <= '0';
    err_10_12        <= '0';

    err_cnt_9        <= '0';
    err_cnt_99       <= '0';
    err_cnt_999      <= '0';
    err_cnt_9999     <= '0';
    err_cnt_99999    <= '0';
    err_cnt_999999   <= '0';

    err_cnt          <=  1 ;
    err_inc          <= '0';
    err_cnt2_1000000 <= '0';
    err_cnt2         <=  1 ;

    err_count_pulse  <= '0';

  elsif rising_edge (clk) then

    err_set_i <= err_set;

    if    (err_set  = '1') and (err_set_i = '0')  then  err_set_pulse <= '1';
    elsif (clk_en_i = '1')                        then  err_set_pulse <= '0';
    end if;


    if (err_set = '1') then
      
      err_none  <= '0';
      err_10_01 <= '0';
      err_10_02 <= '0';
      err_10_03 <= '0';
      err_10_04 <= '0';
      err_10_05 <= '0';
      err_10_06 <= '0';
      err_10_07 <= '0';
      err_10_08 <= '0';
      err_10_09 <= '0';
      err_10_10 <= '0';
      err_10_11 <= '0';
      err_10_12 <= '0';

      case err_type is
        when err_type_none  =>  err_none  <= '1';
        when err_type_10_01 =>  err_10_01 <= '1';
        when err_type_10_02 =>  err_10_02 <= '1';
        when err_type_10_03 =>  err_10_03 <= '1';
        when err_type_10_04 =>  err_10_04 <= '1';
        when err_type_10_05 =>  err_10_05 <= '1';
        when err_type_10_06 =>  err_10_06 <= '1';
        when err_type_10_07 =>  err_10_07 <= '1';
        when err_type_10_08 =>  err_10_08 <= '1';
        when err_type_10_09 =>  err_10_09 <= '1';
        when err_type_10_10 =>  err_10_10 <= '1';
        when err_type_10_11 =>  err_10_11 <= '1';
        when err_type_10_12 =>  err_10_12 <= '1';
        when others         =>  null;
      end case;

    end if;

    if (clk_en_i = '1') then

      -- first counter bank

      if (err_cnt = 9) and ((err_10_01 = '1') or (err_10_07 = '1'))
        then  err_cnt_9 <= '1';
        else  err_cnt_9 <= '0';
      end if;

      if (err_cnt = 99) and ((err_10_02 = '1') or (err_10_08 = '1'))
        then  err_cnt_99 <= '1';
        else  err_cnt_99 <= '0';
      end if;

      if (err_cnt = 999) and ((err_10_03 = '1') or (err_10_09 = '1'))
        then  err_cnt_999 <= '1';
        else  err_cnt_999 <= '0';
      end if;

      if (err_cnt = 9999) and ((err_10_04 = '1') or (err_10_10 = '1'))
        then  err_cnt_9999 <= '1';
        else  err_cnt_9999 <= '0';
      end if;

      if (err_cnt = 99999) and ((err_10_05 = '1') or (err_10_11 = '1'))
        then  err_cnt_99999 <= '1';
        else  err_cnt_99999 <= '0';
      end if;

      if (err_cnt = 999999) and ((err_10_06 = '1') or (err_10_12 = '1') or (err_none = '1'))
        then  err_cnt_999999 <= '1';
        else  err_cnt_999999 <= '0';
      end if;

      if (err_cnt_9      = '1') or (err_cnt_99     = '1') or (err_cnt_999    = '1') or
         (err_cnt_9999   = '1') or (err_cnt_99999  = '1') or (err_cnt_999999 = '1') or (err_set_pulse = '1')
           then  err_cnt <= 1;
           else  err_cnt <= err_cnt + 1;
      end if;

      -- second counter bank (for minor error rates 10^-7 bis 10^-12)

      if (err_cnt_9      = '1') or (err_cnt_99     = '1') or (err_cnt_999    = '1') or
         (err_cnt_9999   = '1') or (err_cnt_99999  = '1') or (err_cnt_999999 = '1') 
           then  err_inc <= '1';
           else  err_inc <= '0';
      end if;

      if (err_cnt2 = 1000000)
        then  err_cnt2_1000000 <= '1';
        else  err_cnt2_1000000 <= '0';
      end if;

      if    (err_set_pulse    = '1') then  err_cnt2 <= 1;             -- reset
      elsif (err_inc          = '0') then  null;                      -- wait
      elsif (err_cnt2_1000000 = '1') then  err_cnt2 <= 1;             -- counter is at the end
      else                                 err_cnt2 <= err_cnt2 + 1;  -- increment
      end if;

      -- error choosing regarding error occuring vector

      if (err_none = '1') then

        err_count_pulse <= '0';

      elsif ((err_cnt_9      = '1') and (err_10_01 = '1')) or
            ((err_cnt_99     = '1') and (err_10_02 = '1')) or
            ((err_cnt_999    = '1') and (err_10_03 = '1')) or
            ((err_cnt_9999   = '1') and (err_10_04 = '1')) or
            ((err_cnt_99999  = '1') and (err_10_05 = '1')) or
            ((err_cnt_999999 = '1') and (err_10_06 = '1')) then

        err_count_pulse <= '1';

      elsif (err_cnt2_1000000 = '1') and (err_inc = '1') and ((err_10_07 = '1') or
                                                              (err_10_08 = '1') or
                                                              (err_10_09 = '1') or
                                                              (err_10_10 = '1') or
                                                              (err_10_11 = '1') or
                                                              (err_10_12 = '1')) then

        err_count_pulse <= '1';

      else 

        err_count_pulse <= '0';

      end if;

      -- end

    end if;

  end if;
end process;

-- ********************************************************************************
-- * data selector and error generation                                           *
-- ********************************************************************************

err_gen : process (clk, reset)
begin
  if (reset = '1') then

    err_insert_i     <= '0';
    err_insert_pulse <= '0';
    err_gen_out      <= '0';

  elsif rising_edge (clk) then

    err_insert_i <= err_insert;

    if    (err_insert = '1') and (err_insert_i = '0') then  err_insert_pulse <= '1';  -- set flag : error to send
    elsif (clk_en_i   = '1')                          then  err_insert_pulse <= '0';  -- reset flag
    end if;

    if (clk_en_i = '1') then

      if (prbs_type_i (3) = '0')
        then  err_gen_out <= prbs_out xor err_insert_pulse xor err_count_pulse;       -- prbs sequence
        else  err_gen_out <= pat_out  xor err_insert_pulse xor err_count_pulse;       -- bit pattern
      end if;

    end if;

  end if;
end process;

tx_bit <= err_gen_out;

end prbs_tx_ser;

-- ********************************************************************************
-- list of changes
-- ===============
-- date        version  name  change
-- 31.05.2004  1.0      thg   creation
-- 13.06.2004  1.1      thg   korrection : pattern 2^20-1 bit change after 14 similar bits
-- 19.06.2004  1.2      thg   modification : all in english
-- ********************************************************************************
