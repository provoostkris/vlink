library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity tb_crc16_frame is
end tb_crc16_frame;

architecture Behavioral of tb_crc16_frame is


    -- Constants
    signal c_new_frame :  string(1 to 2) := "--";

    -- Signals
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '0';
    signal data_in    : std_logic_vector(7 downto 0);
    signal data_valid : std_logic := '0';
    signal frame_start: std_logic := '0';
    signal frame_end  : std_logic := '0';
    signal crc_ready  : std_logic;
    signal crc_out    : std_logic_vector(15 downto 0);

    -- File I/O
    file input_file  : text open read_mode is "frame_data.txt";
    file output_file : text open write_mode is "crc_result.txt";

  function hexchar_to_slv(c : character) return std_logic_vector is
      variable result : std_logic_vector(3 downto 0);
  begin
      case c is
          when '0' => result := "0000";
          when '1' => result := "0001";
          when '2' => result := "0010";
          when '3' => result := "0011";
          when '4' => result := "0100";
          when '5' => result := "0101";
          when '6' => result := "0110";
          when '7' => result := "0111";
          when '8' => result := "1000";
          when '9' => result := "1001";
          when 'A' | 'a' => result := "1010";
          when 'B' | 'b' => result := "1011";
          when 'C' | 'c' => result := "1100";
          when 'D' | 'd' => result := "1101";
          when 'E' | 'e' => result := "1110";
          when 'F' | 'f' => result := "1111";
          when others => result := "XXXX"; -- Invalid character
      end case;
      return result;
  end function;

begin

    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for 10 ns;
        clk <= '1';
        wait for 10 ns;
    end process;

    -- DUT instantiation
    uut: entity work.ccsds_crc16_frame
        port map (
            clk        => clk,
            reset      => reset,
            data_in    => data_in,
            data_valid => data_valid,
            frame_start=> frame_start,
            frame_end  => frame_end,
            crc_ready  => crc_ready,
            crc_out    => crc_out
        );

    -- Test process
    test_process : process
      variable line_in : line;
      variable line_out: line;
      variable hex_val : std_logic_vector(7 downto 0);
      variable frame_count : integer := 0;
      variable timestamp   : time;
      -- variable token       : string(1 to 8);
      variable token       : string(1 to 2);

      begin
          reset <= '1';
          wait for 20 ns;
          reset <= '0';

          while not endfile(input_file) loop
              readline(input_file, line_in);
              read(line_in, token);
              assert false report " read from file : " & token severity note;
              
              if token = c_new_frame then

                  assert false report " end of frame detected" severity note;
                  wait until rising_edge(clk);
                  frame_end <= '1';
                  wait until rising_edge(clk);
                  frame_end <= '0';

                  -- Wait for CRC
                  assert false report " wait for CRC " severity note;
                  wait until crc_ready = '1' for 100 ns;
                  if crc_ready = '1' then
                  
                    -- Write CRC with timestamp
                    frame_count := frame_count + 1;
                    timestamp := now;

                    write(line_out, string'("Frame "));
                    write(line_out, frame_count);
                    write(line_out, string'(" @ "));
                    write(line_out, timestamp);
                    write(line_out, string'(" CRC: "));
                    hwrite(line_out, crc_out);
                    writeline(output_file, line_out);

                    -- Prepare for next frame
                    wait until rising_edge(clk);
                    frame_start <= '1';
                    wait until rising_edge(clk);
                    frame_start <= '0';
                    
                  else
                  
                    write(line_out, string'("Frame processed , however CRC was to late"));
                    writeline(output_file, line_out);
                    
                  end if;

              else
                  -- Convert token to hex
                  -- hex_val := std_logic_vector(to_unsigned(to_integer(image'VALUE(token)), 8));
                  hex_val := hexchar_to_slv(token(1)) & hexchar_to_slv(token(2)) ;

                  wait until rising_edge(clk);
                  data_in <= hex_val;
                  data_valid <= '1';
                  wait until rising_edge(clk);
                  data_valid <= '0';

              end if;
          end loop;


          wait for 20 ns;
          assert false report "TEST COMPLETED" severity failure ;

    end process;

end Behavioral;