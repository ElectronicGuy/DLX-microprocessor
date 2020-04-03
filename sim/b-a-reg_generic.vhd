library IEEE;
use IEEE.std_logic_1164.all; 

entity FD_s is
	port (	D, CLK, RST, EN : in std_logic;
			Q:	out	std_logic);
end FD_s;

architecture Structural_Synchronous of FD_s is -- flip flop D with syncronous reset
begin
	PSYNCH: process(CLK)
	begin
	  if ( CLK'event and CLK = '1' ) then -- positive edge triggered:
	    if RST='1' then -- active high reset 
	      Q <= '0'; 
	    elsif (EN = '1') then
	      Q <= D; -- input is written on output
	    end if;
	  end if;
	end process;

end architecture;

-----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all; 
use WORK.globals.all;

entity reg_generic is 
	generic (N: integer );
	port(	D	:	in	std_logic_vector(N-1 downto 0);
			CLK, RST, EN : 	in	std_logic;
			Q	:	out std_logic_vector(N-1 downto 0));
end entity reg_generic;

architecture Structural_Synchronous of reg_generic is
	component FD_S
		port (	D, CLK, RST, EN : in std_logic;
				Q:	out	std_logic);
	end component;
begin

	Gen : for i in 0 to N-1 generate
	begin
		UFD: FD_s port map (D => D(i), CLK => CLK, RST => RST, EN => EN, Q => Q(i));
	end generate Gen;
end architecture;
