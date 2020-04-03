library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Impornat note: in order to avoid overflow, the result is computed on a larger number of bits (with respect to the input values).
-- The math is very simple: (2^n)(2^m) = 2^(n+m), and this means that (in general) we need N+M bits to represent correctly the result.
-- In the special case N=M the rule is still valid (of course) and the reuslt should be represented on 2*N bits 

entity boothmul is
  generic (N : integer := 32;   -- number of bits of multiplier A
           M : integer := 8 );  -- number of bits of multiplicand B
  port ( Am : in std_logic_vector(N-1 downto 0);
	 Bm : in std_logic_vector(M-1 downto 0);
         Pm : out std_logic_vector(N+M-1 downto 0) );
end entity;

architecture Structural of boothmul is

  signal negAm : std_logic_vector (N-1 downto 0);
  signal sig_enc : std_logic_vector(2 downto 0);
  
  type myarray  is array (M/2 -1 downto 0) of std_logic_vector (N+M-1 downto 0);
  signal sig_sum : myarray; 
  signal mux2add : myarray;
  signal sigB    : myarray;
  signal sigC    : myarray;
  signal sigD    : myarray;
  signal sigE    : myarray;
  
  type myarray2 is array (M/2 -1 downto 0) of std_logic_vector (2 downto 0);
  signal enc2mux : myarray2;

  component rcas
  generic( N : integer );
  port (   A : In std_logic_vector(N-1 downto 0);
	   B : In std_logic_vector(N-1 downto 0);
	   add_sub: in std_logic; 
	   S : Out std_logic_vector(N-1 downto 0);
	   Co: out std_logic );
  end component;

  component rca
  generic( N : integer );
  port (   A : In  std_logic_vector(N-1 downto 0);
	   B : In  std_logic_vector(N-1 downto 0);
	   S : Out std_logic_vector(N-1 downto 0);
           Co: out std_logic );
  end component;

  component mux5to1
  generic (N : integer);
  port ( A         : in  std_logic_vector (N-1 downto 0);
         B         : in  std_logic_vector (N-1 downto 0);
         C         : in  std_logic_vector (N-1 downto 0);
         D         : in  std_logic_vector (N-1 downto 0);
         E         : in  std_logic_vector (N-1 downto 0);
         Y         : out std_logic_vector (N-1 downto 0);
         SEL       : in  std_logic_vector (2 downto 0) );
  end component;
 
  component encoder 
  port ( X : in  std_logic_vector(2 downto 0);
         Y : out std_logic_vector(2 downto 0));
  end component;

begin

  sub_0: rcas generic map (N => N) port map (A => std_logic_vector(to_unsigned(0, N)), B => Am, add_sub => '1', S => negAm);
  
  gen : for I in 1 to M/2-1 generate 
   gen_0: if (I = 1) generate
	  sig_enc             <= Bm(1 downto 0) & '0'; -- Handling of the special case Bm(-1) = 0
  	  sigB(0)(N+1 downto 0) <= Am(N-1)    & Am(N-1)    & Am;
  	  sigC(0)(N+1 downto 0) <= negAm(N-1) & negAm(N-1) & negAm;  -- Keep attention to the sign extension!
	  sigD(0)(N+1 downto 0) <= Am(N-1)    & Am         & '0';
	  sigE(0)(N+1 downto 0) <= negAm(N-1) & negAm      & '0';
  
	  enc_0: encoder port map (X => sig_enc, Y => enc2mux(0));
	  
	  mux_0: mux5to1 generic map (N => N+2) port map (SEL => enc2mux(0), 
					          	    A => std_logic_vector(to_unsigned(0, N+2)),
						  	    B => sigB(0)(N+1 downto 0),
						  	    C => sigC(0)(N+1 downto 0),
						  	    D => sigD(0)(N+1 downto 0),
						  	    E => sigE(0)(N+1 downto 0),
                                                  	    Y => sig_sum(0)(N+1 downto 0) );
	end generate;

 	sigB(I)(N+(2*I)+1 downto 0) <= Am(N-1)    & Am(N-1)    & Am(N-1 downto 0)    & std_logic_vector(to_unsigned(0,2*I));
	sigC(I)(N+(2*I)+1 downto 0) <= negAm(N-1) & negAm(N-1) & negAm(N-1 downto 0) & std_logic_vector(to_unsigned(0,2*I)); 
	sigD(I)(N+(2*I)+1 downto 0) <= Am(N-1)                 & Am(N-1 downto 0)    & std_logic_vector(to_unsigned(0,(2*I)+1));
	sigE(I)(N+(2*I)+1 downto 0) <= negAm(N-1)              & negAm(N-1 downto 0) & std_logic_vector(to_unsigned(0,(2*I)+1));

	enc_i: encoder port map (X => Bm(2*I+1 downto 2*I-1), Y => enc2mux(I));
	mux_i: mux5to1 generic map (N => N + 2*I+2) port map (SEL => enc2mux(I), 
								A => std_logic_vector(to_unsigned(0, N+2*I+2)),
								B => sigB(I)(N+2*I+1 downto 0),
								C => sigC(I)(N+2*I+1 downto 0),
								D => sigD(I)(N+2*I+1 downto 0),
								E => sigE(I)(N+2*I+1 downto 0),
								Y => mux2add(I)(N+2*I+1 downto 0) );
	
	sig_sum(I-1)(N+2*I+1 downto N+2*I) <= sig_sum(I-1)(N+2*I-1) & sig_sum(I-1)(N+2*I-1); 
	add_i: rca generic map (N => N+ 2*I+2) port map (A => mux2add(I)(N+2*I+1 downto 0), 
							 B => sig_sum(I-1)(N+2*I+1 downto 0), 
							 S => sig_sum(I)(N+2*I+1 downto 0) ); 
  end generate;

  Pm <= sig_sum(M/2 -1); 
end architecture; 
