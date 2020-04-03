library IEEE;
use IEEE.std_logic_1164.all;

entity PG is
	Port ( Pa, Ga : in  std_logic;
	       Pb, Gb : in  std_logic;
	       Py, Gy : out std_logic );
end entity PG;

architecture Behavioral of PG is
begin
	Py <= Pa and Pb;
	Gy <= Ga or (Pa and Gb);

end architecture Behavioral;

----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity G is
	Port ( Pa, Ga : in  std_logic;
	       Gb :     in  std_logic;
	       Gy :     out std_logic );
end entity G;

architecture Behavioral of G is
begin
	Gy <= Ga or (Pa and Gb);
	
end architecture Behavioral;

----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.globals.all;
use work.functions.all;

entity sparse_tree is
	Generic (	N:		integer := 32; 	-- #bits (length) of operand A and B
				Nc: 	integer	:= 4); 	-- #bits between each carry generated
	Port (		A: in  	std_logic_vector (N downto 1);
				B: in  	std_logic_vector (N downto 1);
				C: out 	std_logic_vector (N/Nc downto 1); 
                Cin : in std_logic );
end entity sparse_tree;

architecture STRUCTURAL of sparse_tree is

	-- the sparse tree can be divided into two blocks:
	-- 1) the first log2(Nc) rows are connected following a "regular" path
	-- 2) the second log2(#elements in the last row of FirstBlock) rows
	-- follow more complex connection rules, that depends case by case
	-- by the choice on the K value.
	constant rows_fb : integer := ceil_log2(Nc);
	constant rows_sb : integer := ceil_log2(N/(2*rows_fb));

	type myarray is array (rows_fb+rows_sb downto 0) of std_logic_vector (N downto 1);

	signal arrayP : myarray; -- propagate
	signal arrayG : myarray; -- generate

	component PG
	Port ( Pa, Ga : in  std_logic;
	       Pb, Gb : in  std_logic;
	       Py, Gy : out std_logic );
	end component;

	component G
	Port ( Pa, Ga : in  std_logic;
	       Gb :     in  std_logic;
	       Gy :     out std_logic );
	end component;
begin

	arrayP(0)(1) <= A(1) xor B(1) xor Cin;
    arrayG(0)(1) <= (A(1) and B(1)) or (A(1) and Cin) or (B(1) and Cin);

	PGnetwork : for I in 2 to N generate
		arrayP(0)(I) <= A(I) xor B(I);
		arrayG(0)(I) <= A(I) and B(I);
	end generate;

	FirstBlock: for J in 1 to rows_fb+1 generate
	begin
		cols_fb : for I in 1 to N/(2**J) generate  --by considering two adiacent columns every loop iteration, they are halved at each iteration
		begin
			first_col_fb: if (I = 1) generate
			begin
				GG_i: G  port map (	Pa => arrayP(J-1)((2**J)*I),
					     	   		Ga => arrayG(J-1)((2**J)*I),
					           		Gb => arrayG(J-1)((2**J)*I - 2**(J-1)),
					     	   		Gy => arrayG(J)((2**J)*I) );
		  	end generate;
		  
		  	other_cols_fb: if (I /= 0) generate 
		  	begin
        		PG_i: PG port map (	Pa => arrayP(J-1)((2**J)*I),
						   			Ga => arrayG(J-1)((2**J)*I),
									Pb => arrayP(J-1)((2**J)*I - 2**(J-1)),
					     	   		Gb => arrayG(J-1)((2**J)*I - 2**(J-1)),
					     	   		Py => arrayP(J)((2**J)*I),
									Gy => arrayG(J)((2**J)*I));
		  	end generate;
		end generate;
	end generate;
	
	C(1) <= arrayG(rows_fb)(Nc);
	C(2) <= arrayG(rows_fb+1)(2*Nc);

	SecondBlock : for J in rows_fb+2 to rows_sb+rows_fb generate
	begin
		cols_sb: for I in 1 to N/(2**J) generate
		begin
			first_col_sb: if (I = 1) generate
			begin
      			G_i: G  port map (	Pa => arrayP(J-1)((2**J)*I),
									Ga => arrayG(J-1)((2**J)*I),
						   			Gb => arrayG(J-1)((2**J)*I - 2**(J-1)),
						   			Gy => arrayG(J)((2**J)*I));
				
				C((2**J)*I/Nc) <= arrayG(J)((2**J)*I);

				extra_col_g_same_level: for L in 1 to (2**(J-rows_fb-2) -1) generate
				begin
					G_i: G port map (	Pa => arrayP(J-1)((2**J)*I - L*Nc),
			 				 			Ga => arrayG(J-1)((2**J)*I - L*Nc),
							 			Gb => arrayG(J-1)((2**J)*I - 2**(J-1)),
        				                Gy => arrayG(J)((2**J)*I - L*Nc));
					
					C(((2**J)*I - L*Nc)/Nc) <= arrayG(J)((2**J)*I - L*Nc);

				end generate;

       			extra_col_g_upper_level: for L in 1 to (2**(J-rows_fb-2)) generate
					signal temp1, temp2 : std_logic;
				begin
					temp1 <= arrayP(J-1-L)((2**J)*I - L*Nc - (2**(J-rows_fb-2) -1)*Nc);
					temp2 <= arrayG(J-1-L)((2**J)*I - L*Nc - (2**(J-rows_fb-2) -1)*Nc);
					
					G_i: G port map (	Pa => temp1,
							 			Ga => temp2,
							 			Gb => arrayG(J-1)((2**J)*I - 2**(J-1)),
                           				Gy => arrayG(J)((2**J)*I - L*Nc - (2**(J-rows_fb-2) -1)*Nc));
					
					C(((2**J)*I - L*Nc - (2**(J-rows_fb-2) -1)*Nc)/Nc) <= arrayG(J)((2**J)*I- L*Nc - (2**(J-rows_fb-2) -1)*Nc);

        		end generate;
		  	end generate;

			other_cols_sb: if (I /= 1) generate
			begin
				PG_i: PG port map (	Pa => arrayP(J-1)((2**J)*I),
						   			Ga => arrayG(J-1)((2**J)*I),
						   			Pb => arrayP(J-1)((2**J)*I - 2**(J-1)),
						   			Gb => arrayG(J-1)((2**J)*I - 2**(J-1)),
						   			Py => arrayP(J)((2**J)*I),
                           			Gy => arrayG(J)((2**J)*I));

			  	extra_col_pg_same_level: for L in 1 to (2**(J-rows_fb-2) -1) generate
				begin
					PG_i: PG port map (	Pa => arrayP(J-1)((2**J)*I - L*Nc),
							   			Ga => arrayG(J-1)((2**J)*I - L*Nc),
							   			Pb => arrayP(J-1)((2**J)*I - 2**(J-1)),
							   			Gb => arrayG(J-1)((2**J)*I - 2**(J-1)),
							   			Py => arrayP(J)((2**J)*I - L*Nc),
	                         			Gy => arrayG(J)((2**J)*I - L*Nc));
				end generate;

	      		extra_col_pg_upper_level: for L in 1 to (2**(J-rows_fb-2)) generate
					signal temp1, temp2 : std_logic;
				begin
					temp1 <= arrayP(J-1-L)((2**J)*I - L*Nc - (2**(J-rows_fb-2) -1)*Nc);
					temp2 <= arrayG(J-1-L)((2**J)*I - L*Nc - (2**(J-rows_fb-2) -1)*Nc);
	        		PG_i: PG port map (	Pa => temp1,
			 				   			Ga => temp2,
							   			Pb => arrayP(J-1)((2**J)*I - 2**(J-1)),
							   			Gb => arrayG(J-1)((2**J)*I - 2**(J-1)),
							   			Py => arrayP(J)((2**J)*I - L*Nc),
	                         			Gy => arrayG(J)((2**J)*I - L*Nc));
	      		end generate;
		  	end generate;
		end generate;
	end generate;

end architecture STRUCTURAL;
