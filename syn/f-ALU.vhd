library ieee;
use ieee.std_logic_1164.all;															----------- 8 bit: SSS A LLLL
use work.globals.all;																						--- shifter => SR LR LA (SSS)

entity ALU is
	generic(N: integer);
	port(	ALU_OPCODE			: in std_logic_vector(7 downto 0);
			A, B				: in std_logic_vector(N-1 downto 0);
			Y_ADDER				: out std_logic_vector (N-1 downto 0);
			Y_SHIFT				: out std_logic_vector (N-1 downto 0);
			Y_LOGIC				: out std_logic_vector (N-1 downto 0);
			Y_MULT				: out std_logic_vector (N-1 downto 0);
			ne,ge,le,ee			: out std_logic);
end entity;

architecture Structural of ALU is

	component Logic_Unit  
	generic (N: integer);
	port 	(R1,R2: in std_logic_vector(N-1 downto 0);
			S1,S2,S3,S0: in std_logic;
			Y : out std_logic_vector(N-1 downto 0));
	end component;

	component P4adder_subtr 
	generic (	N: integer := NumBit_sg;
                M: integer := NumBit_rca);
  	port (	A, B : in  std_logic_vector (N downto 1);
        	Y    : out std_logic_vector (N downto 1);
            SEL  : in std_logic;
            Co   : out std_logic );
	end component;

	component comparator
  	port ( SUB  : in std_logic_vector(NumBit-1 downto 0);
          Cout : in std_logic;
          ne, ge, le,ee : out std_logic );
	end component;

	component  SHIFTER_GENERIC
		generic(N: integer);
		port(	A: in std_logic_vector(N-1 downto 0);
				B: in std_logic_vector(4 downto 0);
				LOGIC_ARITH: in std_logic;	-- 1 = logic, 0 = arith
				LEFT_RIGHT: in std_logic;	-- 1 = left, 0 = right
				SHIFT_ROTATE: in std_logic;	-- 1 = shift, 0 = rotate
				OUTPUT: out std_logic_vector(N-1 downto 0) );
	end component;

	component boothmul
  		generic(	N : integer := 32;   -- number of bits of multiplier A
        	   		M : integer := 8 );  -- number of bits of multiplicand B
  		port ( 		Am : in std_logic_vector(N-1 downto 0);
	 				Bm : in std_logic_vector(M-1 downto 0);
         			Pm : out std_logic_vector(N+M-1 downto 0) );
	end component;
	
	signal carry: std_logic;
	signal P4_out: std_logic_vector(Numbit-1 downto 0);
begin
	Logic_unit_exe: Logic_Unit 	generic map(N=>NumBit) 
								port map(	R1=>A,
											R2=>B,
											S0=>Alu_opcode(3),
											S1=>Alu_opcode(2),
											S2=>Alu_opcode(1),
											S3=>Alu_opcode(0),
											Y=>Y_LOGIC);

	P4Adder_exe: P4adder_subtr generic map(	N=>Numbit,
											M=>NumBit_rca)
							port map(		A=>A,
											B=>B,
											SEL=>ALU_OPCODE(4),
											Co=> carry,
											Y=>P4_out);

	Y_ADDER <= P4_out;

	Comparator_exe: comparator 
							 port map(		SUB=>P4_out,
											Cout=>carry,
											ne=>ne,
											ge=>ge,
											le=>le,
											ee=>ee);

	Shifter_exe: SHIFTER_GENERIC generic map(	N=>NumBit)
								port map( 		A				=> A,
												B				=> B(4 downto 0),
												LOGIC_ARITH		=> ALU_OPCODE(7),
												LEFT_RIGHT		=> ALU_OPCODE(6),
												SHIFT_ROTATE	=> ALU_OPCODE(5),
												OUTPUT			=> Y_SHIFT);
	mult_exe: 	boothmul 	generic map ( 	N	=> N/2,
											M 	=> N/2 )
							port map(		Am	=> A(N/2-1 downto 0),	
											Bm	=> B(N/2-1 downto 0),
											Pm 	=> Y_MULT );
	
end architecture;					
