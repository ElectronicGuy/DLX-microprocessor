library ieee;
use ieee.std_logic_1164.all;
use work.globals.all;
----------- 8 bit: SSS A LLLL
----------  shifter => SR LR LA
entity execute_stage is
port(	-- inputs from datapath	
		CLK,RST				: in std_logic;
		NPC_EXECUTE_IN		: in std_logic_vector(NumBit-1 downto 0);
		REGA_OUT			: in std_logic_vector(NumBit-1 downto 0);
		REGB_OUT			: in std_logic_vector(NumBit-1 downto 0);
		REGIMM_OUT			: in std_logic_vector(NumBit-1 downto 0);
		--inputs from CU
		ALU_OPCODE			: in std_logic_vector(7 downto 0);
		MUX_SEL_ANPC		: in std_logic;
		MUX_SEL_BIMM		: in std_logic;
		MUX_SEL_JAL_IMM 	: in std_logic;
		MUX_SEL_ALU_32		: in std_logic_vector(2 downto 0);
		MUX_SEL_ALU_1		: in std_logic_vector(1 downto 0);
		ALU_OUTREG_EN		: in std_logic;
		REGBDELAY_LATCH_EN	: in std_logic;
		-- outputs
		REGALU_OUT			: out std_logic_vector(NumBit-1 downto 0);	
		REGB_EX_OUT			: out std_logic_vector(NumBit-1 downto 0) ); 
end entity;

architecture structural of execute_stage is
	
	component ALU is
		generic(N: integer);
		port(	ALU_OPCODE			: in std_logic_vector(7 downto 0);
				A, B				: in std_logic_vector(N-1 downto 0);
				Y_ADDER				: out std_logic_vector (N-1 downto 0);
				Y_SHIFT				: out std_logic_vector (N-1 downto 0);
				Y_LOGIC				: out std_logic_vector (N-1 downto 0);
				Y_MULT				: out std_logic_vector (N-1 downto 0);
				ne,ge,le,ee			: out std_logic);
	end component;

	component P4adder 
		Generic (	N: integer := NumBit;
    	            M: integer := 4);
  		Port (	A, B : in  std_logic_vector (N downto 1);
    	    	Y    : out std_logic_vector (N downto 1);
    	        Ci   : in std_logic;
    	        Co   : out std_logic );
	end component;

	component mux21_generic
		generic (N: integer:= NumBit);
		port (	A:	In	std_logic_vector(N-1 downto 0);
				B:	In	std_logic_vector(N-1 downto 0);
				SEL:In	std_logic;
				Y:	Out	std_logic_vector(N-1 downto 0)); 
	end component;

	component MUX51_GENERIC is
		Generic (N: integer);
		Port (	A:	In	std_logic_vector(N-1 downto 0);
				B:	In	std_logic_vector(N-1 downto 0);
				C:	In	std_logic_vector(N-1 downto 0);
				D:	In	std_logic_vector(N-1 downto 0);
				E:	In	std_logic_vector(N-1 downto 0);
				SEL:In	std_logic_vector(2 downto 0);
				Y:	Out	std_logic_vector(N-1 downto 0));
	end component; 

	component reg_generic 
		generic (N: integer );
		port(	D	:	in	std_logic_vector(N-1 downto 0);
				CLK, RST, EN : 	in	std_logic;
				Q	:	out std_logic_vector(N-1 downto 0));
	end component;
	component MUX21 
		port (	A:	In	std_logic;
				B:	In	std_logic;
				SEL:In	std_logic;
				Y:	Out	std_logic);
	end component;

	component MUX41 
		Port (	A:	In	std_logic;
				B:	In	std_logic;
				C:	In	std_logic;
				D:	In	std_logic;
				SEL:In	std_logic_vector(1 downto 0);
				Y:	Out	std_logic);
	end component;

	signal alu_b, alu_a			:std_logic_vector(NumBit-1 downto 0);

	signal sig_add,sig_shift,sig_logic, sig_mult, sig_comparison,sig_mux_imm_4 : std_logic_vector(NumBit-1 downto 0);
	signal sig_ne,sig_ge,sig_le,sig_ee,mux_alu_cmp_1_out: std_logic;
	signal reg_alu_in : std_logic_vector(NumBit-1 downto 0);

begin

	mux_a_npc: mux21_generic	generic map(	N 	=> NumBit)
								port map(		A 	=> NPC_EXECUTE_IN,  -- 1
												B 	=> REGA_OUT,        -- 0
												SEL	=> MUX_SEL_ANPC,
												Y	=> alu_a);  

	mux_imm_4: mux21_generic 	generic map(	N	=> NumBit)
								port map (		A	=> REGIMM_OUT, 
												B 	=> "00000000000000000000000000000000", --0
												SEL => MUX_SEL_JAL_IMM,
												Y	=> sig_mux_imm_4 );

	mux_b_imm: mux21_generic	generic map (	N	=> NumBit)
								port map(		A	=> REGB_OUT,
												B	=> sig_mux_imm_4,
												SEL	=> MUX_SEL_BIMM,
												Y	=> alu_b);
	
	Alu_exe: ALU 				generic map(	N	=> NumBit)
								port map(		Alu_opcode	=> ALU_OPCODE,
												A			=> alu_a,
												B			=> alu_b,
												Y_ADDER		=> sig_add,
												Y_SHIFT		=> sig_shift,
												Y_LOGIC		=> sig_logic,
												Y_MULT		=> sig_mult,
												ne			=> sig_ne,
												le			=> sig_le,
												ge			=> sig_ge,
												ee			=> sig_ee);

	mux_alu_comparator: mux41	port map(	A 	=> sig_ne,  
											B 	=> sig_ge,
											C	=> sig_le,
											D	=> sig_ee,
											SEL	=> MUX_SEL_ALU_1,
											Y	=> sig_comparison(0));

	-- extend the result of comperison from 1 bit to 32 bits (e.g. '1' -> "00000000000000000000000000000001") 
	sig_comparison(NumBit-1 downto 1) <= (others => '0');	

	mux_alu_32 : MUX51_GENERIC 	generic map(N	=> NumBit)
								port map(	A 	=> sig_add,
											B 	=> sig_logic,
											C 	=> sig_shift,
											D 	=> sig_comparison,
											E	=> sig_mult,
											SEL => MUX_SEL_ALU_32,
											Y 	=> reg_alu_in);

-----------------------------------------------------------------------------------------
-- output registers

	reg_alu: reg_generic 		generic map (	N 	=> NumBit)
								port map(		D 	=> reg_alu_in,
												CLK => CLK,
												RST => RST,
												EN 	=> ALU_OUTREG_EN,
												Q 	=> REGALU_OUT );

	regB_delay: reg_generic 	generic map (	N 	=> NumBit)
								port map(		D 	=> REGB_OUT,
												CLK => CLK,
												RST => RST,
												EN 	=> REGBDELAY_LATCH_EN,
												Q 	=> REGB_EX_OUT);

end architecture;

