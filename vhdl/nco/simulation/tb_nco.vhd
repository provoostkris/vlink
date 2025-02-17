------------------------------------------------------------------------------
--  Test bench for the nco designs
--  rev. 1.0 : 2023 Provoost Kris
------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_nco is
end entity tb_nco;

architecture rtl of tb_nco is

constant c_clk_period : time := 10 ns;

constant c_lut    : natural  := 10;
constant c_res    : natural  := 12;

--! common signals
signal clk        : std_logic := '0';               -- synchron clock
signal rst        : std_logic;                      -- asynchron reset

--! signals
signal freq_a       : std_logic_vector(c_lut-1 downto 0);
signal freq_b       : std_logic_vector(c_lut-1 downto 0);

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
    freq_a   <= ( others => '0');
    freq_b   <= ( others => '0');
    proc_reset(3);

  report " RUN TST.00 ";
    freq_a   <= ( others => '0');
    freq_b   <= ( others => '0');
    proc_reset(30);
    proc_wait_clk(2**8);

  report " RUN TST.01 ";
   freq_a   <= std_logic_vector(to_unsigned(1,c_lut));
   freq_b   <= std_logic_vector(to_unsigned(1,c_lut));
    proc_reset(30);
    proc_wait_clk(2**c_lut);
    proc_wait_clk(2**c_lut);

  report " RUN TST.02 ";
    freq_a   <= std_logic_vector(to_unsigned(33,c_lut));
    freq_b   <= std_logic_vector(to_unsigned(33,c_lut));
    proc_reset(30);
    proc_wait_clk(2**c_lut);
    proc_wait_clk(2**c_lut);

  report " RUN TST.03 ";
    freq_a   <= std_logic_vector(to_unsigned(5,c_lut));
    freq_b   <= std_logic_vector(to_unsigned(5,c_lut));
    proc_reset(30);
    proc_wait_clk(2**c_lut);
    proc_wait_clk(2**c_lut);

  report " END of test bench" severity failure;

end process;

i_nco: entity work.nco
  generic map(
    g_lut             => c_lut  ,
    g_res             => c_res
  )
	port map(
      clk             => clk  ,
      rst             => rst  ,
      freq_a          => freq_a ,
      freq_b          => freq_b ,
      nco_m           => open
	);


end architecture rtl;