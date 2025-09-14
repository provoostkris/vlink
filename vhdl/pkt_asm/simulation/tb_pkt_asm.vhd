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

  signal packet_type      : std_logic_vector(G_TYPE_WIDTH-1 downto 0) := x"ABCD";
  signal packet_trailer   : std_logic_vector(G_TRAILER_WIDTH-1 downto 0) := x"DEAD";
  signal insert_length    : std_logic := '1';

  signal m_tdata          : std_logic_vector(7 downto 0);
  signal m_tvalid         : std_logic;
  signal m_tready         : std_logic := '1';
  signal m_tlast          : std_logic;

  -- Output capture
  type byte_array is array (natural range <>) of std_logic_vector(7 downto 0);
  signal captured_packet : byte_array(0 to 127);
  signal capture_index   : integer := 0;

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

  -- Stimulus process
  process
    variable payload  : byte_array(0 to 4) := (x"11", x"22", x"33", x"44", x"55");
    variable expected : byte_array(0 to 8 + payload'length - 1);
    variable idx : integer := 0;

  begin
    rst_n <= '0';
    wait for 50 ns;
    wait until rising_edge(clk);
    rst_n <= '1';
    wait for 20 ns;
    wait until rising_edge(clk);

    -- Send payload
    for i in payload'range loop
      s_tdata  <= payload(i);
      s_tvalid <= '1';
      if i = payload'high then
        s_tlast  <= '1' ;
      else
        s_tlast  <= '0' ;
      end if;
      wait until rising_edge(clk);
      while s_tready = '0' loop
        wait until rising_edge(clk);
      end loop;
    end loop;
    s_tvalid <= '0';
    s_tlast  <= '0';

    -- Wait for output to complete
    wait until m_tlast = '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);

    -- Check results
    idx := 0 ;
    -- Type field -- FIXME : hard coded for 2 bytes
    expected(idx) := packet_type(1*8-1 downto 0*8);
    idx := idx + 1;
    expected(idx) := packet_type(2*8-1 downto 1*8);
    idx := idx + 1;

    -- Length field (if inserted)
    if insert_length = '1' then
      expected(idx) := std_logic_vector(to_unsigned(payload'length, 16)(15 downto 8));
      idx := idx + 1;
      expected(idx) := std_logic_vector(to_unsigned(payload'length, 16)(7 downto 0));
      idx := idx + 1;
    end if;

    -- Payload
    for i in payload'range loop
      expected(idx) := payload(i);
      idx := idx + 1;
    end loop;

    -- Trailer-- FIXME : hard coded for 2 bytes
    expected(idx) := packet_trailer(1*8-1 downto 0*8);
    idx := idx + 1;
    expected(idx) := packet_trailer(2*8-1 downto 1*8);
    idx := idx + 1;

    -- Compare
    report "Checking output packet for " & integer'image(idx) & " bytes";
    for i in 0 to idx - 1 loop
      if captured_packet(i) /= expected(i) then
        report  "FAIL: Byte " & integer'image(i) &
                " mismatch. Got " & to_hstring(captured_packet(i)) &
                ", expected " & to_hstring(expected(i)) severity error;
      end if;
    end loop;

    report "PASS: Packet matches expected output." severity note;

    std.env.stop;


  end process;

  -- Capture output
  process(clk)
  begin
    if rising_edge(clk) then
      if m_tvalid = '1' and m_tready = '1' then
        captured_packet(capture_index) <= m_tdata;
        capture_index <= capture_index + 1;
      end if;
    end if;
  end process;

end architecture;
