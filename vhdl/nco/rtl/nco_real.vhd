------------------------------------------------------------------------------
--  simple nco_real design
--  rev. 1.0 : 2025 Provoost Kris
------------------------------------------------------------------------------

-- use ieee.std_logic_arith.all;
-- use ieee.std_logic_unsigned.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity nco_real is
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
end nco_real;

architecture rtl of nco_real is

  -- scale factor one less for signed
  constant c_scale    : real := 2.0**(g_res-1)-1.0;

  signal accum      : signed(g_lut-1 downto 0);
  signal phase_val  : real;
  signal angle      : real;
  signal sine_val   : real;

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

  -- mulitpliers
  process(clk, rst)
  begin
    if rst = '1' then
      phase_val   <= 0.0;
      angle       <= 0.0;
      sine_val    <= 0.0;
      nco         <= (others => '0');
    elsif rising_edge(clk) then
      phase_val   <= real(to_integer(accum)) * 2.0 * MATH_PI;
      angle       <= phase_val / 2.0**g_lut ;

      -- Taylor series expansion for sin(x) = x - x^3/3! + x^5/5! - x^7/7! + ...
      sine_val    <=  angle
                      - (angle**3  / 6.0)
                      + (angle**5  / 120.0)
                      - (angle**7  / 5040.0)
                      + (angle**9  / 362880.0)
                      - (angle**11 / 39916800.0)
                      ;
      nco         <= std_logic_vector(to_signed(integer(sine_val * c_scale ), g_res));
    end if;
  end process;
end rtl;
