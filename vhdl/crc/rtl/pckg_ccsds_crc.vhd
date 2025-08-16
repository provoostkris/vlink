------------------------------------------------------------------------------
--  package for the crc functions
--  rev. 1.0 : 2023 Provoost Kris
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package pckg_ccsds_crc is


  function crc16_ccsds_byte(
    crc_in  : std_logic_vector(15 downto 0);
    data_in : std_logic_vector(7 downto 0)
  ) return std_logic_vector;

end pckg_ccsds_crc;

package body pckg_ccsds_crc is
 
  --  Description : VHDL implementatie van het CCSDS CRC-16 algoritme.
  --                Gebaseerd op de specificaties van CCSDS 101.0-B-6.
  --
  --  Algoritme   : Cyclic Redundancy Check (CRC-16)
  --  Breedte     : 16 bits
  --  Polynomiaal : x^16 + x^12 + x^5 + 1 (hex: 0x1021)
  --  Init waarde : 0xFFFF
  --  XOR output  : Geen (0x0000)
  --  Reflectie   : Geen reflectie op input of output

  function crc16_ccsds_byte(
    crc_in  : std_logic_vector(15 downto 0);
    data_in : std_logic_vector(7 downto 0)
  ) return std_logic_vector is
      constant POLY : std_logic_vector(15 downto 0) := x"1021";
      variable crc  : std_logic_vector(15 downto 0) := crc_in;
      variable din  : std_logic_vector(7 downto 0) := data_in;
  begin
      for i in 0 to 7 loop
          if (crc(15) xor din(7 - i)) = '1' then
              crc := (crc(14 downto 0) & '0') xor POLY;
          else
              crc := crc(14 downto 0) & '0';
          end if;
      end loop;
      return crc;
  end function;
  
end pckg_ccsds_crc;