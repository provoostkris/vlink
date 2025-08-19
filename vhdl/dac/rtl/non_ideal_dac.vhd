library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity non_ideal_dac is
    generic (
        N_BITS  : integer := 8;
        V_REF   : real := 5.0;
        MAX_NOISE_VOLTAGE : real := 0.005; -- 5 mV peak noise
        MAX_INL_ERROR : real := 0.01 -- 1% of FSR
    );
    port (
        clk  : in std_logic;
        din  : in std_logic_vector(N_BITS-1 downto 0);
        vout : out real
    );
end entity non_ideal_dac;

architecture behavioral of non_ideal_dac is

    -- Function to model non-linearity based on input value
    function non_linearity_error (
        din_val : in integer;
        max_err : in real;
        num_bits : in integer
    ) return real is
        -- A simple sine function can model a common S-shaped INL curve
        constant max_val : real := real(2**num_bits);
        variable error_val : real;
    begin
        error_val := max_err * sin(real(din_val) / max_val * 2.0 * 3.14159);
        return error_val;
    end function;

    signal ideal_vout               : real := 0.0;
    signal noise_component          : real := 0.0;
    signal non_linearity_component  : real := 0.0;


begin

    -- Ideal DAC calculation
    process (din)
        variable d_in_val : real;
    begin
        d_in_val := real(to_integer(unsigned(din)));
        ideal_vout <= V_REF * (d_in_val / (2.0**N_BITS));
    end process;

    -- Noise and Non-linearity components
    process (clk)
      -- Random seeds
      variable seed_1 : positive := 1;
      variable seed_2 : positive := 2;
      variable rand_real : real;
    begin
      if rising_edge(clk) then
        -- Update noise component on clock edge
        
        uniform(seed_1, seed_1, rand_real);
        rand_real := (rand_real * 2.0) - 1.0;
        noise_component <= rand_real * MAX_NOISE_VOLTAGE;

        -- Update non-linearity component
        non_linearity_component <= non_linearity_error(to_integer(unsigned(din)), MAX_INL_ERROR, N_BITS) * V_REF;
      end if;
    end process;

    -- Total output is the sum of ideal, non-linearity, and noise components
    vout <= ideal_vout + noise_component + non_linearity_component;

end architecture behavioral;