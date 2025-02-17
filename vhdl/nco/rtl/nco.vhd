------------------------------------------------------------------------------
--  simple nco design
--  rev. 1.0 : 2025 Provoost Kris
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity nco is
    generic (
        g_lut  : natural range 8  to 16 := 10;
        g_res  : natural range 8  to 16 := 14
    );
    port(
        clk     : in std_logic;
        rst     : in std_logic;
        freq_a  : in std_logic_vector(g_lut-1 downto 0);
        freq_b  : in std_logic_vector(g_lut-1 downto 0);
        nco_m   : out std_logic_vector(g_res-1 downto 0)
    );
end nco;

architecture behavioral of nco is

    type mem_array is array(0 to (2**g_lut)-1) of integer ;

    -- function computes contents of cosine lookup ROM
    function init_rom return mem_array is
      constant Ni       : integer := 2**g_lut;
      constant Nr       : real := real(Ni);
      variable y, x     : real;
      variable v_mem    : mem_array;
    begin
      for k in 0 to Ni-1 loop
        x        := real(k) / Nr;                     -- create fraction over the loop
        y        := sin(2.0 * MATH_PI * x);           -- cosine wave
        v_mem(k) := integer(real(2**(g_res-1)-1)*y);  -- return integer
      end loop;
      return v_mem;
    end function init_rom;

    constant c_rom : mem_array := init_rom;

    signal res_a     : std_logic_vector(g_res-1 downto 0);
    signal res_b     : std_logic_vector(g_res-1 downto 0);
    signal mult      : signed(2*g_res-1 downto 0);

begin


i_nco_a: entity work.nco_lut
  generic map(g_lut  ,  g_res  )
	port map(
      clk             => clk  ,
      rst             => rst  ,
      phase           => freq_a ,
      nco             => res_a
	);
  
i_nco_b: entity work.nco_dsp
  generic map(g_lut  ,  g_res  )
	port map(
      clk             => clk  ,
      rst             => rst  ,
      phase           => freq_b ,
      nco             => res_b
	);
  
    
    mult    <= signed(res_a) * signed(res_b);
    nco_m   <= std_logic_vector(mult(2*g_res-2 downto g_res-1));

end behavioral;