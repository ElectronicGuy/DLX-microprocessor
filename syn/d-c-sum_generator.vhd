library ieee; 
use ieee.std_logic_1164.all; 
use work.globals.all;

entity sum_generator is
	Generic(	N  : integer:= NumBit_sg;
             	L  : integer:= NumBit_rca);
	Port (		Ci : in  std_logic_vector (N/L downto 1);
		 		A  : in  std_logic_vector (N downto 1);
		  		B  : in  std_logic_vector (N downto 1);
		  		S  : out std_logic_vector (N downto 1));

end entity sum_generator;

architecture STRUCTURAL of sum_generator is
	
    component carry_select
	Generic(N  : integer := NumBit_rca);
	Port (	A  : in std_logic_vector(N downto 1);
	      	B  : in std_logic_vector(N downto 1);
	      	Cic: in std_logic;
            S  : out std_logic_vector(N downto 1));
	end component;  
begin 

  gen: for I in 1 to NumBit_sg/NumBit_rca generate

	csb : carry_select port map (	A  => A(4*I downto 4*(I-1)+1), 
					   				B  => B(4*I downto 4*(I-1)+1), 
  					   				S  => S(4*I downto 4*(I-1)+1),
			  		   				Cic=> Ci(I));
  end generate;
end architecture STRUCTURAL;

