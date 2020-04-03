library ieee;
use ieee.std_logic_1164.all;
use work.globals.all;

entity P4adder is
	Generic (	N: integer := NumBit_sg;
                M: integer := NumBit_rca);
  	Port (	A, B : in  std_logic_vector (N downto 1);
        	Y    : out std_logic_vector (N downto 1);
            Ci   : in std_logic;
            Co   : out std_logic );
end entity;

architecture Structural of P4adder is

  component sparse_tree
  Generic (	N:		integer := 32; 	-- #bits (length) of operand A and B
			Nc: 	integer	:= 4); 	-- #bits between each carry generated
	Port (	A: in  	std_logic_vector (N downto 1);
			B: in  	std_logic_vector (N downto 1);
			C: out 	std_logic_vector (N/Nc downto 1);
            Cin : in std_logic );
  end component;

  component sum_generator
  Generic(	N  : integer:= NumBit_sg;
            L  : integer:= NumBit_rca);
  Port (	Ci : in  std_logic_vector (N/L downto 1);
		 	A  : in  std_logic_vector (N downto 1);
		  	B  : in  std_logic_vector (N downto 1);
		  	S  : out std_logic_vector (N downto 1));

  end component; 

  signal carry_sig : std_logic_vector (8 downto 1);
  signal temp      : std_logic_vector (8 downto 1);
begin 

  tree : sparse_tree generic map (N => N, Nc => M) port map (A => A, B => B, C => carry_sig, Cin => Ci);
  
  temp <= carry_sig(N/M-1 downto 1) & Ci;

  sg0: sum_generator generic map (N => N, L  => M) port map (Ci => temp, A => A, B => B, S => Y);
  
  Co <= carry_sig(N/M);
end architecture Structural;      
