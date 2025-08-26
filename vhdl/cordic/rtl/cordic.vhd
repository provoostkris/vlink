library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cordic is
    Port (
        clk     : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        angle   : in  SIGNED(15 downto 0);
        sine    : out SIGNED(15 downto 0);
        cosine  : out SIGNED(15 downto 0)
    );
end cordic;

architecture Behavioral of cordic is
    constant ITER : integer := 16;

    type vec_array is array(0 to ITER) of SIGNED(15 downto 0);
    signal x_pipe, y_pipe, z_pipe : vec_array;

    -- CORDIC gain compensation factor (approx. 0.6072528 * 2**14)
    constant c_K : integer := 9949;

    -- Precomputed arctangent values (fixed-point)
    constant atan_table : vec_array := (
      to_signed(12477, 16),
      to_signed(7571, 16),
      to_signed(4012, 16),
      to_signed(2037, 16),
      to_signed(1022, 16),
      to_signed(511, 16),
      to_signed(255, 16),
      to_signed(127, 16),
      to_signed(63, 16),
      to_signed(31, 16),
      to_signed(15, 16),
      to_signed(7, 16),
      to_signed(3, 16),
      to_signed(1, 16),
      to_signed(0, 16),
      to_signed(0, 16),
      to_signed(0, 16)
    );

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                x_pipe <= ( others => ( others => '0'));
                y_pipe <= ( others => ( others => '0'));
                z_pipe <= ( others => ( others => '0'));
            else
                x_pipe(0) <= to_signed(c_K, 16); -- Pre-scaled K factor
                y_pipe(0) <= to_signed(0, 16);
                z_pipe(0) <= angle;
                for i in 0 to ITER-1 loop
                    if z_pipe(i)(15) = '0' then
                        x_pipe(i+1) <= x_pipe(i) - shift_right(y_pipe(i), i);
                        y_pipe(i+1) <= y_pipe(i) + shift_right(x_pipe(i), i);
                        z_pipe(i+1) <= z_pipe(i) - atan_table(i);
                    else
                        x_pipe(i+1) <= x_pipe(i) + shift_right(y_pipe(i), i);
                        y_pipe(i+1) <= y_pipe(i) - shift_right(x_pipe(i), i);
                        z_pipe(i+1) <= z_pipe(i) + atan_table(i);
                    end if;
                end loop;
            end if;
        end if;
    end process;

    cosine <= x_pipe(ITER);
    sine   <= y_pipe(ITER);

end Behavioral;
