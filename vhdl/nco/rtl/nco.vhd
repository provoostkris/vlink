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
        g_style : natural range 0  to  2 :=  2;
        g_lut   : natural range 8  to 16 := 10;
        g_res   : natural range 8  to 16 := 14
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

    signal res_a     : std_logic_vector(g_res-1 downto 0);
    signal res_b     : std_logic_vector(g_res-1 downto 0);
    signal mult      : signed(2*g_res-1 downto 0);

begin

gen_real: if g_style = 0 generate
  i_nco_a: entity work.nco_real
    generic map(g_lut  ,  g_res  )
    port map(
        clk             => clk  ,
        rst             => rst  ,
        phase           => freq_a ,
        nco             => res_a
    );

  i_nco_b: entity work.nco_real
  generic map(g_lut  ,  g_res  )
  port map(
      clk             => clk  ,
      rst             => rst  ,
      phase           => freq_b ,
      nco             => res_b
  );
end generate gen_real;


gen_flt32: if g_style = 1 generate
  i_nco_a: entity work.nco_flt32
    generic map(g_lut  ,  g_res  )
    port map(
        clk             => clk  ,
        rst             => rst  ,
        phase           => freq_a ,
        nco             => res_a
    );

  i_nco_b: entity work.nco_flt32
  generic map(g_lut  ,  g_res  )
  port map(
      clk             => clk  ,
      rst             => rst  ,
      phase           => freq_b ,
      nco             => res_b
  );
end generate gen_flt32;

gen_lut: if g_style = 2 generate
  i_nco_a: entity work.nco_lut
  generic map(g_lut  ,  g_res  )
  port map(
      clk             => clk  ,
      rst             => rst  ,
      phase           => freq_a ,
      nco             => res_a
  );

  i_nco_b: entity work.nco_lut
  generic map(g_lut  ,  g_res  )
  port map(
    clk             => clk  ,
    rst             => rst  ,
    phase           => freq_b ,
    nco             => res_b
  );
end generate gen_lut;

    mult    <= signed(res_a) * signed(res_b);
    nco_m   <= std_logic_vector(mult(2*g_res-2 downto g_res-1));

end behavioral;