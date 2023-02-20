--------------------------------------------------------------------
--================= https://github.com/dhmarinov =================--
--------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pckg_fir.all;

entity fir is
    generic (
        filter_taps  : integer range 4  to 16 := 16;
        input_width  : integer range 8  to 25 := 8;
        coeff_width  : integer range 16 to 16 := 16;
        output_width : integer range 8  to 43 := 16
    );
    port (
           clk    : in std_logic;
           rst    : in std_logic;
           enable : in std_logic;
           data_i : in std_logic_vector (input_width-1 downto 0);
           data_o : out std_logic_vector (output_width-1 downto 0)
           );
end fir;

architecture behavioral of fir is

attribute use_dsp : string;
attribute use_dsp of behavioral : architecture is "yes";

constant mac_width : integer := coeff_width+input_width;

type input_registers  is array(0 to filter_taps-1) of signed(input_width-1 downto 0);
type mult_registers   is array(0 to filter_taps-1) of signed(input_width+coeff_width-1 downto 0);
type dsp_registers    is array(0 to filter_taps-1) of signed(mac_width-1 downto 0);
type coeff_registers  is array(0 to filter_taps-1) of signed(coeff_width-1 downto 0);

signal areg_s  : input_registers  ;
signal mreg_s  : mult_registers   ;
signal preg_s  : dsp_registers    ;
signal breg_s  : coeff_registers  ;

begin

data_o <= std_logic_vector(preg_s(0)(mac_width-1 downto mac_width-output_width));


process(clk)
begin

if rising_edge(clk) then

    if (rst   = '1') then
        for i in 0 to filter_taps-1 loop
            areg_s(i) <=(others=> '0');
            mreg_s(i) <=(others=> '0');
            preg_s(i) <=(others=> '0');
        end loop;

        for i in 0 to filter_taps-1 loop
            breg_s(i) <= to_signed( c_16_taps_lpf_2(i) , 16);
        end loop;

    else

      for i in 0 to filter_taps-1 loop
            areg_s(i) <= signed(data_i);

            if (i < filter_taps-1) then
                mreg_s(i) <= areg_s(i)*breg_s(i);
                preg_s(i) <= mreg_s(i) + preg_s(i+1);

            elsif (i = filter_taps-1) then
                mreg_s(i) <= areg_s(i)*breg_s(i);
                preg_s(i)<= mreg_s(i);
            end if;
        end loop;
    end if;

end if;
end process;

end behavioral;