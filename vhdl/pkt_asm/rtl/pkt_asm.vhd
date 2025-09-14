library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pkt_asm is
  generic (
    G_TYPE_WIDTH    : natural range 8 to 128  := 16;     -- bits
    G_TRAILER_WIDTH : natural range 8 to 128  := 16;     -- bits
    G_MAX_BYTES     : natural range 8 to 2048 := 1024    -- payload buffer
  );
  port (
    clk              : in  std_logic;
    rst_n            : in  std_logic;

    -- Input stream
    s_axis_tdata     : in  std_logic_vector(7 downto 0);
    s_axis_tvalid    : in  std_logic;
    s_axis_tready    : out std_logic;
    s_axis_tlast     : in  std_logic;

    -- Header/trailer inputs
    packet_type      : in  std_logic_vector(G_TYPE_WIDTH-1 downto 0);
    packet_trailer   : in  std_logic_vector(G_TRAILER_WIDTH-1 downto 0);
    insert_length    : in  std_logic;

    -- Output stream
    m_axis_tdata     : out std_logic_vector(7 downto 0);
    m_axis_tvalid    : out std_logic;
    m_axis_tready    : in  std_logic;
    m_axis_tlast     : out std_logic
  );
end entity;

architecture rtl of pkt_asm is

  type state_t is (
    RECEIVE, SEND_TYPE, SEND_LEN_H, SEND_LEN_L,
    SEND_PAYLOAD, SEND_TRAILER
  );
  signal state : state_t;

  type ram_t is array (0 to G_MAX_BYTES-1) of std_logic_vector(7 downto 0);
  signal ram : ram_t;

  signal wr_ptr, rd_ptr : unsigned(15 downto 0) ;
  signal len_bytes      : unsigned(15 downto 0) ;
  signal buffer_room    : std_logic;

  signal o_data  : std_logic_vector(7 downto 0);
  signal o_valid : std_logic;
  signal o_last  : std_logic;

  -- Type latch and indexes
  signal type_latched   : std_logic_vector(G_TYPE_WIDTH-1 downto 0);
  signal type_index     : natural range 0 to G_TYPE_WIDTH/8;
  signal trailer_index  : natural range 0 to G_TRAILER_WIDTH/8;

  -- Length insertion flag (latched per frame)
  signal insert_len_latched : std_logic;

begin

  m_axis_tdata  <= o_data;
  m_axis_tvalid <= o_valid;
  m_axis_tlast  <= o_last;

  -- Input ready only during RECEIVE
  s_axis_tready <= '1' when state = RECEIVE and wr_ptr < G_MAX_BYTES else '0';
  buffer_room   <= '1' when wr_ptr < G_MAX_BYTES else '0';

  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        state              <= RECEIVE;
        wr_ptr             <= (others => '0');
        rd_ptr             <= (others => '0');
        len_bytes          <= (others => '0');
        o_data             <= (others => '0');
        o_valid            <= '0';
        o_last             <= '0';
        type_latched       <= (others => '0');
        type_index         <= 0;
        trailer_index      <= 0;
        insert_len_latched <= '0';
      else
        o_valid <= '0';
        o_last  <= '0';

        case state is
          when RECEIVE =>
            if s_axis_tvalid = '1' and buffer_room = '1' then
              ram(to_integer(wr_ptr)) <= s_axis_tdata;
              wr_ptr <= wr_ptr + 1;

              if wr_ptr = 0 then
                type_latched       <= packet_type;
                insert_len_latched <= insert_length;
              end if;

              if s_axis_tlast = '1' then
                len_bytes     <= wr_ptr + 1;
                rd_ptr        <= (others => '0');
                type_index    <= 0;
                trailer_index <= 0;
                state         <= SEND_TYPE;
              end if;
            end if;

          when SEND_TYPE =>
            if type_index < G_TYPE_WIDTH/8 then
              if m_axis_tready = '1' then
                o_data  <= type_latched(type_index*8+7 downto type_index*8);
                o_valid <= '1';
                type_index <= type_index + 1;
                if type_index + 1 = G_TYPE_WIDTH/8 then
                  if insert_len_latched = '1' then
                    state <= SEND_LEN_H;
                  else
                    state <= SEND_PAYLOAD;
                  end if;
                end if;
              end if;
            end if;

          when SEND_LEN_H =>
            if m_axis_tready = '1' then
              o_data  <= std_logic_vector(len_bytes(15 downto 8));
              o_valid <= '1';
              state   <= SEND_LEN_L;
            end if;

          when SEND_LEN_L =>
            if m_axis_tready = '1' then
              o_data  <= std_logic_vector(len_bytes(7 downto 0));
              o_valid <= '1';
              state   <= SEND_PAYLOAD;
            end if;

          when SEND_PAYLOAD =>
            if rd_ptr < len_bytes then
              if m_axis_tready = '1' then
                o_data  <= ram(to_integer(rd_ptr));
                o_valid <= '1';
                rd_ptr  <= rd_ptr + 1;
                if rd_ptr + 1 = len_bytes then
                  state         <= SEND_TRAILER;
                  trailer_index <= 0;
                end if;
              end if;
            end if;

          when SEND_TRAILER =>
            if trailer_index < G_TRAILER_WIDTH/8 then
              if m_axis_tready = '1' then
                o_data  <= packet_trailer(trailer_index*8+7 downto trailer_index*8);
                o_valid <= '1';
                trailer_index <= trailer_index + 1;
                if trailer_index + 1 = G_TRAILER_WIDTH/8 then
                  o_last <= '1';
                  state  <= RECEIVE;
                  wr_ptr <= (others => '0');
                end if;
              end if;
            end if;

          when others =>
            state <= RECEIVE;
        end case;
      end if;
    end if;
  end process;

end architecture;
