------------------------------------------------------------------------------
--  simple nco_flt32 design
--  rev. 1.0 : 2025 Provoost Kris
------------------------------------------------------------------------------

-- use ieee.std_logic_arith.all;
-- use ieee.std_logic_unsigned.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.float_pkg.all;

--library ieee_proposed;
--use ieee_proposed.float_pkg.all;

entity nco_flt32 is
  generic (
    g_lut  : natural range 8  to 16 := 10;
    g_res  : natural range 8  to 16 := 14
  );
  port (
    clk    : in std_logic;
    rst    : in std_logic;
    phase  : in std_logic_vector(g_lut-1 downto 0);
    nco    : out std_logic_vector(g_res-1 downto 0)
  );
end nco_flt32;

architecture rtl of nco_flt32 is

  -- scale factor one less for signed
  constant c_scale    : float32 := to_float(2.0**(g_res-1)-1.0);

  signal accum      : signed(g_lut-1 downto 0);
  signal accumf     : float32;
  signal phase_val  : float32;
  signal angle      : float32;
  signal sine_val   : float32;

begin

  -- accumulator
  process(clk, rst)
  begin
      if rst = '1' then
          accum <= (others => '0');
      elsif rising_edge(clk) then
          accum <= accum + signed(phase);
      end if;
  end process;

  -- convert to float
  accumf <= to_float(accum);

  -- mulitpliers
  process(clk, rst)
  begin
    if rst = '1' then
      phase_val   <= to_float(0);
      angle       <= to_float(0);
      sine_val    <= to_float(0);
      nco         <= (others => '0');
    elsif rising_edge(clk) then
      phase_val   <= accumf * to_float(2.0*MATH_PI);
      angle       <= phase_val / to_float(2.0**g_lut) ;

      -- Taylor series expansion for sin(x) = x - x^3/3! + x^5/5! - x^7/7! + - x^9/9! + ...
      sine_val    <=  angle
                      - (to_real(angle)**3  / to_float(6.0))
                      + (to_real(angle)**5  / to_float(120.0))
                      - (to_real(angle)**7  / to_float(5040.0))
                  --    + (to_real(angle)**9  / to_float(62880.0))
                  --    - (to_real(angle)**11 / to_float(39916800.0))
                      ;
      nco         <= std_logic_vector(to_signed(to_integer(sine_val * c_scale ), g_res));
    end if;
  end process;
end rtl;
