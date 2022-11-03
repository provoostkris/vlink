------------------------------------------------------------------------------
--  logic feedbacks sift register serial stream
--  rev. 1.0 : 2022 Provoost Kris
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.pckg_lfsr.all;

entity lfsr_ser_cfg is 
	port(
      clk             :  in std_logic;
      rst             :  in std_logic;
      taps            :  in std_logic_vector(7 downto 0);
      init            :  in std_logic_vector(7 downto 0);
      load            :  in std_logic;
      delay           :  in std_logic;
      cfg_fsr         :  out std_logic
	);
end entity lfsr_ser_cfg;
 
architecture rtl of lfsr_ser_cfg is
   
	signal   prgm              :std_logic_vector(7 downto 0);
	signal   redu              :std_logic_vector(7 downto 0);
	signal   xord              :std_logic;

begin   
   
p_main: process(rst, clk) is 
begin
   if rst = '1' then
      cfg_fsr          <= '1';
      prgm             <= (others => '1');
   elsif rising_edge(clk) then
      if load = '1' then
         prgm             <= init;
      elsif delay = '1' then
         prgm( 6 downto 0)             <= prgm( 7 downto 1);
         prgm( 7 )                     <= xord;
         cfg_fsr                       <= prgm(0);
      end if;
   end if;
end process;

-- Reduce the logic vector to only it use full data
-- Create the major XOR gate to reduce all feedbacks in a single signal  
      redu                          <= prgm and taps;    
      xord                          <= xor_reduce(redu);
      
end architecture rtl;