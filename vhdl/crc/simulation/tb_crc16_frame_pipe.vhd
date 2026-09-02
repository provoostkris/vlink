library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_crc16_frame_pipe is
  generic (
    g_input_pipe  : string := "\\.\pipe\ccsds_crc16_in";
    g_output_pipe : string := "\\.\pipe\ccsds_crc16_out"
  );
end entity tb_crc16_frame_pipe;

architecture behavioral of tb_crc16_frame_pipe is

  constant c_clock_period : time := 20 ns;
  constant c_new_frame    : string(1 to 2) := "--";

  signal clk         : std_logic := '0';
  signal a_rst       : std_logic := '0';
  signal s_rst       : std_logic := '0';
  signal data_in     : std_logic_vector(7 downto 0) := (others => '0');
  signal data_valid  : std_logic := '0';
  signal frame_start : std_logic := '0';
  signal frame_end   : std_logic := '0';
  signal crc_ready   : std_logic;
  signal crc_out     : std_logic_vector(15 downto 0);

  file input_pipe  : text;
  file output_pipe : text;

  function hexchar_to_slv(c : character) return std_logic_vector is
    variable v_result : std_logic_vector(3 downto 0);
  begin
    case c is
      when '0' => v_result := "0000";
      when '1' => v_result := "0001";
      when '2' => v_result := "0010";
      when '3' => v_result := "0011";
      when '4' => v_result := "0100";
      when '5' => v_result := "0101";
      when '6' => v_result := "0110";
      when '7' => v_result := "0111";
      when '8' => v_result := "1000";
      when '9' => v_result := "1001";
      when 'A' | 'a' => v_result := "1010";
      when 'B' | 'b' => v_result := "1011";
      when 'C' | 'c' => v_result := "1100";
      when 'D' | 'd' => v_result := "1101";
      when 'E' | 'e' => v_result := "1110";
      when 'F' | 'f' => v_result := "1111";
      when others => v_result := "XXXX";
    end case;
    return v_result;
  end function;

  function is_hex_character(c : character) return boolean is
  begin
    return (c >= '0' and c <= '9') or
           (c >= 'A' and c <= 'F') or
           (c >= 'a' and c <= 'f');
  end function;

begin

  clk <= not clk after c_clock_period / 2;

  uut : entity work.ccsds_crc16_frame
    port map (
      clk         => clk,
      a_rst       => a_rst,
      s_rst       => s_rst,
      data_in     => data_in,
      data_valid  => data_valid,
      frame_start => frame_start,
      frame_end   => frame_end,
      crc_ready   => crc_ready,
      crc_out     => crc_out
    );

  pipe_process : process
    variable v_status       : file_open_status;
    variable v_line_in      : line;
    variable v_line_out     : line;
    variable v_token        : string(1 to 2);
    variable v_hex_byte     : std_logic_vector(7 downto 0);
    variable v_frame_count  : natural := 0;
  begin
    file_open(v_status, input_pipe, g_input_pipe, read_mode);
    assert v_status = open_ok
      report "Unable to open input pipe: " & g_input_pipe
      severity failure;

    file_open(v_status, output_pipe, g_output_pipe, write_mode);
    assert v_status = open_ok
      report "Unable to open output pipe: " & g_output_pipe
      severity failure;

    a_rst <= '1';
    wait for c_clock_period;
    a_rst <= '0';
    s_rst <= '1';
    wait until rising_edge(clk);
    s_rst <= '0';

    while not endfile(input_pipe) loop
      readline(input_pipe, v_line_in);
      read(v_line_in, v_token);

      if v_token = c_new_frame then
        wait until rising_edge(clk);
        frame_end <= '1';
        wait until rising_edge(clk);
        frame_end <= '0';

        wait until crc_ready = '1' for 100 ns;
        assert crc_ready = '1'
          report "CRC result timeout"
          severity error;

        v_frame_count := v_frame_count + 1;
        write(v_line_out, string'("FRAME "));
        write(v_line_out, v_frame_count);
        write(v_line_out, string'(" CRC "));
        hwrite(v_line_out, crc_out);
        writeline(output_pipe, v_line_out);

        wait until rising_edge(clk);
        frame_start <= '1';
        wait until rising_edge(clk);
        frame_start <= '0';
      else
        assert is_hex_character(v_token(1)) and
               is_hex_character(v_token(2))
          report "Input pipe record is not a two-digit hexadecimal byte"
          severity error;

        v_hex_byte := hexchar_to_slv(v_token(1)) &
                      hexchar_to_slv(v_token(2));
        wait until rising_edge(clk);
        data_in    <= v_hex_byte;
        data_valid <= '1';
        wait until rising_edge(clk);
        data_valid <= '0';
      end if;
    end loop;

    file_close(input_pipe);
    file_close(output_pipe);
    assert false report "PIPE TEST COMPLETED" severity failure;
  end process;

end architecture behavioral;
