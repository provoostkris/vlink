-- Testbench for the non_ideal_dac entity.
-- This testbench applies a ramp from 0 to 2^N_BITS - 1 to the DAC and
-- checks the behavior of the analog output, which includes noise and non-linearities.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Define the testbench entity
entity tb_non_ideal_dac is
end entity tb_non_ideal_dac;

-- Define the testbench architecture
architecture behavioral of tb_non_ideal_dac is

    -- Constants for the testbench
    constant N_BITS_TB            : integer := 8;
    constant V_REF_TB             : real    := 5.0;
    constant MAX_NOISE_VOLTAGE_TB : real    := 0.25;
    constant MAX_INL_ERROR_TB     : real    := 0.10;
    
            
            
    constant CLK_PERIOD: time    := 10 ns;

    -- Signals for connecting to the UUT
    signal clk_tb  : std_logic := '0';
    signal din_tb  : std_logic_vector(N_BITS_TB-1 downto 0);
    signal vout_tb : real;

begin

    -- Instantiate the non_ideal_dac (UUT)
    uut : entity work.non_ideal_dac
        generic map (
            N_BITS            => N_BITS_TB,
            V_REF             => V_REF_TB,
            MAX_NOISE_VOLTAGE => MAX_NOISE_VOLTAGE_TB,
            MAX_INL_ERROR     => MAX_INL_ERROR_TB
        )
        port map (
            clk  => clk_tb,
            din  => din_tb,
            vout => vout_tb
        );

    -- Clock generator process
    -- Generates a clock signal with a 50% duty cycle.
    clk_process : process
    begin
            clk_tb <= '0';
            wait for CLK_PERIOD / 2;
            clk_tb <= '1';
            wait for CLK_PERIOD / 2;
    end process clk_process;

    -- Stimulus process
    -- Applies a ramp signal to the DAC input and observes the output.
    stimulus_process : process
        variable i : integer := 0;
    begin
        -- Start with a reset-like state
        din_tb <= (others => '0');
        wait for 2 * CLK_PERIOD;

        -- Apply a ramp input from 0 to 2^N_BITS - 1
        for i in 0 to (2**N_BITS_TB - 1) loop
            din_tb <= std_logic_vector(to_unsigned(i, N_BITS_TB));
            wait for CLK_PERIOD;
        end loop;

        -- Apply a few specific values to demonstrate different error points
        -- These values are chosen to show the non-linear curve's effect
        din_tb <= std_logic_vector(to_unsigned(2**(N_BITS_TB-1), N_BITS_TB));
        wait for 2 * CLK_PERIOD;

        din_tb <= std_logic_vector(to_unsigned(2**(N_BITS_TB) - 1, N_BITS_TB));
        wait for 2 * CLK_PERIOD;

        -- End the simulation
        report "Simulation finished." severity failure;
        
    end process stimulus_process;

end architecture behavioral;
