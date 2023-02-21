------------------------------------------------------------------------------
--  Test bench for the fir designs
--  rev. 1.0 : 2023 Provoost Kris
------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.uniform;

entity tb_fir is
end entity tb_fir;

architecture rtl of tb_fir is

constant c_clk_period : time := 10 ns;

constant c_i_scale    : std_logic_vector(7 downto 0) := std_logic_vector(to_signed(2**7-1,8));
constant c_q_scale    : std_logic_vector(7 downto 0) := std_logic_vector(to_signed(2**7-1,8));

--! common signals
signal clk        : std_logic := '0';               -- synchron clock
signal rst        : std_logic;                      -- asynchron reset

--! signals
signal stream_rx_dat   : std_logic_vector(7 downto 0);
signal stream_rx_ena   : std_logic;
signal stream_tx_dat   : std_logic_vector(15 downto 0);
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

  impure function binary_slv(len : integer ) return std_logic_vector is
    variable v_real  		  : real;
    variable v_int 			  : integer;
    variable v_vec        : std_logic_vector(len - 1 downto 0);
  begin
      uniform(seed1, seed2, v_real);
      v_int := integer(v_real);
      case v_int is
        when 0 		  =>
          v_vec(v_vec'high)             := '0';
          v_vec(v_vec'high-1 downto 0)  := ( others => '1');
        when others =>
          v_vec(v_vec'high)             := '1';
          v_vec(v_vec'high-1 downto 0)  := ( others => '0');
      end case;
      return v_vec;
  end function;

  impure function rand_slv(len : integer ) return std_logic_vector is
    variable v_real  		  : real;
    variable v_int 			  : integer;
    variable v_vec        : std_logic_vector(len - 1 downto 0);
  begin
      uniform(seed1, seed2, v_real);
      v_int := integer(real(2**len)*v_real);
      v_vec := std_logic_vector(to_signed(v_int,len));
      return v_vec;
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
    stream_rx_dat   <= ( others => '0');
    stream_rx_ena   <= '0';
    proc_reset(3);

  report " RUN TST.00 ";
    stream_rx_dat   <= ( others => '0');
    stream_rx_ena   <= '0';
    proc_reset(3);
    proc_wait_clk(2**8);

  report " RUN TST.01 ";
    -- positive impulse resoponse
    stream_rx_dat   <= ( others => '0');
    stream_rx_ena   <= '1';
    proc_reset(3);
    proc_wait_clk(16);
    stream_rx_dat(stream_rx_dat'high)             <= '0';
    stream_rx_dat(stream_rx_dat'high-1 downto 0)  <= ( others => '1');
    proc_wait_clk(1);
    stream_rx_dat   <= ( others => '0');
    proc_wait_clk(16);
    proc_wait_clk(24);
    -- negative impulse response
    stream_rx_dat   <= ( others => '0');
    stream_rx_ena   <= '1';
    proc_reset(3);
    proc_wait_clk(16);
    stream_rx_dat(stream_rx_dat'high)             <= '1';
    stream_rx_dat(stream_rx_dat'high-1 downto 0)  <= ( others => '0');
    proc_wait_clk(1);
    stream_rx_dat   <= ( others => '0');
    proc_wait_clk(16);
    proc_wait_clk(24);

  report " RUN TST.02 ";
    stream_rx_dat   <= ( others => '0');
    stream_rx_ena   <= '1';
    proc_reset(3);
    v_cycles := 0;
    while v_cycles < 2**6 loop
      stream_rx_dat   <= binary_slv(8);
      proc_wait_clk(16);
      v_cycles := v_cycles + 1;
    end loop;
    proc_wait_clk(24);

  report " RUN TST.03 ";
    stream_rx_dat   <= ( others => '0');
    stream_rx_ena   <= '1';
    proc_reset(3);
    v_cycles := 0;
    while v_cycles < 2**8 loop
      stream_rx_dat   <= binary_slv(8);
      proc_wait_clk(1);
      v_cycles := v_cycles + 1;
    end loop;
    proc_wait_clk(24);

  report " RUN TST.04 ";
    stream_rx_dat   <= ( others => '0');
    stream_rx_ena   <= '1';
    proc_reset(3);
    v_cycles := 0;
    while v_cycles < 2**8 loop
      stream_rx_dat   <= rand_slv(8);
      proc_wait_clk(1);
      v_cycles := v_cycles + 1;
    end loop;
    proc_wait_clk(24);


    proc_wait_clk(100);
  report " END of test bench" severity failure;

end process;

i_fir: entity work.fir
	port map(
      clk             => clk           ,
      rst             => rst           ,
      enable          => stream_rx_ena ,
      data_i          => stream_rx_dat ,
      data_o          => stream_tx_dat
	);


end architecture rtl;