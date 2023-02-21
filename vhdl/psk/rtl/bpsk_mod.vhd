------------------------------------------------------------------------------
--  bipolar phase shift keying
--  rev. 1.0 : 2023 Provoost Kris
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

library work;
use work.pckg_bpsk.all;

entity bpsk is
	generic(
      g_resolution    :  in positive range 4 to 15 := 8
	  );
	port(
      clk             :  in  std_logic;
      rst             :  in  std_logic;
      i_scale         :  in  std_logic_vector(g_resolution-1 downto 0);
      q_scale         :  in  std_logic_vector(g_resolution-1 downto 0);
      stream_rx_dat   :  in  std_logic;
      stream_rx_ena   :  in  std_logic;
      stream_tx_dat   :  out std_logic_vector(2*g_resolution-1 downto 0);
      stream_tx_ena   :  out std_logic
	);
end entity bpsk;

architecture rtl of bpsk is

  --! constants
  
  --! signals
	signal   sign_i			: std_logic;
  signal   phase_i		: signed(stream_tx_dat'range);
	alias	   i_phase		: signed(g_resolution-1 downto 0) is phase_i(g_resolution-1 downto 0);
	alias	   q_phase		: signed(g_resolution-1 downto 0) is phase_i(phase_i'high downto g_resolution);
	

begin

--! define the sign value and map the phases
sign_i 	<= not stream_rx_dat;
i_phase	<= signed(i_scale) when sign_i = '1' else signed(not(i_scale));
q_phase	<= signed(q_scale) when sign_i = '1' else signed(not(q_scale));

--! map the input to a phase
p_main: process(rst, clk) is
begin
   if rst = '1' then
      stream_tx_dat          <= ( others => '0');
      stream_tx_ena          <= '0';
   elsif rising_edge(clk) then
      stream_tx_dat          <= std_logic_vector(i_phase) & std_logic_vector(q_phase);
      stream_tx_ena          <= stream_rx_ena ;
   end if;
end process;


end architecture rtl;
