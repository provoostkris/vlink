------------------------------------------------------------------------------
--  Test bench for the serial lfsr designs
--  rev. 1.0 : 2022 Provoost Kris
------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity tb_sei is
end entity tb_sei;

architecture rtl of tb_sei is

constant c_clk_period : time := 10 ns;

--! common signals
signal clk        : std_logic := '0';               -- synchron clock
signal rst        : std_logic;                      -- asynchron reset

--! signals
signal ratio           : std_logic_vector(7 downto 0);
signal stream_rx_dat   : std_logic;
signal stream_rx_ena   : std_logic;
signal stream_tx_dat   : std_logic;
signal stream_tx_ena   : std_logic;

--! procedures
procedure proc_wait_clk
  (constant cycles : in natural) is
begin
   for i in 0 to cycles-1 loop
    wait until rising_edge(clk);
   end loop;
end procedure;


begin

--! common
	clk       <= not clk  after c_clk_period/2;

--! run test bench
p_run: process
  procedure proc_reset
    (constant cycles : in natural) is
  begin
     rst <= '1';
     for i in 0 to cycles-1 loop
      wait until rising_edge(clk);
     end loop;
     rst <= '0';
  end procedure;
begin

  report " Apply POR configuration ";
    ratio           <= ( others => '0');
    stream_rx_dat   <= '0';
    stream_rx_ena   <= '0';
    proc_reset(3);
    
  report " RUN TST.00 ";
    ratio <= ( others => '0');
    stream_rx_dat   <= '0';
    stream_rx_ena   <= '0';
    proc_reset(3);
    proc_wait_clk(2**8);
    
  report " RUN TST.01 ";
    ratio <= ( others => '0');
    stream_rx_dat   <= '1';
    stream_rx_ena   <= '1';
    proc_reset(3);
    proc_wait_clk(2**8);
    
  report " RUN TST.02 ";
    ratio <= x"04";
    stream_rx_dat   <= '0';
    stream_rx_ena   <= '0';
    proc_reset(3);
    proc_wait_clk(2**8);
    
  report " RUN TST.03 ";
    ratio <= x"04";
    stream_rx_dat   <= '1';
    stream_rx_ena   <= '1';
    proc_reset(3);
    proc_wait_clk(2**8);
    
  report " RUN TST.04 ";
    ratio <= x"17";
    stream_rx_dat   <= '0';
    stream_rx_ena   <= '0';
    proc_reset(3);
    proc_wait_clk(2**8);
    
  report " RUN TST.05 ";
    ratio <= x"17";
    stream_rx_dat   <= '1';
    stream_rx_ena   <= '1';
    proc_reset(3);
    proc_wait_clk(2**8);

    proc_wait_clk(100);
  report " END of test bench" severity failure;

end process;

i_sei: entity work.sei
	port map(
      clk             => clk           ,
      rst             => rst           ,
      ratio           => ratio         ,
      stream_rx_dat   => stream_rx_dat ,
      stream_rx_ena   => stream_rx_ena ,
      stream_tx_dat   => stream_tx_dat ,
      stream_tx_ena   => stream_tx_ena
	);






end architecture rtl;