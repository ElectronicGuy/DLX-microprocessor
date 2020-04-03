library ieee;
use ieee.std_logic_1164.all;


entity MUX21_GENERIC is
	Generic (N: integer);
	Port (	A:	In	std_logic_vector(N-1 downto 0);
			B:	In	std_logic_vector(N-1 downto 0);
			SEL:In	std_logic;
			Y:	Out	std_logic_vector(N-1 downto 0));
end entity;

architecture Behavioral of MUX21_GENERIC is
begin
	Y <= A when SEL = '1' else B;
end architecture;
