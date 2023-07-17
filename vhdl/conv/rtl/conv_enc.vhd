------------------------------------------------------------------------------
--  convolutional encoder
--  rev. 1.0 : 2023 Provoost Kris
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.pckg_conv_enc.all;

entity conv_enc is
	port(
      clk             :  in std_logic;
      rst             :  in std_logic;
      stream_rx_dat   :  in std_logic;
      stream_rx_ena   :  in std_logic;
      stream_tx_dat   :  out std_logic_vector(1 downto 0);
      stream_tx_ena   :  out std_logic
	);
end entity conv_enc;

architecture rtl of conv_enc is

	signal   delay_i           :std_logic_vector(6 downto 0);
	signal   C1_i              :std_logic;
	signal   C2_i              :std_logic;

begin

p_main: process(rst, clk) is
begin
   if rst = '1' then
      delay_i          <= (others => '0');
      C1_i             <= '0';
      C2_i             <= '0';
   elsif rising_edge(clk) then
      if stream_rx_ena = '1' then
      -- normal delay line
        delay_i <= delay_i(delay_i'high-1 downto 0) & stream_rx_dat;
      -- C1 taps
      C1_i  <=  delay_i(0) xor
                delay_i(1) xor
                delay_i(2) xor
                delay_i(3) xor
                -- delay_i(4) xor
                -- delay_i(5) xor
                delay_i(6) ;
      -- C2 taps
      C2_i  <=  delay_i(0) xor
                -- delay_i(1) xor
                delay_i(2) xor
                delay_i(3) xor
                -- delay_i(4) xor
                delay_i(5) xor
                delay_i(6) ;
      end if;
   end if;
end process;

p_output: process(rst, clk) is
begin
   if rst = '1' then
      stream_tx_dat          <= (others => '0');
      stream_tx_ena          <= '0';
   elsif rising_edge(clk) then
      stream_tx_dat          <= not C2_i & C1_i;
      stream_tx_ena          <= stream_rx_ena;
   end if;
end process;



end architecture rtl;