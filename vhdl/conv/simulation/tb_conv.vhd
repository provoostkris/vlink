------------------------------------------------------------------------------
--  Test bench for the convolutional coding
--  rev. 1.0 : 2022 Provoost Kris
------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.uniform;

entity tb_conv is
end entity tb_conv;

architecture rtl of tb_conv is

constant c_clk_period : time := 10 ns;

--! common signals
signal clk        : std_logic := '0';               -- synchron clock
signal rst        : std_logic;                      -- asynchron reset

--! encoder signals
signal stream_rx_dat   : std_logic;
signal stream_rx_ena   : std_logic;
signal stream_tx_dat   : std_logic_vector(1 downto 0);
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
  variable v_cycles : integer ;
	variable seed1    : integer := 99;
	variable seed2    : integer := 999;

  impure function rand_std return std_logic is
    variable v_real  		  : real;
    variable v_int 			  : integer;
    variable v_bit   		  : std_logic;
  begin
      uniform(seed1, seed2, v_real);
      v_int := integer(v_real);
    case v_int is
      when 0 		  => v_bit := '0';
      when others => v_bit := '1';
    end case;
      return v_bit;
  end function;

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
    stream_rx_dat   <= '0';
    stream_rx_ena   <= '0';
    proc_reset(3);

  report " RUN TST.00 ";
    stream_rx_dat   <= '0';
    stream_rx_ena   <= '0';
    proc_reset(3);
    proc_wait_clk(2**4);

  report " RUN TST.01 ";
    stream_rx_dat   <= '0';
    stream_rx_ena   <= '1';
    proc_reset(3);
    v_cycles := 0;
    while v_cycles < 2**8 loop
      stream_rx_dat   <= not stream_rx_dat;
      proc_wait_clk(1);
      v_cycles := v_cycles + 1;
    end loop;

  report " RUN TST.02 ";
    stream_rx_dat   <= '0';
    stream_rx_ena   <= '0';
    proc_reset(3);
    v_cycles := 0;
    while v_cycles < 2**8 loop
      stream_rx_dat   <= rand_std;
      stream_rx_ena   <= rand_std;
      proc_wait_clk(1);
      v_cycles := v_cycles + 1;
    end loop;

    proc_wait_clk(100);
  report " END of test bench" severity failure;

end process;

i_conv_enc: entity work.conv_enc
	port map(
      clk             => clk      ,
      rst             => rst      ,
      stream_rx_dat   => stream_rx_dat ,
      stream_rx_ena   => stream_rx_ena ,
      stream_tx_dat   => stream_tx_dat ,
      stream_tx_ena   => stream_tx_ena
	);

end architecture rtl;