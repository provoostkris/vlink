------------------------------------------------------------------------------
--  bipolar phase shift keying
--  rev. 1.0 : 2023 Provoost Kris
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

library work;
use work.pckg_bpsk_demod.all;

entity bpsk_demod is
	generic(
      g_resolution    :  in positive range 4 to 15 := 8
	  );
	port(
      clk             :  in  std_logic;
      rst             :  in  std_logic;
      stream_rx_dat   :  in  std_logic_vector(2*g_resolution-1 downto 0);
      stream_rx_ena   :  in  std_logic;
      stream_tx_dat   :  out std_logic;
      stream_tx_ena   :  out std_logic
	);
end entity bpsk_demod;

architecture rtl of bpsk_demod is

  --! constants

  --! signals
	signal i_phase		: signed(g_resolution-1 downto 0) ;
	signal q_phase		: signed(g_resolution-1 downto 0) ;

begin

--! define the sign value and map the phases
i_phase		<= signed(stream_rx_dat(g_resolution-1 downto 0));
q_phase		<= signed(stream_rx_dat(stream_rx_dat'high downto g_resolution));

--! map the phase to an binary
p_main: process(rst, clk) is
begin
   if rst = '1' then
      stream_tx_dat          <= '0';
      stream_tx_ena          <= '0';
   elsif rising_edge(clk) then
      -- note that for bpsk mapping it is sufficient to take the sign bit ooly
      stream_tx_dat          <= i_phase(i_phase'high);
      stream_tx_ena          <= stream_rx_ena ;
   end if;
end process;


end architecture rtl;