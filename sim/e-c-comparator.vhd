library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.globals.all;
-- small logic connected after the adder.
-- used to spot >= <= !=

entity comparator is
  port (  SUB  : in std_logic_vector(NumBit-1 downto 0);
          Cout : in std_logic;
          ne, ge, le,ee : out std_logic );
end entity;

architecture Behavioral of comparator is	signal sub_int : integer;
	signal nor_res : std_logic;
begin
	sub_int <= to_integer(unsigned(SUB));
	nor_res <= '1' when sub_int = 0 else '0';
	
  ne <= not(nor_res);
  ge <= Cout;
  le <= not(Cout) or nor_res;
  ee<= nor_res;

end architecture;
