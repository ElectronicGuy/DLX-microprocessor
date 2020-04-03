library ieee;
use ieee.std_logic_1164.all;


entity MUX21 is
	port (	A:	In	std_logic;
			B:	In	std_logic;
			SEL:In	std_logic;
			Y:	Out	std_logic);
end entity;

architecture Behavioral of MUX21 is
begin
	Y <= A when SEL = '1' else B;
end architecture;
