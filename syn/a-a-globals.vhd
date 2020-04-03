library ieee;
use ieee.std_logic_1164.all;
package FUNCTIONS is
   	
	function ceil_log2 (x : integer) return integer;
   
end FUNCTIONS;

package body FUNCTIONS is
   function ceil_log2 (x : integer) return integer is
      variable i : natural;
   begin
      i := 0;  
      -- Majority of OSs us 32 bits (4 bytes) to represent an integer. 
	  -- For this reason more than 32 cycles are useless.
      while (2**i < x) and i < 31 loop  
         i := i + 1;
      end loop;
      return i;
   end function;
	
end FUNCTIONS;

------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use WORK.functions.all;

package globals is
	constant	NumBit 	: integer:=32 ;
-----------------RegisterFile----------
	constant	tot_regs : integer := 80;
	constant 	ADD_LENGTH : integer := ceil_log2(tot_regs);
-----------------P4 adder-----------
 	constant NumBit_sg : integer := 32;
  	constant NumBit_rca: integer := 4;	

end globals;

