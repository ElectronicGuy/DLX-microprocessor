library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.globals.all;

entity Add4 is
	generic (N : integer);
	port(	A	:	in std_logic_vector(Numbit-1 downto 0);
	 		Y	:	out std_logic_vector(Numbit-1 downto 0));
end entity;

Architecture Behaviour of Add4 is
	-- signal B : std_logic_vector( NumBit -1 downto 0) := std_logic_vector(to_unsigned(4,Numbit));
begin
--	B <= std_logic_vector(to_unsigned(4,Numbit));
	Y <= A+std_logic_vector(to_unsigned(4,Numbit));	
end architecture;

