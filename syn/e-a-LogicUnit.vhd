library ieee;
use ieee.std_logic_1164.all;

entity NAND3 is
	port(A,B,C: in std_logic;
			Y: out std_logic);
end entity;
architecture Behavioural of NAND3 is
	signal out1: std_logic;
begin
	out1<= A nand B;
	Y<= out1 nand C;
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity NAND4 is
	port(A,B,C,D: in std_logic;
			Y: out std_logic) ;
end entity;

architecture Behavioural of NAND4 is
	signal sigout1,sigout2: std_logic;
begin
	sigout1<= A nand B;
	sigout2<= C nand D;
	Y<= sigout1 nand sigout2;
end architecture;


library ieee;
use ieee.std_logic_1164.all;

entity Logic_Unit is 
	generic (N: integer);
	port 	(R1,R2: in std_logic_vector(N-1 downto 0);
			S1,S2,S3,S0: in std_logic;
			Y : out std_logic_vector(N-1 downto 0));
end entity;

architecture Structural of Logic_Unit is
	component NAND4 is
		port(A,B,C,D: in std_logic;
				Y: out std_logic);
	end component;

	component NAND3 is
	port	(A,B,C: in std_logic;
			Y: out std_logic);
	end component;
	signal L1,L2,L3,L0, L5: std_logic_vector(N-1 downto 0);
	signal inv_R1, inv_R2 : std_logic_vector(N-1 downto 0);
begin 
	inv_R1 <= not(R1);
	inv_R2 <= not(R2);

	Gen1: for i in 0 to N-1 generate
	begin
	Nand3_1:NAND3 port map (A=> S0,
							B=> inv_R1(i),
							C=> inv_R2(i),
							Y=> L0(i));
	Nand3_2:NAND3 port map (A=> S1,
							B=> inv_R1(i),
							C=> R2(i),
							Y=> L1(i));
	Nand3_3:NAND3 port map (A=> S2,
							B=> R1(i),
							C=> inv_R2(i),
							Y=> L2(i));
	Nand3_4:NAND3 port map (A=> S3,
							B=> R1(i),
							C=> R2(i),
							Y=> L3(i));

	Nand4_0:NAND4 port map(	A=> L0(i),
							B=> L1(i),
							C=> L2(i),
							D=> L3(i),
							Y=> L5(i) );
	end generate;

	y <= L5;
end architecture;


							
	




















	
