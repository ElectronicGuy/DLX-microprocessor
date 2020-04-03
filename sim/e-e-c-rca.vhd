-- This is a slightly modified version of the rca_generic of cap1
-- It does not have the Ci and Co capabilities, and it is only an adder (not subtractor)
library ieee; 
use ieee.std_logic_1164.all; 

entity rca is 
  generic( N : integer );
  port (   A : In  std_logic_vector(N-1 downto 0);
	   B : In  std_logic_vector(N-1 downto 0);
	   S : Out std_logic_vector(N-1 downto 0);
           Co: out std_logic );
end rca; 

architecture structural of rca is

  signal STMP : std_logic_vector(N-1 downto 0);
  signal CTMP : std_logic_vector(N   downto 0);
  signal Bxor : std_logic_vector(N-1 downto 0);

  component FA 
  Port ( A:	In	std_logic;
	 B:	In	std_logic;
	 Ci:	In	std_logic;
	 S:	Out	std_logic;
	 Co:	Out	std_logic);
  end component; 

  component HA
  Port (	A:	In	std_logic;
		B:	In	std_logic;
		S:	Out	std_logic;
		Co:	Out	std_logic);
  end component;

begin

  S <= STMP;
  Co <= CTMP(N);
  
  HA_0 : HA port map (A => A(0), B => B(0), S => STMP(0), Co => CTMP(1)); 

  gen : for I in 2 to N generate  
    FA_i: FA port map (A => A(I-1), B => B(I-1), Ci => CTMP(I-1), S => STMP(I-1), Co => CTMP(I)); 
  end generate;

end structural;
