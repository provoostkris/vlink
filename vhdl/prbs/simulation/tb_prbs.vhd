------------------------------------------------------------------------------
--  Test bench for the serial prbs designs
--  rev. 1.0 : 2022 Provoost Kris
------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity tb_prbs is
end entity tb_prbs;

architecture rtl of tb_prbs is

--! common signals
signal clk        : std_logic := '0';               -- synchron clock
signal reset      : std_logic;                      -- asynchron reset
signal clk_en     : std_logic;                      -- clock enable
                    
signal prbs_set   : std_logic;                      -- set new prbs / bit pattern
signal prbs_type  : std_logic_vector (3 downto 0);  -- type of prbs / bit pattern
signal prbs_inv   : std_logic;                      -- invert prbs pattern
                    
--! TX signals      
signal err_insert : std_logic;                      -- manual error insert
signal err_set    : std_logic;                      -- set new error type
signal err_type   : std_logic_vector (3 downto 0);  -- error type
signal tx_bit     : std_logic;                      -- tx serial output
                    
--! RX signals      
signal rx_bit     : std_logic;                      -- rx serial input
signal syn_state  : std_logic;                      -- synchronisation state output
signal syn_los    : std_logic;                      -- sync loss signaling output
signal bit_err    : std_logic;                      -- biterror signaling output
signal clk_err    : std_logic;                      -- clockerror (bitslip) signaling output

begin

--! common
	clk       <= not clk  after 10  ns;
	reset     <= '1', '0' after 100 ns;
  clk_en    <= '1';

--! routing
  rx_bit <= tx_bit;
  

p_run: process
begin

  report " Apply POR configuration ";
    prbs_set    <= '0';
    prbs_type   <= ( others => '0');
    prbs_inv    <= '0';
    err_insert  <= '0';
    err_set     <= '0';
    err_type    <= ( others => '0');
    wait until reset'event and reset = '0';
    wait until rising_edge(clk);
  report " RUN TST.00 ";
    prbs_set    <= '1';
    prbs_type   <= ( others => '0');
    prbs_inv    <= '0';
    wait until rising_edge(clk);
    prbs_set    <= '0';
    prbs_type   <= ( others => '0');
    prbs_inv    <= '0';
    wait for 1 ms;

    wait for 1 ms;
  report " END of test bench" severity failure;

end process;

i_prbs_tx_ser : entity work.prbs_tx_ser
  port map (
    clk        => clk          ,-- synchron clock
    reset      => reset        ,-- asynchron reset
    clk_en     => clk_en       ,-- clock enable
    prbs_set   => prbs_set     ,-- set new prbs / bit pattern
    prbs_type  => prbs_type    ,-- type of prbs / bit pattern
    prbs_inv   => prbs_inv     ,-- invert prbs pattern
    err_insert => err_insert   ,-- manual error insert
    err_set    => err_set      ,-- set new error type
    err_type   => err_type     ,-- error type
    tx_bit     => tx_bit        -- tx serial output
  );

i_prbs_rx_ser : entity work.prbs_rx_ser
  port map (
    clk        => clk        , -- synchron clock
    reset      => reset      , -- asynchron reset
    clk_en     => clk_en     , -- clock enable
    rx_bit     => rx_bit     , -- rx serial input
    prbs_set   => prbs_set   , -- set new prbs / bit pattern
    prbs_type  => prbs_type  , -- type of prbs / bit pattern
    prbs_inv   => prbs_inv   , -- invert prbs pattern
    syn_state  => syn_state  , -- synchronisation state output
    syn_los    => syn_los    , -- sync loss signaling output
    bit_err    => bit_err    , -- biterror signaling output
    clk_err    => clk_err      -- clockerror (bitslip) signaling output
  );

end architecture rtl;