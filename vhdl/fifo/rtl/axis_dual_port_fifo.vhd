--! @file axis_dual_port_fifo.vhd
--! @brief AXI4-Stream dual-clock dual-port FIFO (single-file, vendor-agnostic).
--! @details
--!   - Independent write/read clocks with CDC via Gray-coded pointers.
--!   - AXIS slave (write) and AXIS master (read) interfaces with tlast.
--!   - Parameterized width and depth (depth must be a power of two).
--!   - Portable VHDL-2008; no vendor primitives needed.
--! @note Handshake rules:
--!   - Push when s_axis_tvalid='1' and s_axis_tready='1'.
--!   - Pop  when m_axis_tvalid='1' and m_axis_tready='1'.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief AXIS dual-port FIFO entity.
--! @tparam DATA_WIDTH Width of tdata in bits.
--! @tparam DEPTH Number of FIFO entries (must be power of two).
entity axis_dual_port_fifo is
  generic (
    DATA_WIDTH : integer := 32;  --! @tparam DATA_WIDTH Data width in bits (>0).
    DEPTH      : integer := 64   --! @tparam DEPTH FIFO depth (power of two).
  );
  port (
    --! @name AXIS write interface (slave)
    --! @{
    s_axis_clk    : in  std_logic;                               --! @param s_axis_clk Write domain clock.
    s_axis_rst    : in  std_logic;                               --! @param s_axis_rst Synchronous reset (active high) in write domain.
    s_axis_tvalid : in  std_logic;                               --! @param s_axis_tvalid Write-side valid.
    s_axis_tdata  : in  std_logic_vector(DATA_WIDTH-1 downto 0); --! @param s_axis_tdata Write-side data.
    s_axis_tlast  : in  std_logic := '0';                        --! @param s_axis_tlast Write-side packet boundary.
    s_axis_tready : out std_logic;                               --! @param s_axis_tready Write-side ready (deasserts when full).
    --! @}

    --! @name AXIS read interface (master)
    --! @{
    m_axis_clk    : in  std_logic;                               --! @param m_axis_clk Read domain clock.
    m_axis_rst    : in  std_logic;                               --! @param m_axis_rst Synchronous reset (active high) in read domain.
    m_axis_tvalid : out std_logic;                               --! @param m_axis_tvalid Read-side valid.
    m_axis_tdata  : out std_logic_vector(DATA_WIDTH-1 downto 0); --! @param m_axis_tdata Read-side data.
    m_axis_tlast  : out std_logic;                               --! @param m_axis_tlast Read-side packet boundary.
    m_axis_tready : in  std_logic                                --! @param m_axis_tready Read-side ready (backpressure).
    --! @}
  );
end entity;

architecture rtl of axis_dual_port_fifo is

  --! @brief Integer ceiling log2 helper.
  function clog2(n : integer) return integer is
    variable r : integer := 0;
    variable v : integer := n - 1;
  begin
    while v > 0 loop
      r := r + 1;
      v := v / 2;
    end loop;
    return r;
  end function;

  --! @brief Power-of-two check (n > 0 and only one set bit).
  function is_pow2(n : integer) return boolean is
    variable v : integer := n;
  begin
    if v <= 0 then
      return false;
    end if;
    while (v mod 2) = 0 loop
      v := v / 2;
    end loop;
    return v = 1;
  end function;

  --! @brief Binary to Gray code conversion.
  function bin2gray(b : unsigned) return unsigned is
  begin
    return b xor (b srl 1);
  end function;

  --! @brief Gray code to binary conversion.
  function gray2bin(g : unsigned) return unsigned is
    variable b : unsigned(g'range) := (others => '0');
  begin
    b(b'high) := g(g'high);
    for i in (g'high - 1) downto g'low loop
      b(i) := b(i+1) xor g(i);
    end loop;
    return b;
  end function;

  --! @brief Compute integer address from pointer's low bits.
  function next_addr(ptr : unsigned) return integer is
  begin
    return to_integer(ptr(ptr'low + clog2(DEPTH) - 1 downto ptr'low));
  end function;

  -- ============================================================
  -- Local parameters
  -- ============================================================
  constant ADDR_BITS : integer := clog2(DEPTH);   --! @brief Address width for DEPTH entries.
  constant PTR_BITS  : integer := ADDR_BITS + 1;  --! @brief Extra bit for wrap/full detection.
  constant WORD_W    : integer := DATA_WIDTH + 1; --! @brief Stored word: tlast + tdata.

  -- ============================================================
  -- Storage (true dual-port via separate processes)
  -- ============================================================
  --! @brief RAM array storing {tlast, tdata}.
  type ram_t is array (0 to DEPTH-1) of std_logic_vector(WORD_W-1 downto 0);
  signal ram : ram_t ;

  -- ============================================================
  -- Pointers and CDC synchronizers
  -- ============================================================
  --! @brief Write-domain pointers.
  signal wr_ptr_bin    : unsigned(PTR_BITS-1 downto 0) ;
  signal wr_ptr_gray   : unsigned(PTR_BITS-1 downto 0) ;

  --! @brief Read-domain pointers.
  signal rd_ptr_bin    : unsigned(PTR_BITS-1 downto 0) ;
  signal rd_ptr_gray   : unsigned(PTR_BITS-1 downto 0) ;

  --! @brief Cross-domain pointer synchronizers (Gray-coded).
  signal rd_ptr_gray_sync1, rd_ptr_gray_sync2 : unsigned(PTR_BITS-1 downto 0) ;
  signal wr_ptr_gray_sync1, wr_ptr_gray_sync2 : unsigned(PTR_BITS-1 downto 0) ;

  --! @brief Status flags in each domain.
  signal full_s   : std_logic; --! @brief FIFO  full (write domain).
  signal afull_s  : std_logic; --! @brief FIFO afull (write domain).
  signal empty_m  : std_logic; --! @brief FIFO empty (read domain).

  --! @brief Write to memory condition
  signal write_mem   : std_logic; --! @brief write in memory (write domain).

  --! @brief AXIS read-side output registers.
  signal m_valid_q : std_logic;
  signal m_data_q  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal m_last_q  : std_logic;

begin
  --! @brief Elaboration-time checks for parameters.

    assert is_pow2(DEPTH)
      report "axis_dual_port_fifo: DEPTH must be a power of two"
      severity failure;
    assert DATA_WIDTH > 0
      report "axis_dual_port_fifo: DATA_WIDTH must be > 0"
      severity failure;

  -- ============================================================
  -- Write clock domain (s_axis_clk)
  -- ============================================================

  --! @brief Synchronize read Gray pointer into write domain.
  sync_rdptr_to_wr: process(s_axis_clk)
  begin
    if rising_edge(s_axis_clk) then
      if s_axis_rst = '1' then
        rd_ptr_gray_sync1 <= (others => '0');
        rd_ptr_gray_sync2 <= (others => '0');
      else
        rd_ptr_gray_sync1 <= rd_ptr_gray;
        rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
      end if;
    end if;
  end process;

  --! @brief Compute write-side full flag (classic async FIFO rule).
  full_comb: process(wr_ptr_bin, rd_ptr_gray_sync2)
    variable wr_ptr_gray_next : unsigned(PTR_BITS-1 downto 0);
    variable rdg              : unsigned(PTR_BITS-1 downto 0);
  begin
    --! full computation
    wr_ptr_gray_next := bin2gray(wr_ptr_bin + 1);
    rdg := rd_ptr_gray_sync2;
    -- Full when next write Gray equals read Gray with top two bits inverted.
    if  (wr_ptr_gray_next(PTR_BITS-1) /= rdg(PTR_BITS-1)) and
        (wr_ptr_gray_next(PTR_BITS-2) /= rdg(PTR_BITS-2)) and
        (wr_ptr_gray_next(PTR_BITS-3 downto 0) = rdg(PTR_BITS-3 downto 0)) then
      full_s <= '1';
    else
      full_s <= '0';
    end if;
    --! almost full computation
    wr_ptr_gray_next := bin2gray(wr_ptr_bin + 2);
    rdg := rd_ptr_gray_sync2;
    -- Almost Full when next+1 write Gray equals read Gray with top two bits inverted.
    if  (wr_ptr_gray_next(PTR_BITS-1) /= rdg(PTR_BITS-1)) and
        (wr_ptr_gray_next(PTR_BITS-2) /= rdg(PTR_BITS-2)) and
        (wr_ptr_gray_next(PTR_BITS-3 downto 0) = rdg(PTR_BITS-3 downto 0)) then
      afull_s <= '1';
    else
      afull_s <= '0';
    end if;
  end process;

  --! @brief tready deasserts when FIFO is almost full.
  s_axis_tready <= not (afull_s or full_s);
  --! @brief only write when tready and tvalid are active
  write_mem     <= not (afull_s or full_s) and s_axis_tvalid;

  --! @brief Write path: accept data when valid & ready, store {tlast,tdata}, advance pointer.
  write_proc: process(s_axis_clk)
    variable waddr : integer;
  begin
    if rising_edge(s_axis_clk) then
      if s_axis_rst = '1' then
        wr_ptr_bin  <= (others => '0');
        wr_ptr_gray <= (others => '0');
      else
        --! @brief write valid data when there is room
        if write_mem = '1' then
          waddr := next_addr(wr_ptr_bin);
          ram(waddr) <= s_axis_tlast & s_axis_tdata;
          wr_ptr_bin  <= wr_ptr_bin + 1;
          wr_ptr_gray <= bin2gray(wr_ptr_bin + 1);
        end if;
      end if;
    end if;
  end process;

  -- ============================================================
  -- Read clock domain (m_axis_clk)
  -- ============================================================

  --! @brief Synchronize write Gray pointer into read domain.
  sync_wrptr_to_rd: process(m_axis_clk)
  begin
    if rising_edge(m_axis_clk) then
      if m_axis_rst = '1' then
        wr_ptr_gray_sync1 <= (others => '0');
        wr_ptr_gray_sync2 <= (others => '0');
      else
        wr_ptr_gray_sync1 <= wr_ptr_gray;
        wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
      end if;
    end if;
  end process;

  --! @brief Empty flag: equal Gray pointers (local read vs. synced write).
  empty_comb: process(rd_ptr_gray, wr_ptr_gray_sync2)
  begin
    if rd_ptr_gray = wr_ptr_gray_sync2 then
      empty_m <= '1';
    else
      empty_m <= '0';
    end if;
  end process;

  --! @brief Read path with output registers and AXIS handshake.
  read_proc: process(m_axis_clk)
    variable raddr    : integer;
    variable word     : std_logic_vector(WORD_W-1 downto 0);
    variable take_new : boolean;
  begin
    if rising_edge(m_axis_clk) then
      if m_axis_rst = '1' then
        rd_ptr_bin  <= (others => '0');
        rd_ptr_gray <= (others => '0');
        m_valid_q   <= '0';
        m_data_q    <= (others => '0');
        m_last_q    <= '0';
        take_new    := false ;
      else
        --! @brief Fetch new word if output is free or consumer just accepted.
        take_new := (m_valid_q = '0') or (m_axis_tready = '1');

        if take_new and (empty_m = '0') then
          --! @brief Read from RAM and advance read pointer.
          raddr := next_addr(rd_ptr_bin);
          word  := ram(raddr);
          m_last_q  <= word(WORD_W-1);
          m_data_q  <= word(WORD_W-2 downto 0);
          m_valid_q <= '1';

          rd_ptr_bin  <= rd_ptr_bin + 1;
          rd_ptr_gray <= bin2gray(rd_ptr_bin + 1);

        elsif (m_axis_tready = '1') then
          --! @brief If consumer accepted but FIFO is empty, drop valid.
          if empty_m = '1' then
            m_valid_q <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  --! @brief Drive AXIS read-side outputs.
  m_axis_tvalid <= m_valid_q;
  m_axis_tdata  <= m_data_q;
  m_axis_tlast  <= m_last_q;

  -- ============================================================
  -- Optional debug/readability comments (non-functional)
  -- ============================================================
  --! @note Throughput: one beat per clock in each domain when handshakes allow.
  --! @note Timing: output is registered; CDC paths limited to Gray sync flops.
  --! @note Extensibility: pack additional sidebands (e.g., tkeep/tuser) into WORD_W.

end architecture;
