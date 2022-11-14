------------------------------------------------------------------------------
--  TOP level design file for virtual link
--  rev. 1.0 : 2022 Provoost Kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

entity vlink is
	port(
      clk             :  in std_logic;
      rst             :  in std_logic
	);
end entity vlink;

architecture rtl of vlink is



--! PRBS TX signals
signal tx_prbs_set   : std_logic;                      -- set new prbs / bit pattern
signal tx_prbs_type  : std_logic_vector (3 downto 0);  -- type of prbs / bit pattern
signal tx_prbs_inv   : std_logic;                      -- invert prbs pattern
signal tx_err_insert : std_logic;                      -- manual error insert
signal tx_err_set    : std_logic;                      -- set new error type
signal tx_err_type   : std_logic_vector (3 downto 0);  -- error type
signal tx_bit        : std_logic;                      -- tx serial output
signal tx_clk_en     : std_logic;                      -- clock enable

--! SEI signals
signal ratio           : std_logic_vector(7 downto 0);
signal stream_rx_dat   : std_logic;
signal stream_rx_ena   : std_logic;
signal stream_tx_dat   : std_logic;
signal stream_tx_ena   : std_logic;

--! PRBS RX signals
signal rx_prbs_set   : std_logic;                      -- set new prbs / bit pattern
signal rx_prbs_type  : std_logic_vector (3 downto 0);  -- type of prbs / bit pattern
signal rx_prbs_inv   : std_logic;                      -- invert prbs pattern
signal rx_syn_state  : std_logic;                      -- synchronisation state output
signal rx_syn_los    : std_logic;                      -- sync loss signaling output
signal rx_bit_err    : std_logic;                      -- biterror signaling output
signal rx_clk_err    : std_logic;                      -- clockerror (bitslip) signaling output
signal rx_bit        : std_logic;                      -- rx serial input
signal rx_clk_en     : std_logic;                      -- clock enable

begin

--! clock control 
tx_clk_en         <= '1';

--! configuration control
tx_prbs_set       <= '0';
tx_prbs_type      <= "0000";
tx_prbs_inv       <= '0';
tx_err_insert     <= '0';
tx_err_set        <= '0';
tx_err_type       <= "0000";

ratio             <= "11111111";

rx_prbs_set       <= '0';
rx_prbs_type      <= "0000";
rx_prbs_inv       <= '0';
-- rx_syn_state
-- rx_syn_los
-- rx_bit_err
-- rx_clk_err


--! transmitter
i_prbs_tx_ser : entity work.prbs_tx_ser
  port map (
    clk        => clk             ,-- synchron clock
    reset      => rst             ,-- asynchron reset
    clk_en     => tx_clk_en       ,-- clock enable
    prbs_set   => tx_prbs_set     ,-- set new prbs / bit pattern
    prbs_type  => tx_prbs_type    ,-- type of prbs / bit pattern
    prbs_inv   => tx_prbs_inv     ,-- invert prbs pattern
    err_insert => tx_err_insert   ,-- manual error insert
    err_set    => tx_err_set      ,-- set new error type
    err_type   => tx_err_type     ,-- error type
    tx_bit     => tx_bit           -- tx serial output
  );

--! channel

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

-- core assignments
stream_rx_dat <= tx_bit;
stream_rx_ena <= tx_clk_en;

rx_bit        <= stream_tx_dat;
rx_clk_en     <= stream_tx_ena;

--! reciever
i_prbs_rx_ser : entity work.prbs_rx_ser
  port map (
    clk        => clk           , -- synchron clock
    reset      => rst           , -- asynchron reset
    clk_en     => rx_clk_en     , -- clock enable
    rx_bit     => rx_bit        , -- rx serial input
    prbs_set   => rx_prbs_set   , -- set new prbs / bit pattern
    prbs_type  => rx_prbs_type  , -- type of prbs / bit pattern
    prbs_inv   => rx_prbs_inv   , -- invert prbs pattern
    syn_state  => rx_syn_state  , -- synchronisation state output
    syn_los    => rx_syn_los    , -- sync loss signaling output
    bit_err    => rx_bit_err    , -- biterror signaling output
    clk_err    => rx_clk_err      -- clockerror (bitslip) signaling output
  );

end architecture rtl;