library ieee; 
use ieee.std_logic_1164.all;
use work.globals.all; 

entity FA is 
	Port (	A:	In	std_logic;
		B:	In	std_logic;
		Ci:	In	std_logic;
		S:	Out	std_logic;
		Co:	Out	std_logic);
end FA; 

architecture BEHAVIORAL of FA is
begin

  S <= A xor B xor Ci ;
  Co <= (A and B) or (B and Ci) or (A and Ci);
  
end BEHAVIORAL;

--------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all; 
use work.globals.all;

entity rca_gen is 
	generic(N  :    integer := NumBit_rca);
	Port (	A  :	In	std_logic_vector(N downto 1);
		B  :	In	std_logic_vector(N downto 1);
		Ci :	In	std_logic;
		S  :	Out	std_logic_vector(N downto 1);
		Co :	Out	std_logic);
end rca_gen; 

architecture STRUCTURAL of rca_gen is

  signal STMP : std_logic_vector(N downto 1);
  signal CTMP : std_logic_vector(N+1 downto 1);

  component FA 
  Port ( A:	In	std_logic;
	 B:	In	std_logic;
	 Ci:	In	std_logic;
	 S:	Out	std_logic;
	 Co:	Out	std_logic);
  end component; 

begin

  CTMP(1) <= Ci;
  S <= STMP;
  Co <= CTMP(N+1);
  
  gen : for I in 2 to N+1 generate
    FA_i : FA port map (A => A(I-1), B => B(I-1), Ci => CTMP(I-1), S => STMP(I-1), Co => CTMP(I)); 
  end generate;

end STRUCTURAL;
