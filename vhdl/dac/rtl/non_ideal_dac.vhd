library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- ==========================================================================
-- non_ideal_dac.vhd
--
-- Behavioral simulation model of a non-ideal Digital-to-Analog Converter (DAC).
-- Produces a real-valued `vout` by combining an ideal DAC transfer with
-- simulation-only non-ideal effects: random noise and a static INL curve.
--
-- Generics:
--   N_BITS            : integer  - DAC resolution (bits)
--   V_REF             : real     - reference voltage (volts)
--   MAX_NOISE_VOLTAGE : real     - peak noise amplitude (volts)
--   MAX_INL_ERROR     : real     - max INL as fraction of FSR (0..1)
--
-- Ports:
--   clk  : in  std_logic                     - clock (rising edge updates)
--   din  : in  std_logic_vector(N_BITS-1 downto 0)
--   vout : out real                           - analog output (simulation)
--
-- Notes:
--   - Uses `real` arithmetic and `ieee.math_real.uniform` => simulation only
--   - Non-linearity modeled by a sine-shaped INL curve for demonstration
--   - Random seed variables are local to the process and produce deterministic
--     sequences unless changed; re-seed externally for different runs.
-- ==========================================================================

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

    -- Function: non_linearity_error
    -- Purpose: Compute a static non-linearity (INL-like) error for the given
    --          digital input value. The result is an error term in units of
    --          fraction of full-scale (i.e., multiplied by V_REF later).
    -- Parameters:
    --   din_val  : integer - numeric value of the digital input
    --   max_err  : real    - maximum error magnitude as fraction of FSR
    --   num_bits : integer - number of DAC bits (used to compute max value)
    -- Returns:
    --   real - fractional error in range approximately [-max_err, +max_err]
    -- Implementation note: Uses a sine-shaped curve to produce an S-shaped
    -- distortion profile. This is a simple model for demonstration; replace
    -- with measured INL data for more accurate simulation.
    function non_linearity_error (
        din_val : in integer;
        max_err : in real;
        num_bits : in integer
    ) return real is
        constant max_val : real := real(2**num_bits);
        variable error_val : real;
    begin
        error_val := max_err * sin(real(din_val) / max_val * 2.0 * 3.14159);
        return error_val;
    end function;

    -- Signals hold intermediate analog quantities (simulation only)
    signal ideal_vout               : real := 0.0; -- ideal DAC transfer result
    signal noise_component          : real := 0.0; -- random noise (volts)
    signal non_linearity_component  : real := 0.0; -- INL contribution (volts)


begin

    -- Ideal DAC calculation (combinational)
    -- Computes the ideal analog output based on the unsigned digital input
    -- and the reference voltage. This uses `real` arithmetic and is
    -- non-synthesizable; intended for behavioral simulation only.
    process (din)
        variable d_in_val : real;
    begin
        d_in_val := real(to_integer(unsigned(din)));
        ideal_vout <= V_REF * (d_in_val / (2.0**N_BITS));
    end process;

        -- Process: update random noise and INL component on clock edge
        -- Notes:
        --  - Uses `uniform` from `ieee.math_real` to generate a pseudo-random
        --    value in [0,1). The code remaps it to [-1,1) before scaling.
        --  - `seed_1` and `seed_2` are local variables; keep them deterministic
        --    for reproducible simulation runs, or re-seed for varied runs.
        process (clk)
            -- Random seeds (positive required by `uniform`); these control the
            -- generated pseudo-random sequence. Change values to change sequence.
            variable seed_1 : positive := 1;
            variable seed_2 : positive := 2;
            variable rand_real : real;
        begin
            if rising_edge(clk) then
                -- Generate a new uniform random value and convert to [-1, +1)
                uniform(seed_1, seed_2, rand_real);
                rand_real := (rand_real * 2.0) - 1.0;
                noise_component <= rand_real * MAX_NOISE_VOLTAGE;

                -- Compute non-linearity (fractional) and convert to volts by
                -- multiplying by V_REF. The function returns a fractional error of
                -- FSR; multiplying by V_REF gives an approximate voltage error.
                non_linearity_component <= non_linearity_error(to_integer(unsigned(din)), MAX_INL_ERROR, N_BITS) * V_REF;
            end if;
        end process;

    -- Total output is the sum of ideal, non-linearity, and noise components
    vout <= ideal_vout + noise_component + non_linearity_component;

end architecture behavioral;