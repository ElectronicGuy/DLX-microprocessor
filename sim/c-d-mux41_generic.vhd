library ieee;
use ieee.std_logic_1164.all;


entity MUX41_GENERIC is
	Generic (N: integer);
	Port (	A:	In	std_logic_vector(N-1 downto 0);
			B:	In	std_logic_vector(N-1 downto 0);
			C:	In	std_logic_vector(N-1 downto 0);
			D:	In	std_logic_vector(N-1 downto 0);
			SEL:In	std_logic_vector(1 downto 0);
			Y:	Out	std_logic_vector(N-1 downto 0));
end entity;

architecture Behavioral of MUX41_GENERIC is
begin
	process(A,B,C,D,SEL)
	begin
		if(SEL(0)= '0' and SEL(1)= '0') then
			Y<= A;
		elsif(SEL(0)= '1' and SEL(1)= '0') then
			Y<= B;
		elsif(SEL(0)= '0' and SEL(1)= '1') then
			Y<= C;
		else
			Y<= D;
		end if;
	end process;
end architecture;
