library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

library work;
use     work.pckg_ccsds_crc.all;

entity ccsds_crc16_frame is
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        data_in    : in  std_logic_vector(7 downto 0);
        data_valid : in  std_logic;
        frame_start: in  std_logic;
        frame_end  : in  std_logic;
        crc_ready  : out std_logic;
        crc_out    : out std_logic_vector(15 downto 0)
    );
end ccsds_crc16_frame;

architecture Behavioral of ccsds_crc16_frame is

  constant POLY : unsigned(15 downto 0) := x"1021";

  signal crc_reg : std_logic_vector(15 downto 0) ;
  signal crc_done: std_logic;

begin

    process(clk)
      variable crc  : std_logic_vector(15 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' or frame_start = '1' then
                crc      := (others => '1'); -- Reset CRC
                crc_reg  <= (others => '1'); -- Reset CRC
            elsif data_valid = '1' then
                crc := crc16_ccsds_byte(crc,data_in);
            end if;

            crc_reg <= std_logic_vector(crc);

            if reset = '1' or frame_start = '1' then
                crc_done <= '0';
            elsif frame_end = '1' then
                crc_done <= '1';
            end if;
        end if;
    end process;

    crc_out   <= crc_reg;
    crc_ready <= crc_done;

end Behavioral;
