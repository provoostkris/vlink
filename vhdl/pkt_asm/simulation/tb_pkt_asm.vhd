library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity tb_pkt_asm is end;
architecture sim of tb_pkt_asm is

  constant CLK_PERIOD : time := 10 ns;

  -- DUT generics
  constant G_TYPE_WIDTH    : natural := 16;
  constant G_TRAILER_WIDTH : natural := 16;
  constant G_MAX_BYTES     : natural := 64;

  -- DUT signals
  signal clk              : std_logic := '0';
  signal rst_n            : std_logic := '0';

  signal s_tdata          : std_logic_vector(7 downto 0);
  signal s_tvalid         : std_logic := '0';
  signal s_tready         : std_logic;
  signal s_tlast          : std_logic := '0';

  signal packet_type      : std_logic_vector(G_TYPE_WIDTH-1 downto 0);
  signal packet_trailer   : std_logic_vector(G_TRAILER_WIDTH-1 downto 0);
  signal insert_length    : std_logic;

  signal m_tdata          : std_logic_vector(7 downto 0);
  signal m_tvalid         : std_logic;
  signal m_tready         : std_logic := '1';
  signal m_tlast          : std_logic;

  -- Output capture
  type byte_array is array (natural range <>) of std_logic_vector(7 downto 0);
  signal captured_packet : byte_array(0 to 255);
  signal capture_index   : integer;

  -- Test case definition
  type test_case_t is record
    payload        : byte_array(0 to 7);
    payload_len    : integer;
    type_field     : std_logic_vector(G_TYPE_WIDTH-1 downto 0);
    trailer_field  : std_logic_vector(G_TRAILER_WIDTH-1 downto 0);
    insert_length  : std_logic;
  end record;

  type test_array_t is array (natural range <>) of test_case_t;

  constant tests : test_array_t := (
    (payload => (x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08"),
     payload_len => 8,
     type_field => x"AAAA",
     trailer_field => x"1111",
     insert_length => '1'),

    (payload => (x"10", x"20", x"30", x"40", x"50", x"60", x"70", x"80"),
     payload_len => 8,
     type_field => x"BBBB",
     trailer_field => x"2222",
     insert_length => '0'),

    (payload => ( x"10", x"20", x"30", x"40", x"50", x"60", x"70", x"80"),
     payload_len => 8,
     type_field => x"A4C4",
     trailer_field => x"C1C2",
     insert_length => '0'),

    (payload => (x"AA", x"BB", x"CC", x"DD", x"EE", x"FF", x"00", x"11"),
     payload_len => 8,
     type_field => x"1234",
     trailer_field => x"DEAD",
     insert_length => '1')
  );

begin

  -- Clock generation
  clk <= not clk after CLK_PERIOD / 2;

  -- DUT instantiation
  uut: entity work.pkt_asm
    generic map (
      G_TYPE_WIDTH    => G_TYPE_WIDTH,
      G_TRAILER_WIDTH => G_TRAILER_WIDTH,
      G_MAX_BYTES     => G_MAX_BYTES
    )
    port map (
      clk              => clk,
      rst_n            => rst_n,
      s_axis_tdata     => s_tdata,
      s_axis_tvalid    => s_tvalid,
      s_axis_tready    => s_tready,
      s_axis_tlast     => s_tlast,
      packet_type      => packet_type,
      packet_trailer   => packet_trailer,
      insert_length    => insert_length,
      m_axis_tdata     => m_tdata,
      m_axis_tvalid    => m_tvalid,
      m_axis_tready    => m_tready,
      m_axis_tlast     => m_tlast
    );

  -- Stimulus and checking
  process
    variable expected : byte_array(0 to 255);
    variable idx      : integer;
  begin
    rst_n <= '0';
    wait for 50 ns;
    wait until rising_edge(clk);
    rst_n <= '1';
    wait for 20 ns;
    wait until rising_edge(clk);

    for t in tests'range loop
      report "Running test case " & integer'image(t);

      -- Apply config
      packet_type    <= tests(t).type_field;
      packet_trailer <= tests(t).trailer_field;
      insert_length  <= tests(t).insert_length;

      -- Send payload
      for i in 0 to tests(t).payload_len - 1 loop
        s_tdata  <= tests(t).payload(i);
        s_tvalid <= '1';
        s_tlast  <= '1' when i = tests(t).payload_len - 1 else '0';
        wait until rising_edge(clk);
        while s_tready = '0' loop
          wait until rising_edge(clk);
        end loop;
      end loop;
      s_tvalid <= '0';
      s_tlast  <= '0';

      -- Wait for output
      wait until m_tlast = '1';

      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait until rising_edge(clk);

      -- Build expected packet
      idx := 0;

      for i in 0 to G_TYPE_WIDTH/8 - 1 loop
        expected(idx) := tests(t).type_field(i*8+7 downto i*8);
        idx := idx + 1;
      end loop;

      if tests(t).insert_length = '1' then
        expected(idx) := std_logic_vector(to_unsigned(tests(t).payload_len, 16)(15 downto 8));
        idx := idx + 1;
        expected(idx) := std_logic_vector(to_unsigned(tests(t).payload_len, 16)(7 downto 0));
        idx := idx + 1;
      end if;

      for i in 0 to tests(t).payload_len - 1 loop
        expected(idx) := tests(t).payload(i);
        idx := idx + 1;
      end loop;

      for i in 0 to G_TRAILER_WIDTH/8 - 1 loop
        expected(idx) := tests(t).trailer_field(i*8+7 downto i*8);
        idx := idx + 1;
      end loop;

      -- Compare
      report "Checking output packet for " & integer'image(idx) & " bytes";
      for i in 0 to idx - 1 loop
        if captured_packet(i) /= expected(i) then
          report "FAIL: Test " & integer'image(t) & " Byte " & integer'image(i) &
                 " mismatch. Got " & to_hstring(captured_packet(i)) &
                 ", expected " & to_hstring(expected(i)) severity error;
        end if;
      end loop;

      report "PASS: Test " & integer'image(t) & " passed." severity note;
      wait for 100 ns;
      wait until rising_edge(clk);
    end loop;

    report "All tests completed." severity note;
    std.env.stop;
  end process;

  -- Capture output
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
          capture_index <= 0;
      else
        if m_tvalid = '1' and m_tready = '1' then
          captured_packet(capture_index) <= m_tdata;
          if m_tlast = '1' then
            capture_index <= 0;
          else
            capture_index <= capture_index + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

end architecture;
