library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;


entity tb_cordic is
end tb_cordic;

architecture Behavioral of tb_cordic is

    -- Signals for driving and observing the DUT
    signal clk     : STD_LOGIC := '0';
    signal reset   : STD_LOGIC := '0';
    signal angle   : SIGNED(15 downto 0);
    signal sine    : SIGNED(15 downto 0);
    signal cosine  : SIGNED(15 downto 0);
    
    signal degrees     : integer range -360 to 360;    
    signal real_deg    : real;
    signal real_rad    : real;
    signal real_sin    : real;
    signal real_cos    : real;

    -- Constants
    constant c_clk_per    : time    := 10 ns;
    constant c_sgn_bits   : integer := 1;
    constant c_dec_bits   : integer := 1;
    constant c_frc_bits   : integer := 14;
    

  -- Converts degrees to fixed-point radians (16-bit signed)
  function deg_to_rad_fixed(angle_deg : integer) return signed is
      constant SCALE  : real := 3.14159265 * 2.0**c_frc_bits / 180.0;
      variable result : integer;
  begin
      result := integer((real(angle_deg) * SCALE));
      return to_signed(result, 16);
  end function;
  
  procedure log_test_id(test_id : in string) is
      variable L : line;
  begin
      write(L, string'("=== STARTING TEST ID: "));
      write(L, test_id);
      write(L, string'(" ==="));
      writeline(output, L);
  end procedure;

  procedure log_test_step(signal_name : in string; step_desc : in string; t : in time) is
      variable L : line;
  begin
      write(L, string'("[" & time'image(t) & "] "));
      write(L, string'("TEST STEP: "));
      write(L, signal_name);
      write(L, string'(" - "));
      write(L, step_desc);
      writeline(output, L);
  end procedure;

begin

real_deg <= real(degrees);
real_rad <= real(to_integer(angle)  ) / 2.0**c_frc_bits;
real_sin <= real(to_integer(sine)  )  / 2.0**c_frc_bits;
real_cos <= real(to_integer(cosine))  / 2.0**c_frc_bits;
  
    -- Instantiate the CORDIC module
    uut: entity work.cordic
        Port map (
            clk     => clk,
            reset   => reset,
            angle   => angle,
            sine    => sine,
            cosine  => cosine
        );

    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for c_clk_per / 2;
            clk <= '1';
            wait for c_clk_per / 2;
        end loop;
    end process;

    -- Stimulus process
    stim_proc: process
    begin

      
        
        log_test_id("TC_001 : Test all angles");
        log_test_step("Reset", "pull reset line", now);
        wait until rising_edge(clk);
        reset <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        reset <= '0';
        log_test_step("loop", "go over all angles", now);
        for i in -90 to 90 loop
          angle   <= deg_to_rad_fixed(i);
          degrees <= i;
          wait until rising_edge(clk);
        end loop;

        -- End simulation
        wait for c_clk_per * 20;
        wait until rising_edge(clk);
        report "Simulation finished." severity failure;
        wait;
    end process;

end Behavioral;
