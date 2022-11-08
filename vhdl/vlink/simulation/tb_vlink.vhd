------------------------------------------------------------------------------
--  Test bench for the virtual link
--  rev. 1.0 : 2022 Provoost Kris
------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity tb_vlink is
end entity tb_vlink;

architecture rtl of tb_vlink is

--! common signals
signal clk        : std_logic := '0';               -- synchron clock
signal rst        : std_logic;                      -- asynchron reset

begin

--! common
	clk       <= not clk  after 10  ns;
	rst       <= '1', '0' after 100 ns;

p_run: process
begin

  report " START of test bench ";
    wait for 2 ms;
  report " END of test bench" severity failure;

end process;

i_vlink : entity work.vlink
  port map (
    clk        => clk          ,-- synchron clock
    rst        => rst           -- asynchron reset
  );


end architecture rtl;