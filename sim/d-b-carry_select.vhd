library ieee; 
use ieee.std_logic_1164.all; 
use work.globals.all;

entity  carry_select is

	Generic(N  : integer := 4);
	Port (	A  : in std_logic_vector(N downto 1);
	      	B  : in std_logic_vector(N downto 1);
	      	Cic: in std_logic;
              	S  : out std_logic_vector(N downto 1));
	   
end entity carry_select;
	
architecture STRUCTURAL of carry_select is
	
	component rca_gen  
	generic(N  :    integer := 4);
	Port (	A  :	In	std_logic_vector(N downto 1);
		B  :	In	std_logic_vector(N downto 1);
		Ci :	In	std_logic;
		S  :	Out	std_logic_vector(N downto 1);
		Co :	Out	std_logic);
	end component; 

	component mux21_generic 
	generic (N : integer := 4);
   	port ( A         : in  std_logic_vector (N downto 1);
        	 B         : in  std_logic_vector (N downto 1);
         	Y         : out std_logic_vector (N downto 1);
        	 SEL       : in  std_logic );
	end component;
	
	signal sumtop, sumbot : std_logic_vector(N downto 1); 

begin

	rca_top: rca_gen port map (Ci=> '0', A => A, B => B, S => sumtop);

	rca_bot: rca_gen port map (Ci=> '1', A => A, B => B, S => sumbot);

	mux : mux21_generic	 generic map (N => 4) port map (A => sumbot, B => sumtop, SEL => Cic, Y => S);

end architecture STRUCTURAL;
