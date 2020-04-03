library ieee;
use ieee.std_logic_1164.all;
use work.globals.all;

entity P4adder_subtr is
	generic (	N: integer := NumBit_sg;
                M: integer := NumBit_rca);
  	port (	A, B : in  std_logic_vector (N downto 1);
        	Y    : out std_logic_vector (N downto 1);
            SEL  : in std_logic;
			Co   : out std_logic );
end entity;

architecture Structural of P4adder_subtr is
	
	component P4adder
		generic (	N: integer := NumBit_sg;
         	       	M: integer := NumBit_rca);
  		port (	A, B : in  std_logic_vector (N downto 1);
        		Y    : out std_logic_vector (N downto 1);
            	Ci   : in std_logic;
            	Co   : out std_logic );
	end component;
	
	signal xor_B : std_logic_vector(N downto 1);
begin
	xor_gen: for i in 1 to N generate
		xor_B(i) <= B(i) xor SEL;
	end generate;

	P4add : P4adder generic map(N => NumBit, M => 4) 
					port map(	A => A,
								B => xor_B,
								Y => Y,
								Ci => SEL,
								Co=>Co );								
end architecture;
