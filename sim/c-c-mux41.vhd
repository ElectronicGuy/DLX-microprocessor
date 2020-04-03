library ieee;
use ieee.std_logic_1164.all;


entity MUX41 is

	Port (	A:	In	std_logic;
			B:	In	std_logic;
			C:	In	std_logic;
			D:	In	std_logic;
			SEL:In	std_logic_vector(1 downto 0);
			Y:	Out	std_logic);
end entity;

architecture Behavioral of MUX41 is
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
