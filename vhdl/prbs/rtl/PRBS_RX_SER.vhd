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
-- *  file        : prbs_rx_ser.vhd                                               *
-- *  version     : 1.4                                                           *
-- *  target      : plain vhdl                                                    *
-- *  description : receiver / tester for prbs-sequence and bit-pattern           *
-- ********************************************************************************

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_arith.all;
use     ieee.std_logic_unsigned.all;

library work;
use     work.prbs_pck.all;

-- ********************************************************************************

entity prbs_rx_ser is
  port (
    clk        : in  std_logic;                      -- synchron clock
    reset      : in  std_logic;                      -- asynchron reset
    clk_en     : in  std_logic;                      -- clock enable
    rx_bit     : in  std_logic;                      -- rx serial input
    prbs_set   : in  std_logic;                      -- set new prbs / bit pattern
    prbs_type  : in  std_logic_vector (3 downto 0);  -- type of prbs / bit pattern
    prbs_inv   : in  std_logic;                      -- invert prbs pattern
    syn_state  : out std_logic;                      -- synchronisation state output
    syn_los    : out std_logic;                      -- sync loss signaling output
    bit_err    : out std_logic;                      -- biterror signaling output
    clk_err    : out std_logic                       -- clockerror (bitslip) signaling output
  );
end prbs_rx_ser;

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

architecture prbs_rx_ser of prbs_rx_ser is

-- ********************************************************************************

type      prbs_state_type  is (null_state, fill_state, wait_state, test_state, sync_state);
attribute enum_encoding                    : string;
attribute enum_encoding of prbs_state_type : type is "00001 00010 00100 01000 10000";
signal    prbs_state                       : prbs_state_type;

signal    clk_en_i, rx_bit_i, prbs_set_i, prbs_inv_i                    : std_logic;
signal    prbs_set_pulse, prbs_set_merker, prbs_zero                    : std_logic;
signal    prbs_en, prbs_fill, prbs_test, prbs_err, err_test, err_flag   : std_logic;
signal    pat_en , pat_fill , pat_test , pat_err , pat_bit_i, pat_found : std_logic;
signal    prbs_bit_i, prbs_bit_ii, prbs_bit_iii                         : std_logic;
signal    prbs_type_i                                                   : std_logic_vector (  3 downto 0);
signal    pat_ref, pat_in                                               : std_logic_vector (  7 downto 0);
signal    prbs_sr                                                       : std_logic_vector ( 31 downto 1);
signal    err_sr                                                        : std_logic_vector (127 downto 0);
signal    pat_cnt                                                       : integer range 0 to  7;
signal    fill_cnt_ref, fill_cnt, err_cnt, dl_cnt                       : integer range 0 to 31;

-- ********************************************************************************

begin

-- ********************************************************************************
-- * latching of : pattern sequence or bit pattern                                *
-- ********************************************************************************

in_latch : process (clk, reset)
begin
  if (reset = '1') then

    clk_en_i        <= '0';
    rx_bit_i        <= '0';
    prbs_set_i      <= '0';
    prbs_set_pulse  <= '0';
    prbs_type_i     <= "0000";
    prbs_inv_i      <= '0';
    prbs_set_merker <= '0';
                    
  elsif rising_edge (clk) then

    clk_en_i   <= clk_en;
    rx_bit_i   <= rx_bit;
    prbs_set_i <= prbs_set;

    if (prbs_set = '1') and (prbs_set_i = '0') then
      prbs_set_pulse <= '1';
      prbs_type_i    <= prbs_type;
      prbs_inv_i     <= prbs_inv;
    else
      prbs_set_pulse <= '0';
    end if;

    if    (prbs_set_pulse = '1')  then  prbs_set_merker <= '1';
    elsif (clk_en_i = '1')        then  prbs_set_merker <= '0';
    end if;

  end if;
end process;

-- ********************************************************************************
-- * receiver state-machine                                                       *
-- ********************************************************************************

state_machine : process (clk, reset)
begin
  if (reset = '1') then

    fill_cnt_ref <=  0;
    fill_cnt     <=  0;
    prbs_en      <= '0';
    pat_en       <= '0';
    prbs_state   <= null_state;
    prbs_fill    <= '0';
    pat_fill     <= '0';
    prbs_test    <= '0';
    pat_test     <= '0';
    err_test     <= '0';

  elsif rising_edge (clk) then

    case prbs_type_i is
      when prbs_2_09_1 =>  fill_cnt_ref <=  9;  prbs_en <= '1';  pat_en <= '0';
      when prbs_2_11_1 =>  fill_cnt_ref <= 11;  prbs_en <= '1';  pat_en <= '0';
      when prbs_2_15_1 =>  fill_cnt_ref <= 15;  prbs_en <= '1';  pat_en <= '0';
      when prbs_2_20_1 =>  fill_cnt_ref <= 20;  prbs_en <= '1';  pat_en <= '0';
      when prbs_2_20_2 =>  fill_cnt_ref <= 20;  prbs_en <= '1';  pat_en <= '0';
      when prbs_2_23_1 =>  fill_cnt_ref <= 23;  prbs_en <= '1';  pat_en <= '0';
      when prbs_2_29_1 =>  fill_cnt_ref <= 29;  prbs_en <= '1';  pat_en <= '0';
      when prbs_2_31_1 =>  fill_cnt_ref <= 31;  prbs_en <= '1';  pat_en <= '0';
      when pat_all_0   =>  fill_cnt_ref <= 10;  prbs_en <= '0';  pat_en <= '1';
      when pat_all_1   =>  fill_cnt_ref <= 10;  prbs_en <= '0';  pat_en <= '1';
      when pat_alt_s   =>  fill_cnt_ref <= 10;  prbs_en <= '0';  pat_en <= '1';
      when pat_alt_d   =>  fill_cnt_ref <= 10;  prbs_en <= '0';  pat_en <= '1';
      when pat_one_0   =>  fill_cnt_ref <= 10;  prbs_en <= '0';  pat_en <= '1';
      when pat_one_1   =>  fill_cnt_ref <= 10;  prbs_en <= '0';  pat_en <= '1';
      when pat_two_0   =>  fill_cnt_ref <= 10;  prbs_en <= '0';  pat_en <= '1';
      when pat_two_1   =>  fill_cnt_ref <= 10;  prbs_en <= '0';  pat_en <= '1';
      when others      =>  fill_cnt_ref <= 10;  prbs_en <= '0';  pat_en <= '0';
    end case;

    if (clk_en_i = '1') then

      prbs_fill <= '0';
      pat_fill  <= '0';
      prbs_test <= '0';
      pat_test  <= '0';
      err_test  <= '0';

      case prbs_state is

        when null_state =>  -- reset all

          fill_cnt   <= 0;
          prbs_state <= fill_state;

        when fill_state =>  -- fill shift register with input data

          if    (prbs_en = '1') then prbs_fill <= '1';
          elsif (pat_en  = '1') then pat_fill  <= '1';
          end if;

          if    (prbs_en = '1') then
            if    (fill_cnt < fill_cnt_ref)  then  fill_cnt   <= fill_cnt + 1;  -- wait for shift register to fill
            else                                   prbs_state <= wait_state;    -- wait one cycle (ring shift register working)
            end if;
          elsif (pat_en = '1') then
            if    (fill_cnt < fill_cnt_ref)  then  fill_cnt   <= fill_cnt + 1;  -- wait for shift register to fill
            elsif (pat_found = '1')          then  prbs_state <= wait_state;    -- wait until pattern found
            end if;
          end if;

          -- restart when prbs-sequence or bit-pattern has changed
          if (prbs_set_merker = '1') then  prbs_state <= null_state;  end if;

        when wait_state =>  -- wait one clock : first rx-bit is now compared with bit from shift register

          if    (prbs_en = '1') then prbs_test <= '1';
          elsif (pat_en  = '1') then pat_test  <= '1';
          end if;

          fill_cnt   <=  0;
          prbs_state <= test_state;

          -- restart when prbs-sequence or bit-pattern has changed
          if (prbs_set_merker = '1') then  prbs_state <= null_state;  end if;

          -- restart when prbs shift-register is filled with zeros
          if (prbs_zero = '1') then  prbs_state <= null_state;  end if;

        when test_state =>  -- no error should occur in one full shift register cycle 

          if    (prbs_en = '1') then prbs_test <= '1';
          elsif (pat_en  = '1') then pat_test  <= '1';
          end if;

          if (fill_cnt = fill_cnt_ref)
            then  prbs_state <= sync_state;
            else  fill_cnt   <= fill_cnt + 1;
          end if;

          -- if an error happen in prbs- or pattern-mode : fill the shift register again with rx-data
          if ((prbs_en = '1') and (prbs_err = '1')) or ((pat_en = '1') and (pat_err = '1')) then  prbs_state <= null_state;  end if;

          -- restart when prbs-sequence or bit-pattern has changed
          if (prbs_set_merker = '1') then  prbs_state <= null_state;  end if;

          -- restart when prbs shift-register is filled with zeros
          if (prbs_zero = '1') then  prbs_state <= null_state;  end if;

        when sync_state =>  -- synchronized at rx bit stream

          if    (prbs_en = '1') then prbs_test <= '1';
          elsif (pat_en  = '1') then pat_test  <= '1';
          end if;

          err_test <= '1';

          -- if the maximum error-limit is reached : fill the shift register again with rx-data
          if (err_flag = '1')        then  prbs_state <= null_state;  end if;

          -- restart when prbs-sequence or bit-pattern has changed
          if (prbs_set_merker = '1') then  prbs_state <= null_state;  end if;

          -- restart when prbs shift-register is filled with zeros
          if (prbs_zero = '1') then  prbs_state <= null_state;  end if;

        when others  =>

          prbs_state <= null_state;

      end case;

    end if;

  end if;
end process;

-- ********************************************************************************
-- * prbs sequence ring shift register                                            *
-- ********************************************************************************

prbs_chk : process (clk, reset)
begin
  if (reset = '1') then

    prbs_bit_i   <= '0';
    prbs_bit_ii  <= '0';
    prbs_bit_iii <= '0';
    prbs_sr      <= (others => '1');
    prbs_err     <= '0';
    dl_cnt       <=  0 ;
    prbs_zero    <= '0';
             
  elsif rising_edge (clk) then

    if (clk_en_i = '1') then

      prbs_bit_i   <= rx_bit_i xor prbs_inv_i;
      prbs_bit_ii  <= prbs_bit_i;
      prbs_bit_iii <= prbs_bit_ii;

      if (prbs_fill = '1') then  -- fill the shift register

        -- normal : insert the received bit in the shift register
        -- the special case dealing for the sequence 2^20-1 (itu-t o.151) couldn't be applied here :
        -- when there were already 14 similar bits transmitted, the next bit is normally transmitted with the opposite polarity

        prbs_sr (31 downto 1) <= prbs_sr (30 downto 1) & prbs_bit_i;  -- shift

      elsif (prbs_test = '1') then  -- shift register is working in feedback mode

        case prbs_type_i is
          when prbs_2_09_1 =>  prbs_sr (1) <= prbs_sr ( 5) xor prbs_sr ( 9);
          when prbs_2_11_1 =>  prbs_sr (1) <= prbs_sr ( 9) xor prbs_sr (11);
          when prbs_2_15_1 =>  prbs_sr (1) <= prbs_sr (14) xor prbs_sr (15);
          when prbs_2_20_1 =>  prbs_sr (1) <= prbs_sr (17) xor prbs_sr (20);
          when prbs_2_20_2 =>  prbs_sr (1) <= prbs_sr ( 3) xor prbs_sr (20);
          when prbs_2_23_1 =>  prbs_sr (1) <= prbs_sr (18) xor prbs_sr (23);
          when prbs_2_29_1 =>  prbs_sr (1) <= prbs_sr (27) xor prbs_sr (29);
          when prbs_2_31_1 =>  prbs_sr (1) <= prbs_sr (28) xor prbs_sr (31);
          when others      =>  prbs_sr (1) <= '1';
        end case;

        prbs_sr (31 downto 2) <= prbs_sr (30 downto 1);  -- shift

      end if;

      if (prbs_test = '1') then  -- compare received bit with bit from shift register

        if    (prbs_type_i = prbs_2_20_1) and (dl_cnt = 14)  then  dl_cnt <= 1;           -- 14 similar bits and the sequence 2^20 - 1 : counter reset
        elsif (dl_cnt = 31)                                  then  dl_cnt <= 1;           -- overflow (did normally not happen) : counter reset
        elsif (prbs_bit_iii = prbs_bit_ii)                   then  dl_cnt <= dl_cnt + 1;  -- no bitchange : increment counter
        else                                                       dl_cnt <= 1;           -- bitchange : counter reset
        end if;

        if (prbs_type_i = prbs_2_20_1) and (dl_cnt = 14)         -- 14 similar bits and the sequence 2^20 - 1
          then  prbs_err <= prbs_bit_ii xor (not prbs_bit_iii);  -- compare receives bit with inverted last received bit
          else  prbs_err <= prbs_bit_ii xor prbs_sr (1);         -- normal case : compare received bit with bit from shift register 
        end if;

      else

        prbs_err <= '0';
        dl_cnt   <=  1 ;

      end if;

      -- check if the prbs shift register is filled only with zeros

      prbs_zero <= '0';

      case prbs_type_i is
        when prbs_2_09_1 => if (prbs_sr ( 9 downto 1) =                        "000000000") then  prbs_zero <= '1';  end if;
        when prbs_2_11_1 => if (prbs_sr (11 downto 1) =                     "000000000000") then  prbs_zero <= '1';  end if;
        when prbs_2_15_1 => if (prbs_sr (15 downto 1) =                 "0000000000000000") then  prbs_zero <= '1';  end if;
        when prbs_2_20_1 => if (prbs_sr (20 downto 1) =            "000000000000000000000") then  prbs_zero <= '1';  end if;
        when prbs_2_20_2 => if (prbs_sr (20 downto 1) =            "000000000000000000000") then  prbs_zero <= '1';  end if;
        when prbs_2_23_1 => if (prbs_sr (23 downto 1) =         "000000000000000000000000") then  prbs_zero <= '1';  end if;
        when prbs_2_29_1 => if (prbs_sr (29 downto 1) =   "000000000000000000000000000000") then  prbs_zero <= '1';  end if;
        when prbs_2_31_1 => if (prbs_sr (31 downto 1) = "00000000000000000000000000000000") then  prbs_zero <= '1';  end if;
        when others      =>                                                                       prbs_zero <= '0';
      end case;

    end if;

  end if;
end process;

-- ********************************************************************************
-- * bit pattern comparator                                                       *
-- ********************************************************************************

pat_chk : process (clk, reset)
begin
  if (reset = '1') then

    pat_bit_i <= '0';
    pat_ref   <= (others => '0');
    pat_in    <= (others => '0');
    pat_cnt   <=  0 ;
    pat_found <= '0';
    pat_err   <= '0';

  elsif rising_edge (clk) then

    -- set new reference pattern
    
    if (prbs_set_pulse = '1') then
      case prbs_type_i is
        when pat_all_0 =>  pat_ref <= pattern_all_0;
        when pat_all_1 =>  pat_ref <= pattern_all_1;
        when pat_alt_s =>  pat_ref <= pattern_alt_s;
        when pat_alt_d =>  pat_ref <= pattern_alt_d;
        when pat_one_0 =>  pat_ref <= pattern_one_0;
        when pat_one_1 =>  pat_ref <= pattern_one_1;
        when pat_two_0 =>  pat_ref <= pattern_two_0;
        when pat_two_1 =>  pat_ref <= pattern_two_1;
        when others    =>  pat_ref <= pattern_all_1;
      end case;
    end if;

    if (clk_en_i = '1') then

      pat_bit_i <= rx_bit_i;

      pat_in <= pat_bit_i & pat_in (7 downto 1);                             -- fill the shift register with received data (lsb first)

      if    (pat_fill = '1') and (pat_ref = pat_in) then  pat_cnt <= 1;      -- pointer counter for register bit
      elsif (pat_cnt  =  7 )                        then  pat_cnt <= 0;
      else                                                pat_cnt <= pat_cnt + 1;
      end if;

      if (pat_fill = '1') and (pat_ref = pat_in)                             -- find the pattern
        then  pat_found <= '1';  
        else  pat_found <= '0';
      end if;

      if (pat_test = '1') and (pat_bit_i /= pat_ref (pat_cnt))               -- compare the pattern
        then  pat_err <= '1';
        else  pat_err <= '0';
      end if;

    end if;

  end if;
end process;

-- ********************************************************************************
-- * error history and error counter                                              *
-- ********************************************************************************

-- the synchronization should be lost, when the error rate exceeds 0.2
-- to detect this level, the bit errors during the last 128 received bits are memorized
-- a flag is set, if there are more than 25 errors

err_sum : process (clk, reset)
begin
  if (reset = '1') then

    err_sr   <= (others => '0');
    err_cnt  <=  0;
    err_flag <= '0';

  elsif rising_edge (clk) then

    if (clk_en_i = '0') then  -- wait
    
      null;  

    elsif (err_test = '0') then  -- reset all

      err_sr   <= (others => '0');
      err_cnt  <=  0;
      err_flag <= '0';

    else  -- (err_test = '1')  -- count errors 

      err_sr (127 downto 1) <= err_sr (126 downto 0);

      if    (prbs_err = '1') then  err_sr (0) <= '1';
      elsif (pat_err  = '1') then  err_sr (0) <= '1';
      else                         err_sr (0) <= '0';
      end if;

      if    (err_sr (127) = '1') and ((prbs_err = '1') or (pat_err = '1')) then
        err_cnt <= err_cnt;      -- a memorized error less and a new error additional : counter is unchanged
      elsif (err_sr (127) = '1') then
        err_cnt <= err_cnt - 1;  -- a memorized error less : counter decrement
      elsif ((prbs_err = '1') or (pat_err = '1')) then
        err_cnt <= err_cnt + 1;  -- a new error additional : counter increment
      else
        err_cnt <= err_cnt;      -- no change
      end if;

      if (err_cnt > 25)
        then  err_flag <= '1';
        else  err_flag <= '0';
      end if;

    end if;

  end if;
end process;

-- ********************************************************************************
-- * output signals                                                               *
-- ********************************************************************************

out_sign : process (clk, reset)
begin
  if (reset = '1') then

    syn_state <= '0';  -- synchronisation state output
    syn_los   <= '0';  -- sync loss signaling output
    bit_err   <= '0';  -- biterror signaling output
    clk_err   <= '0';  -- clockerror (bitslip) signaling output

  elsif rising_edge (clk) then

    -- synchronisation state output : state machine = syn_state  : sync'ed on received data
    
    if (prbs_state = sync_state)
      then  syn_state <= '1';
      else  syn_state <= '0';
    end if;

    -- sync loss signaling output : pulse when sync is lost
    
    if (prbs_state = sync_state) and (clk_en_i = '1') and (err_flag = '1')
      then  syn_los <= '1';
      else  syn_los <= '0';
    end if;

    -- bit error signaling output : pulse per bit error
    -- only bit errors are signaled, who are not involved in a sync loss event
    -- for this reason, the bit error signaling pin is the output of the error memory shift register
    
    if (prbs_state = sync_state) and (clk_en_i = '1') and (err_sr (127) = '1')
      then  bit_err <= '1';
      else  bit_err <= '0';
    end if;

--    clock error signaling output : pulse per clock error
--    if (prbs_state = sync_state) and (clk_en_i = '1') and (err_flag = '1')  
--      then  clk_err <= '1';
--      else  clk_err <= '0';
--    end if;

    clk_err <= '0';

  end if;
end process;

-- ********************************************************************************

end prbs_rx_ser;

-- ********************************************************************************
-- list of changes
-- ===============
-- date        version  name  change
-- 06.06.2004  1.0      thg   creation
-- 13.06.2004  1.1      thg   korrection : pattern 2^20-1 bit change after 14 similar bits
-- 19.06.2004  1.2      thg   modification : all in english
-- 26.06.2004  1.3      thg   addition : check if the prbs shift register is filled only with zeros
-- 26.09.2004  1.4      thg   addition : reset state machine if the prbs shift register is filled only with zeros
-- ********************************************************************************
