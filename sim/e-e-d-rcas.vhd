-- This is a slightly modified version of the rca_generic of cap1
-- Now it is an adder/subtractor
library ieee; 
use ieee.std_logic_1164.all; 

entity rcas is 
  generic( N : integer );
  port (   A : In std_logic_vector(N-1 downto 0);
	   B : In std_logic_vector(N-1 downto 0);
	   add_sub: in std_logic; 
	   S : Out std_logic_vector(N-1 downto 0);
	   Co: out std_logic );
end rcas; 

architecture structural of rcas is

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

begin

  CTMP(0) <= add_sub;
  S <= STMP;
  Co <= CTMP(N);
  
  gen_rcas: for I in 1 to N generate
    Bxor(I-1) <= B(I-1) xor add_sub;    
    
    FA_i : FA port map (A => A(I-1), 
			B => Bxor(I-1),
			Ci => CTMP(I-1),
			S => STMP(I-1),
			Co => CTMP(I) ); 
  end generate;

end structural;
