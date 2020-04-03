library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globals.all;

entity zero_detector is
	generic ( 	N	: integer := Numbit);
	port (		A	: in std_logic_vector(Numbit-1 downto 0);
				YE	: out std_logic ); 
end entity;

architecture Behavioral of zero_detector is
begin 

	process(A) is
		begin
		if (to_integer(unsigned(A))=0) then
			YE <= '1';
		else
			YE <= '0';
		end if;
	end process;
	
end architecture;
