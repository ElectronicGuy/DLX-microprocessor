library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MUX51_GENERIC is
	Generic (N: integer);
	Port (	A:	In	std_logic_vector(N-1 downto 0);
			B:	In	std_logic_vector(N-1 downto 0);
			C:	In	std_logic_vector(N-1 downto 0);
			D:	In	std_logic_vector(N-1 downto 0);
			E:	In	std_logic_vector(N-1 downto 0);
			SEL:In	std_logic_vector(2 downto 0);
			Y:	Out	std_logic_vector(N-1 downto 0));
end entity;

architecture Behavioral of MUX51_GENERIC is
begin
	process(A,B,C,D,E,SEL)
	begin
		if(SEL = "000") then
			Y<= A;
		elsif(SEL = "001") then
			Y<= B;
		elsif(SEL = "010") then
			Y<= C;
		elsif (SEL = "011") then
			Y<= D;
		else
			Y<= E;
		end if;
	end process;
end architecture;
