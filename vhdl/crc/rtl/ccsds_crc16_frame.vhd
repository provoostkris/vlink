library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library work;
use     work.pckg_ccsds_crc.all;

entity ccsds_crc16_frame is
    Port (
        clk          : in  std_logic;
        a_rst        : in  std_logic;
        s_rst        : in  std_logic;
        data_in      : in  std_logic_vector(7 downto 0);
        data_valid   : in  std_logic;
        frame_start  : in  std_logic;
        frame_end    : in  std_logic;
        crc_ready    : out std_logic;
        crc_out      : out std_logic_vector(15 downto 0)
    );
end ccsds_crc16_frame;

architecture Behavioral of ccsds_crc16_frame is

  signal crc_reg : std_logic_vector(15 downto 0) ;
  signal crc_done: std_logic;

begin

process(clk, a_rst)
  procedure do_reset is
  begin
      crc_reg  <= (others => '1');
      crc_done <= '0';
  end procedure;
begin
    if a_rst = '1' then
        do_reset;
    elsif rising_edge(clk) then
        if s_rst = '1' then
            do_reset;
        elsif frame_start = '1' then
            do_reset;
        elsif data_valid = '1' then
            crc_reg <= crc16_ccsds_byte(crc_reg, data_in);
        end if;

        if frame_end = '1' then
            crc_done <= '1';
        elsif frame_start = '1' then
            crc_done <= '0';
        end if;
    end if;
end process;

    crc_out   <= crc_reg;
    crc_ready <= crc_done;

end Behavioral;
