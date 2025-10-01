library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity tb_axis_dual_port_fifo is
end entity;

architecture sim of tb_axis_dual_port_fifo is

  constant DATA_WIDTH : integer := 32;
  constant DEPTH      : integer := 16;

  -- DUT ports
  signal a_clk, a_rst : std_logic := '0';
  signal b_clk, b_rst : std_logic := '0';

  signal s_valid : std_logic := '0';
  signal s_data  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal s_last  : std_logic := '0';
  signal s_ready : std_logic;

  signal m_valid : std_logic;
  signal m_data  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal m_last  : std_logic;
  signal m_ready : std_logic := '1';

  signal x_valid : std_logic;
  signal x_data  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal x_last  : std_logic;
  signal x_ready : std_logic := '1';

  -- Scoreboard
  type packet_t is record
    data : std_logic_vector(DATA_WIDTH-1 downto 0);
    last : std_logic;
  end record;

  type pkt_array_t is array (natural range <>) of packet_t;
  constant MAX_PKTS : integer := 100;
  signal sent_pkts  : pkt_array_t(0 to MAX_PKTS-1);
  signal recv_pkts  : pkt_array_t(0 to MAX_PKTS-1);
  signal sent_count : integer;
  signal recv_count : integer;

  -- Clock generation
  constant A_PERIOD : time := 7 ns;
  constant B_PERIOD : time := 10 ns;

begin

  -- Instantiate DUT
  dut_0: entity work.axis_dual_port_fifo
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      DEPTH      => DEPTH
    )
    port map (
      s_axis_clk    => a_clk,
      s_axis_rst    => a_rst,
      s_axis_tvalid => s_valid,
      s_axis_tdata  => s_data,
      s_axis_tlast  => s_last,
      s_axis_tready => s_ready,

      m_axis_clk    => b_clk,
      m_axis_rst    => b_rst,
      m_axis_tvalid => x_valid,
      m_axis_tdata  => x_data,
      m_axis_tlast  => x_last,
      m_axis_tready => x_ready
    );

  dut_1: entity work.axis_dual_port_fifo
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      DEPTH      => DEPTH
    )
    port map (
      s_axis_clk    => b_clk,
      s_axis_rst    => b_rst,
      s_axis_tvalid => x_valid,
      s_axis_tdata  => x_data,
      s_axis_tlast  => x_last,
      s_axis_tready => x_ready,

      m_axis_clk    => a_clk,
      m_axis_rst    => a_rst,
      m_axis_tvalid => m_valid,
      m_axis_tdata  => m_data,
      m_axis_tlast  => m_last,
      m_axis_tready => m_ready
    );


  -- Clocks
  a_clk <= not a_clk after A_PERIOD/2;
  b_clk <= not b_clk after B_PERIOD/2;

  -- Reset
  process
  begin
    a_rst <= '1';
    b_rst <= '1';
    wait for 100 ns;
    a_rst <= '0';
    b_rst <= '0';
    wait;
  end process;

  -- Stimulus: push packets

  stim_cnt: process (a_clk,a_rst)
  begin
    if a_rst = '1' then
        s_data  <= ( others => '0');
        s_last  <= '0';
        s_valid <= '0';
    elsif rising_edge(a_clk) then
      if s_valid = '1' and s_ready = '1' then
        s_data  <= std_logic_vector(to_unsigned(1+sent_count, DATA_WIDTH));
      end if;

      if sent_count < MAX_PKTS-1 then
        s_valid  <= s_ready;
        s_last   <= '0';
      else
        if s_ready = '0' then
          s_valid  <= '1';
          s_last   <= '1';
        else
          s_valid  <= '0';
          s_last   <= '0';
        end if;
      end if;

    end if;
  end process;


  -- Monitor: pop packets
  sent_proc: process
  begin
    sent_count <= 0;
    wait until a_rst = '0';
    while sent_count < MAX_PKTS loop
      wait until rising_edge(a_clk);
      -- sent counter
      if s_valid = '1' and s_ready = '1' then
        sent_pkts(sent_count).data <= s_data;
        sent_pkts(sent_count).last <= s_last;
        sent_count <= sent_count + 1;
      end if;
    end loop;
    wait;
  end process;

  -- Monitor: pop packets
  recv_proc: process
  begin
    recv_count <= 0;
    wait until a_rst = '0';
    while recv_count < MAX_PKTS loop
      wait until rising_edge(a_clk);
      -- recieve counter and flow control
      if m_valid = '1' and m_ready = '1' then
        recv_pkts(recv_count).data <= m_data;
        recv_pkts(recv_count).last <= m_last;
        recv_count <= recv_count + 1;

        -- Random backpressure
        if recv_count mod 13 = 0 or recv_count mod 29 = 0 then
          m_ready <= '0';
          wait until rising_edge(a_clk);
          m_ready <= '1';
        end if;
        -- burst backpressure
        if recv_count mod 62 = 0 then
          m_ready <= '0';
          for j in 0 to 25 loop
            wait until rising_edge(a_clk);
          end loop;
          m_ready <= '1';
        end if;
      end if;
    end loop;
    wait;
  end process;

  -- Checker
  check_proc: process
  begin
    wait until m_last = '1' and m_valid = '1';
    wait until rising_edge(a_clk);
    wait until rising_edge(a_clk);
    for i in 0 to MAX_PKTS-1 loop
        report  " CNT :" & integer'image(i) &
                "  RX : " & to_hstring(recv_pkts(i).data) &
                "  TX : " & to_hstring(sent_pkts(i).data);
      assert recv_pkts(i).data = sent_pkts(i).data
        report "--FAIL--"
        severity error;
      assert recv_pkts(i).last = sent_pkts(i).last
        report "tlast mismatch at index " & integer'image(i)
        severity error;
    end loop;

    wait for 100 ns;
    report " Test bench completed" severity note;
    std.env.stop;

  end process;

  -- Timeout watchdog process
  timeout_proc : process
  begin
    wait for 2 us;  -- Adjust to desired timeout duration
    report "Testbench timeout: simulation stopped." severity warning;
    std.env.stop;
  end process timeout_proc;

end architecture;
