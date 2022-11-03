------------------------------------------------------------------------------
--  Test bench for the serial lfsr designs
--  rev. 1.0 : 2022 Provoost Kris
------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity tb_lfsr is
end entity tb_lfsr;

architecture rtl of tb_lfsr is

constant c_clk_period : time := 10 ns;

--! common signals
signal clk        : std_logic := '0';               -- synchron clock
signal rst        : std_logic;                      -- asynchron reset

--! lfsr signals
signal taps      : std_logic_vector(7 downto 0);
signal init      : std_logic_vector(7 downto 0);
signal load      : std_logic;
signal delay     : std_logic;
signal cfg_fsr   : std_logic;

--! scrambler signals
signal seq_fsr       : std_logic;
signal original      : std_logic;
signal scrambled     : std_logic;
signal descrambled   : std_logic;

--! procedures
procedure wait_clk
  (constant cycles : in natural) is
begin
   for i in 0 to cycles-1 loop
   wait until rising_edge(clk);
   end loop;
end procedure;

begin

--! common
	clk       <= not clk  after c_clk_period/2;
	rst       <= '1', '0' after 100 ns;

--! run test bench
p_run: process
begin

  report " Apply POR configuration ";
    taps    <= ( others => '0');
    init    <= ( others => '0');
    load    <= '0';
    delay   <= '0';
    wait until rst'event and rst = '0';
    wait until rising_edge(clk);

  report " RUN TST.00 ";
    taps    <= x"A9";
    init    <= ( others => '1');
    load    <= '0';
    delay   <= '1';
    wait_clk(128);

  report " RUN TST.01 ";
    taps    <= x"A9";
    init    <= ( others => '1');
    load    <= '1';
    wait until rising_edge(clk);
    load    <= '0';
    delay   <= '1';
    wait_clk(128);

    wait_clk(100);
  report " END of test bench" severity failure;

end process;

i_lfsr_ser_cfg: entity work.lfsr_ser_cfg
	port map(
      clk             => clk      ,
      rst             => rst      ,
      taps            => taps     ,
      init            => init     ,
      load            => load     ,
      delay           => delay    ,
      cfg_fsr         => cfg_fsr
	);

--! create scrambler
p_dummy_src: process
begin
    original <= '1';
    wait_clk(10);
    original <= '0';
    wait_clk(20);
    original <= '1';
    wait_clk(30);
    original <= '0';
    wait_clk(12);
end process;

p_scrambler: process (clk)
begin
  if rising_edge(clk) then
    -- keep a 1 cycle delayed copy of the random sequence
    seq_fsr       <= cfg_fsr;
    -- scrambling is just the plain XOR of the LFSR with the original signal
    scrambled     <= original  xor cfg_fsr;
    -- descrambling is the same LFSR sequence with the scrambled signal
    descrambled   <= scrambled xor seq_fsr;
  end if;
end process;




end architecture rtl;