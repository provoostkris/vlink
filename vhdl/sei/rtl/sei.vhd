------------------------------------------------------------------------------
--  systematic error insertion
--  rev. 1.0 : 2022 Provoost Kris
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use ieee.std_logic_misc.xnor_reduce;

library work;
use work.pckg_sei.all;

entity sei is
	port(
      clk             :  in std_logic;
      rst             :  in std_logic;
      ratio           :  in std_logic_vector(7 downto 0);
      stream_rx_dat   :  in std_logic;
      stream_rx_ena   :  in std_logic;
      stream_tx_dat   :  out std_logic;
      stream_tx_ena   :  out std_logic
	);
end entity sei;

architecture rtl of sei is

  --! constants
  constant c_zero                 : unsigned(ratio'range) := ( others => '0');
  
  --! signals
	signal   error_i                : std_logic;
	signal   err_cnt_i              : unsigned(7 downto 0);
	signal   err_mod_i              : unsigned(7 downto 0);

begin

--! generate periodic error signal
p_ratio: process(rst, clk) is
begin
   if rst = '1' then
      err_cnt_i   <= ( others => '0');
      err_mod_i   <= ( others => '1');
   elsif rising_edge(clk) then
      err_cnt_i   <= err_cnt_i + x"01";
      case ratio is
        when std_logic_vector(c_zero)  =>
          err_mod_i   <= (others => '1');
        when others  =>
          err_mod_i   <= err_cnt_i mod unsigned(ratio);
      end case;
      case err_mod_i is
        when c_zero  =>
          error_i     <= '1';
        when others  =>
          error_i     <= '0';
      end case;
   end if;
end process;

--! insert the error in the stream
p_main: process(rst, clk) is
begin
   if rst = '1' then
      stream_tx_dat          <= '0';
      stream_tx_ena          <= '0';
   elsif rising_edge(clk) then
      stream_tx_dat          <= stream_rx_dat xor error_i;
      stream_tx_ena          <= stream_rx_ena ;
   end if;
end process;


end architecture rtl;