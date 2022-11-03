------------------------------------------------------------------------------
--  package for the lfsr designs
--  rev. 1.0 : 2022 Provoost Kris
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package pckg_lfsr is

function xor_reduce         (x: std_logic_vector)         return std_logic;   
function xor_reduce_masked  (x, mask: std_logic_vector)   return std_logic;
   
end pckg_lfsr;

package body pckg_lfsr is
 
function xor_reduce(x: std_logic_vector) return std_logic is
 variable result: std_logic;
begin
 result := '0';
 for i in x'range loop
   result := result xor x(i);
 end loop;
 return result;
end xor_reduce;

function xor_reduce_masked (x, mask: std_logic_vector) return std_logic is
variable result: std_logic; 
begin
 result := '0';  
 for i in mask'range loop
   result := result xor ( x(i) and mask(i) );
 end loop;
 return result;
end xor_reduce_masked;
   
end pckg_lfsr;