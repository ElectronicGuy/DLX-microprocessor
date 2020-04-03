library ieee;
use ieee.std_logic_1164.all;
use work.globals.all;

entity decode_stage is
port(		RST, CLK			: in std_logic;
			-- inputs from top entity (PC,IR...)
			SOURCE1				: in std_logic_vector(4 downto 0);
			SOURCE2				: in std_logic_vector(4 downto 0);
			DESTINATION 		: in std_logic_vector(5 downto 0);
			IMMEDIATE 			: in std_logic_vector(25 downto 0);
			NPC					: in std_logic_vector(NumBit-1 downto 0);
			-- register file inputs
			RD1_EN 				: in std_logic;
			RD2_EN 				: in std_logic;
			WR_EN_WB			: in std_logic;
			RF_DATAIN 			: in std_logic_vector(NumBit-1 downto 0);
			-- enable signals
			REGA_LATCH_EN 		: in std_logic;
			REGB_LATCH_EN 		: in std_logic;
			REGIMM_LATCH_EN 	: in std_logic;
			NPC_LATCH_DEC_EN	: in std_logic;
			-- jump related signals
			MUX_SEL_IMM			: in std_logic;
			JUMPFC				: in std_logic_vector(1 downto 0);
			MUX_SEL_JAL_ADDR_LW	: in std_logic_vector(1 downto 0);
			-- decode outputs 
			REGA_OUT			: out std_logic_vector(NumBit-1 downto 0);
			REGB_OUT			: out std_logic_vector(NumBit-1 downto 0);
			REGIMM_OUT			: out std_logic_vector(NumBit-1 downto 0);
			NPC_EXECUTE_IN		: out std_logic_vector(NumBit-1 downto 0);	  -- this signal is sequential (register)
			NPC_DECODE_OUT 		: out std_logic_vector(NumBit-1 downto 0);    -- this signal is combinatorial
			FLUSH				: out std_logic;

			REG_DELAY1			: out std_logic_vector(5 downto 0);
			REG_DELAY2			: out std_logic_vector(5 downto 0);
			REG_DELAY3			: out std_logic_vector(5 downto 0);			
			REG_DELAY4			: out std_logic_vector(5 downto 0);
			EN_IN				: in std_logic );  
end entity;

architecture Structural of decode_stage is

	component reg_generic
		generic (N: integer );
		port(	D	:	in	std_logic_vector(N-1 downto 0);
				CLK, RST, EN : 	in	std_logic;
				Q	:	out std_logic_vector(N-1 downto 0));
	end component;

	component mux41_generic
		Generic (N: integer);
		Port (	A:	In	std_logic_vector(N-1 downto 0);
				B:	In	std_logic_vector(N-1 downto 0);
				C:	In	std_logic_vector(N-1 downto 0);
				D:	In	std_logic_vector(N-1 downto 0);
				SEL:In	std_logic_vector(1 downto 0);
				Y:	Out	std_logic_vector(N-1 downto 0));
	end component;

	component mux21_generic
		generic (N: integer:= NumBit);
		port (	A:	In	std_logic_vector(N-1 downto 0);
				B:	In	std_logic_vector(N-1 downto 0);
				SEL:In	std_logic;
				Y:	Out	std_logic_vector(N-1 downto 0)); 
	end component;

	component P4adder 
		generic (	N: integer := NumBit;
      	          	M: integer := 4);
  		port (	A, B : in  std_logic_vector (N downto 1);
        		Y    : out std_logic_vector (N downto 1);
            	Ci   : in std_logic;
            	Co   : out std_logic );
	end component;

	component register_file
		generic ( N: integer ;
        		  A: integer;
		 		tot_regs: integer);
 		port ( 	CLK: 		IN std_logic;
    	    	RESET: 		IN std_logic;
	 			ENABLE: 	IN std_logic;
				RD1: 		IN std_logic;
	 			RD2: 		IN std_logic;
	 			WR: 		IN std_logic;
	 			ADD_WR: 	IN std_logic_vector(A-1 downto 0);
	 			ADD_RD1: 	IN std_logic_vector(A-1 downto 0);
	 			ADD_RD2: 	IN std_logic_vector(A-1 downto 0);
	 			DATAIN: 	IN std_logic_vector(N-1 downto 0);
     			OUT1: 		OUT std_logic_vector(N-1 downto 0);
	 			OUT2: 		OUT std_logic_vector(N-1 downto 0));
	end component;

	component MUX41 
		Port (	A:	In	std_logic;
			B:	In	std_logic;
			C:	In	std_logic;
			D:	In	std_logic;
			SEL:In	std_logic_vector(1 downto 0);
			Y:	Out	std_logic);
	end component;
	
	component	zero_detector 
		generic ( 	N	: integer := Numbit);
		port (		A	: in std_logic_vector(Numbit-1 downto 0);
					YE	: out std_logic ); 
	end component;

	component FD_s
		port (	D, CLK, RST, EN : in std_logic;
				Q				: out std_logic);
	end component;

	component MUX21
		port (	A:	In	std_logic;
				B:	In	std_logic;
				SEL:In	std_logic;
				Y:	Out	std_logic);
	end component;

	component reg_wr
		port(	D				:	in	std_logic_vector(5 downto 0);
				CLK, RST, EN 	: 	in	std_logic;
				Q				:	out std_logic_vector(5 downto 0));
	end component;

	-- delay registers
	signal add_wr_0, add_wr_1,add_wr_2, add_wr_3,add_wr_4 	: std_logic_vector(5 downto 0);
	-- lw register 
	signal sig_source2_delay1 								: std_logic_vector(4 downto 0);
	signal sig_source2_delay1_extended						: std_logic_vector(5 downto 0);
	-- signal extenders
	signal sig_immediate 									: std_logic_vector(25 downto 0);
	signal imm_16, imm_26									: std_logic_vector(NumBit-1 downto 0);
	-- jump logic signals
	signal jump_sel, eq_cond , neq_cond						: std_logic;
	signal addJ_out, mux_imm_out							: std_logic_vector(NumBit-1 downto 0);
	signal sig_npc, sig_npc_decode_out 						: std_logic_vector (NumBit-1 downto 0);
	-- flush logic signals
	signal sig_wr_flush, sig_fd_1, sig_fd_2, sig_fd_3, sig_fd_4 : std_logic;
	--output registers
	signal rega_in, regb_in									: std_logic_vector(NumBit-1 downto 0);
	
begin
	
	NPC_DECODE_OUT	<= sig_npc_decode_out;			-- combinatorial signal (no reg)
--------------------------------------------------------------------------------------------------------
-- input registers and RF
RF: register_file 	generic map(	N => NumBit, A => 5, tot_regs => 32) 
						port map(		CLK 	=> CLK,
										RESET	=> RST,
										ENABLE 	=> '1',
										RD1 	=> RD1_EN,
	 									RD2 	=> RD2_EN,
	 									WR		=> sig_wr_flush,
	 									ADD_RD1 => SOURCE1,  
	 									ADD_RD2 => SOURCE2,  
										ADD_WR	=> add_wr_4(4 downto 0), -- the wr address should be delayed of 3 clock cycles. It will be used in the WB stage
	 									DATAIN  => RF_DATAIN,
     									OUT1    => rega_in,
	 									OUT2    => regb_in );
	reg_imm: reg_generic 			generic map(	N 	=> 26) 
									port map(		D 	=> IMMEDIATE,
													CLK => CLK,
													RST => RST,
													EN 	=> EN_IN,
													Q 	=> sig_immediate);
	reg_npc_in : reg_generic 		generic map(	N 	=> NumBit) 
										port map(		D 	=> NPC,
														CLK => CLK,
														RST => RST,
														EN 	=> EN_IN,
														Q 	=> sig_npc);

	reg_source2_delay1 : reg_generic 	generic map(	N 	=> 5 )
										port map(		D 	=> SOURCE2,
														CLK => CLK,
														RST => RST,
														EN 	=> '1',
														Q 	=> sig_source2_delay1);

---------------------------------------------------------------------------------------------------------
-- mux + 3 regs to delay the add_wr for 3 clock cycles.
	
	
	reg_add_wr_delay_0: reg_wr		port map(		D 	=> DESTINATION,
													CLK => CLK,
													RST => RST,
													EN 	=> '1',
													Q 	=> add_wr_0 );
	REG_DELAY1 <= add_wr_0;

	sig_source2_delay1_extended <= '0' & sig_source2_delay1;
	mux_wr_rf : mux41_generic 	generic map(	N	=> 6)
								port map (		A	=> add_wr_0,
												B 	=> "011111", --31 (jal)
												C	=> sig_source2_delay1_extended,
												D	=> "100000",
												SEL => MUX_SEL_JAL_ADDR_LW,
												Y 	=> add_wr_1 );


	reg_add_wr_delay_1: reg_wr 		port map(		D 	=> add_wr_1,
													CLK => CLK,
													RST => RST,
													EN 	=> '1',
													Q 	=> add_wr_2 );

	REG_DELAY2 <= add_wr_2;

	reg_add_wr_delay_2: reg_wr 		port map(		D 	=> add_wr_2,
													CLK => CLK,
													RST => RST,
													EN 	=> '1',
													Q 	=> add_wr_3 );
	REG_DELAY3 <= add_wr_3;

	reg_add_wr_delay_3: reg_wr 		port map(		D 	=> add_wr_3,
													CLK => CLK,
													RST => RST,
													EN 	=> '1',
													Q 	=> add_wr_4 );
	REG_DELAY4 <= add_wr_4;

-----------------------------------------------------------------------------------------------------
	-- sign extenders:
	imm_26(NumBit-1 downto 26)  <= (others => sig_immediate(25)); 
	imm_26(25 downto 0) 		<= sig_immediate;
	
	imm_16(NumBit-1 downto 16)  <= (others => sig_immediate(15));
	imm_16(15 downto 0) 		<= sig_immediate(15 downto 0);
-----------------------------------------------------------------------------------------------------
-- jump logic
	
	zero_det: zero_detector 	generic map(	N	=> NumBit)
								port map(		A	=> regb_in,
												YE 	=> eq_cond );

	neq_cond <= not(eq_cond);

	mux_imm_size: 	Mux21_generic 		generic map( 	N 	=> NumBit)
										port map(		A	=> imm_16,
														B	=> imm_26,
														SEL	=> MUX_SEL_IMM,
														Y	=> mux_imm_out);
	
	-- Sum immediate with npc coming from the decode stage
	Add_J: P4adder 					generic map (	N	=> Numbit,
													M	=> 4)
									port map (		A	=> mux_imm_out,
													B	=> sig_npc,
													Y	=> addJ_out,
													Ci	=> '0');

	-- If there is a B/J select the npc+imm, otherwise keep npc from fecth stage
	mux_npc_selection : mux21_generic 	generic map(	N	=> NumBit)
										port map (		A	=> AddJ_out, 
														B 	=> NPC,  --VERIFICATO: ci vuole NPC e non sig_NPC per risparmiare un colpo di clock
														SEL => jump_sel,
														Y 	=> sig_npc_decode_out );

	-- selection signal for the previous mux 
	mux_jump_condition_res : MUX41 	port map (	A	=> '0', 
												B 	=> '1', 
												C	=> eq_cond,
				 								D	=> neq_cond, 
												SEL => JUMPFC, 
												Y 	=> jump_sel );

-----------------------------------------------------------------------------------------------------------
-- output registers
	reg_a : reg_generic 	generic map(	N => NumBit) 
							port map(		D => rega_in,
											CLK => CLK,
											RST => RST,
											EN => REGA_LATCH_EN,
											Q => REGA_OUT );
	
	reg_b : reg_generic 	generic map(	N => NumBit) 
							port map(		D => regb_in,
											CLK => CLK,
											RST => RST,
											EN => REGB_LATCH_EN,
											Q => REGB_OUT );

	regimmm : reg_generic 	generic map (	N 	=> NumBit) 
							port map (		D 	=> imm_16,
											CLK => CLK,
											RST => RST,
											EN 	=> REGIMM_LATCH_EN,
											Q 	=> REGIMM_OUT );

	reg_npc: reg_generic 	generic map(	N 	=> Numbit) 
							port map(		D 	=> sig_npc, ----------------modifica da sig_npc_decode_out
											CLK => CLK,
											RST => RST,
											EN 	=> NPC_LATCH_DEC_EN,
											Q 	=> NPC_EXECUTE_IN);
---------------------------------------------------------------------------------------------------------------
  -- flush logic
	ff_1 : FD_s port map( 	D 	=> jump_sel,
							CLK	=> CLK,
							RST => RST,
							EN 	=> '1',
							Q	=> sig_fd_1 );
	ff_2 : FD_s port map(	D 	=> sig_fd_1,
							CLK	=> CLK,
							RST => RST,
							EN 	=> '1',
							Q	=> sig_fd_2 );

	ff_3 : FD_s port map(	D 	=> sig_fd_2,
							CLK	=> CLK,
							RST => RST,
							EN 	=> '1',
							Q	=> sig_fd_3 );

	ff_4 : FD_s port map(	D 	=> sig_fd_3,
							CLK	=> CLK,
							RST => RST,
							EN 	=> '1',
							Q	=> sig_fd_4 );

	mux_rf_flush: mux21 port map(	A 	=> '0',
									B	=> WR_EN_WB, 
									SEL => sig_fd_4,
									Y 	=> sig_wr_flush);

	FLUSH <= jump_sel;

end architecture;
