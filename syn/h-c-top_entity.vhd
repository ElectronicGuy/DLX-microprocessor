library ieee;
use ieee.std_logic_1164.all;
use work.globals.all;

entity top_entity is
	port (	CLK, RST 	: in std_logic;
			PC		 	: out std_logic_vector(NumBit-1 downto 0);
			IR			: in std_logic_vector(NumBit-1 downto 0) ); 
end entity;

architecture Structural of top_entity is

	-- simple adder with one argument always = 4
	component Add4
		generic (N : integer ); 
		port(	A	:	in  std_logic_vector(Numbit-1 downto 0);
	 			Y	:	out std_logic_vector(Numbit-1 downto 0));
	end component;

	component mux21_generic
		generic (N: integer:= NumBit);
		port (	A:	In	std_logic_vector(N-1 downto 0);
				B:	In	std_logic_vector(N-1 downto 0);
				SEL:In	std_logic;
				Y:	Out	std_logic_vector(N-1 downto 0)); 
	end component;

	component reg_generic
		generic (N: integer );
		port(	D	:	in	std_logic_vector(N-1 downto 0);
				CLK, RST, EN : 	in	std_logic;
				Q	:	out std_logic_vector(N-1 downto 0));
	end component;

	component datapath
	port(	CLK : in std_logic;
			RST : in std_logic;			
			--decode
			SOURCE1				: in std_logic_vector(4 downto 0);
			SOURCE2				: in std_logic_vector(4 downto 0);
			DESTINATION 		: in std_logic_vector(5 downto 0);
			IMMEDIATE 			: in std_logic_vector(25 downto 0);
			NPC  				: in std_logic_vector(Numbit-1 downto 0); 
			RD1_EN 				: in std_logic;
			RD2_EN 				: in std_logic;
			REGA_LATCH_EN 		: in std_logic;
			REGB_LATCH_EN 		: in std_logic;
			REGIMM_LATCH_EN 	: in std_logic;
			MUX_SEL_IMM			: in std_logic;
			MUX_SEL_JAL_ADDR_LW	: in std_logic_vector(1 downto 0);
			NPC_LATCH_DEC_EN	: in std_logic;
			JUMPFC				: in std_logic_vector(1 downto 0);

			NPC_DATAPATH_OUT  	: out std_logic_vector(Numbit-1 downto 0); -- combinatorial NPC (jump handling)
			REG_DELAY1			: out std_logic_vector(5 downto 0);
			REG_DELAY2			: out std_logic_vector(5 downto 0);
			REG_DELAY3			: out std_logic_vector(5 downto 0);
			REG_DELAY4			: out std_logic_vector(5 downto 0);
			EN_IN 				: in std_logic;
			--execute
			ALU_OPCODE			: in std_logic_vector(7 downto 0);
			MUX_SEL_JAL_IMM		: in std_logic;
			MUX_SEL_BIMM		: in std_logic;
			MUX_SEL_ANPC		: in std_logic;
			MUX_SEL_ALU_32		: in std_logic_vector(2 downto 0);
			MUX_SEL_ALU_1		: in std_logic_vector(1 downto 0);
			ALU_OUTREG_EN		: in std_logic;
			REGBDELAY_LATCH_EN	: in std_logic;
			--memory access
		 	DRAM_WE 			: in std_logic;
			LMD_LATCH_EN		: in std_logic;
			ALU_MA_LATCH_EN 	: in std_logic;
			DRAM_EN				: in std_logic;
			--write back 
			MUX_SEL_WB			: in std_logic;
			RF_WE 				: in std_logic );
	end component;
	
	component dlx_cu
  		generic (	FUNC_SIZE          :     integer := 11;  -- Func Field Size for R-Type Ops
    				OP_CODE_SIZE       :     integer := 6;  -- Op Code Size 
   	 				CW_SIZE            :     integer := 35);  -- Control Word Size
 		port( 		IR	: in std_logic_vector(Numbit-1 downto 0); 
					CLK : in std_logic;
					RST : in std_logic;
					--decode
					RD1_EN 				: out std_logic;
					RD2_EN 				: out std_logic;
					NPC_LATCH_DEC_EN	: out std_logic;
					REGA_LATCH_EN 		: out std_logic;
					REGB_LATCH_EN 		: out std_logic;
					REGIMM_LATCH_EN 	: out std_logic;
					MUX_SEL_IMM			: out std_logic;
					JUMPFC				: out std_logic_vector(1 downto 0);
					MUX_SEL_JAL_ADDR_LW	: out std_logic_vector(1 downto 0);
					--execute
					MUX_SEL_ANPC		: out std_logic; 
					MUX_SEL_JAL_IMM		: out std_logic;  
					MUX_SEL_BIMM		: out std_logic;
					ALU_OPCODE			: out std_logic_vector(7 downto 0);
					MUX_SEL_ALU_32		: out std_logic_vector(2 downto 0);
					MUX_SEL_ALU_1		: out std_logic_vector(1 downto 0);
					ALU_OUTREG_EN		: out std_logic;
					REGBDELAY_LATCH_EN	: out std_logic;
					--memory access
			 		DRAM_WE 			: out std_logic;
					LMD_LATCH_EN		: out std_logic;
					DRAM_EN				: out std_logic;
					ALU_MA_LATCH_EN		: out std_logic;
					--write back 
					MUX_SEL_WB			: out std_logic;
					RF_WE 				: out std_logic );
	end component; 

	component dependency_manager 
		port( 	RST				: in std_logic;
				IR				: in std_logic_vector(31 downto 0);
				IR_OUT			: out std_logic_vector(31 downto 0);
				DIRTY_BIT		: out std_logic;
				EN_OUT			: out std_logic;
				REG_DELAY1		: in std_logic_vector(5 downto 0);  
				REG_DELAY2		: in std_logic_vector(5 downto 0); 
				REG_DELAY3		: in std_logic_vector(5 downto 0);
				REG_DELAY4		: in std_logic_vector(5 downto 0) );
	end component;


	signal sig_ir, sig_ir_dependency : std_logic_vector(NumBit-1 downto 0);

	signal sig_rd1_en, sig_rd2_en, sig_rega_latch_en, sig_regb_latch_en, sig_regimm_latch_en, sig_mux_sel_imm,  sig_mux_sel_jal_imm, sig_npc_latch_dec_en : std_logic;
	signal sig_jumpfc, sig_mux_sel_jal_addr : std_logic_vector(1 downto 0);
	
	signal sig_alu_opcode : std_logic_vector (7 downto 0);
	signal sig_mux_sel_bimm, sig_sel_anpc, sig_alu_outreg_en, sig_regbdelay_latch_en : std_logic;
	signal sig_mux_sel_alu_32 : std_logic_vector(2 downto 0);
	signal sig_mux_sel_alu_1 : std_logic_vector(1 downto 0);

	signal sig_dram_we, sig_lmd_latch_en, sig_alu_ma_latch_en, sig_dram_en : std_logic;
	
	signal sig_mux_sel_wb, sig_rf_we : std_logic;
	
	signal sig_npc, sig_npc_datapath: std_logic_vector(NumBit-1 downto 0);	

	signal reg_pc_out: std_logic_vector(NumBit-1 downto 0);
	signal sig_reg_delay1, sig_reg_delay2, sig_reg_delay3, sig_reg_delay4, sig_destination : std_logic_vector(5 downto 0);
	signal sig_en_dependecy, sig_dirty_bit : std_logic;

begin
	reg_pc : reg_generic 	generic map(N => NumBit)
							port map (	D => sig_npc_datapath,
										CLK => CLK,
										RST => RST,
										EN => sig_en_dependecy,
										Q => reg_pc_out );
	
	
	add4_0 : Add4 			generic map(N => NumBit)
							port map(	A => reg_pc_out,
										Y => sig_npc );

	PC <= reg_pc_out;
	sig_ir <= IR;
										
	dep_man : dependency_manager  port map (RST 			=> RST,
											DIRTY_BIT 		=> sig_dirty_bit,
											IR				=> sig_ir,
											IR_OUT			=> sig_ir_dependency,
											EN_OUT			=> sig_en_dependecy,
											REG_DELAY1		=> sig_reg_delay1,  
											REG_DELAY2		=> sig_reg_delay2, 
											REG_DELAY3		=> sig_reg_delay3,
											REG_DELAY4		=> sig_reg_delay4 );
	
	sig_destination <= sig_dirty_bit & sig_ir_dependency(15 downto 11);

	datapath_0 : datapath 	port map (	CLK 				=> CLK,
										RST 				=> RST,
									
										SOURCE2				=> sig_ir_dependency(20 downto 16),
										SOURCE1				=> sig_ir_dependency(25 downto 21),
										DESTINATION 		=> sig_destination,
										IMMEDIATE 			=> sig_ir_dependency(25 downto 0),
										NPC  				=> sig_npc,
										
										RD1_EN 				=> sig_rd1_en,
										RD2_EN 				=> sig_rd2_en,
										
										REGA_LATCH_EN 		=> sig_rega_latch_en,
										REGB_LATCH_EN 		=> sig_regb_latch_en,
										REGIMM_LATCH_EN 	=> sig_regimm_latch_en,
										MUX_SEL_IMM			=> sig_mux_sel_imm,
										MUX_SEL_JAL_ADDR_LW	=> sig_mux_sel_jal_addr,
										MUX_SEL_JAL_IMM		=> sig_mux_sel_jal_imm,
										NPC_LATCH_DEC_EN	=> sig_npc_latch_dec_en,
										JUMPFC				=> sig_jumpfc,

										NPC_DATAPATH_OUT	=> sig_npc_datapath,
										REG_DELAY1 			=> sig_reg_delay1,
										REG_DELAY2 			=> sig_reg_delay2,
										REG_DELAY3 			=> sig_reg_delay3,
										REG_DELAY4			=> sig_reg_delay4,
										EN_IN 				=> sig_en_dependecy,

										ALU_OPCODE			=> sig_alu_opcode,
										MUX_SEL_BIMM		=> sig_mux_sel_bimm,
										MUX_SEL_ANPC		=> sig_sel_anpc,
										MUX_SEL_ALU_32		=> sig_mux_sel_alu_32,
										MUX_SEL_ALU_1		=> sig_mux_sel_alu_1,
										ALU_OUTREG_EN		=> sig_alu_outreg_en,
										REGBDELAY_LATCH_EN	=> sig_regbdelay_latch_en,
			
									 	DRAM_WE 			=> sig_dram_we,
										LMD_LATCH_EN		=> sig_lmd_latch_en,
										ALU_MA_LATCH_EN 	=> sig_alu_ma_latch_en,
										DRAM_EN				=> sig_dram_en,

										MUX_SEL_WB			=> sig_mux_sel_wb,
										RF_WE 				=> sig_rf_we );

	cu_0 : dlx_cu port map( IR					=> sig_ir_dependency, 
							CLK 				=> CLK,
							RST 				=> RST,
							RD1_EN 				=> sig_rd1_en,
							RD2_EN 				=> sig_rd2_en,
							NPC_LATCH_DEC_EN	=> sig_npc_latch_dec_en,
							REGA_LATCH_EN 		=> sig_rega_latch_en,
							REGB_LATCH_EN 		=> sig_regb_latch_en,
							REGIMM_LATCH_EN 	=> sig_regimm_latch_en,
							MUX_SEL_IMM			=> sig_mux_sel_imm,
							JUMPFC				=> sig_jumpfc,
							MUX_SEL_JAL_IMM		=> sig_mux_sel_jal_imm,
							MUX_SEL_JAL_ADDR_LW	=> sig_mux_sel_jal_addr,
			
							ALU_OPCODE			=> sig_alu_opcode,
							MUX_SEL_BIMM		=> sig_mux_sel_bimm,
							MUX_SEL_ALU_32		=> sig_mux_sel_alu_32,
							MUX_SEL_ALU_1		=> sig_mux_sel_alu_1,
							ALU_OUTREG_EN		=> sig_alu_outreg_en,
							REGBDELAY_LATCH_EN	=> sig_regbdelay_latch_en,
							MUX_SEL_ANPC		=> sig_sel_anpc,
			
					 		DRAM_WE 			=> sig_dram_we,
							LMD_LATCH_EN		=> sig_lmd_latch_en,
							DRAM_EN				=> sig_dram_en,
							ALU_MA_LATCH_EN		=> sig_alu_ma_latch_en,
			
							MUX_SEL_WB			=> sig_mux_sel_wb,
							RF_WE 				=> sig_rf_we );


end architecture;
