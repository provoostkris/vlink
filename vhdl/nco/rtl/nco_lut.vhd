------------------------------------------------------------------------------
--  simple nco_lut design
--  rev. 1.0 : 2025 Provoost Kris
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity nco_lut is
  generic (
    g_lut  : natural range 8  to 16 := 10;
    g_res  : natural range 8  to 16 := 14
  );
  port(
    clk     : in std_logic;
    rst     : in std_logic;
    phase   : in std_logic_vector(g_lut-1 downto 0);
    nco     : out std_logic_vector(g_res-1 downto 0)
  );
end nco_lut;

architecture behavioral of nco_lut is

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

    signal accum   : unsigned(g_lut-1 downto 0);
    signal res     : signed(g_res-1 downto 0);

begin

  -- accumulator
    process(clk, rst)
    begin
        if rst = '1' then
            accum <= (others => '0');
        elsif rising_edge(clk) then
            accum <= accum + unsigned(phase);
        end if;
    end process;
    
    
  -- lookup
    process(clk, rst)
    begin
        if rst = '1' then
            res <= (others => '0');
        elsif rising_edge(clk) then
            res <= to_signed(c_rom(to_integer(accum)),g_res);
        end if;
    end process;

  -- type conversion
    nco <= std_logic_vector(res);

end behavioral;