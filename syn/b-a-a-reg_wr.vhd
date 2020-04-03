library ieee;
use ieee.std_logic_1164.all; 

entity reg_wr is 
	port(		D	:	in	std_logic_vector(5 downto 0);
				CLK, RST, EN : 	in	std_logic;
				Q	:	out std_logic_vector(5 downto 0));
end entity;

architecture Behavioral_synch of reg_wr is	
begin

	reg_complet_proc : process(CLK)
	begin
	  if ( CLK'event and CLK = '1' ) then -- positive edge triggered:
	    if RST='1' then -- active high reset 
	      Q <= "100000"; -- nop with dirty bit; 
	    elsif (EN = '1') then
	      Q <= D; -- input is written on output
	    end if;
	  end if;
	end process;

end architecture;
