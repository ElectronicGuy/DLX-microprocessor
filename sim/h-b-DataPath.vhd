library ieee;
use ieee.std_logic_1164.all;
use work.globals.all;

entity datapath is
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
end entity;

architecture structural of datapath is

	component decode_stage 
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
	end component;

	component execute_stage 
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
	end component;

	component mem_access_stage 
		port ( 	ALU_OUT 		: in std_logic_vector(NumBit-1 downto 0);
			  	REGB_EX_OUT		: in std_logic_vector(NumBit-1 downto 0);
				DRAM_WE 		: in std_logic;
				LMD_LATCH_EN	: in std_logic;
				DRAM_EN			: in std_logic;
				RST, CLK		: in std_logic;
				ALU_MA_LATCH_EN	: in std_logic;
				FLUSH			: in std_logic;
				ALU_MA_OUT		: out std_logic_vector(NumBit-1 downto 0);
				LMD_OUT 		: out std_logic_vector(NumBit-1 downto 0) );
	end component;

	component write_back_stage
		port (	LMD_OUT 		: in std_logic_vector (NumBit-1 downto 0);
				ALU_MA_OUT 		: in std_logic_vector (NumBit-1 downto 0);
				
				MUX_SEL_WB 		: in std_logic;
				RF_DATA_IN 		: out std_logic_vector (NumBit-1 downto 0) );
	end component;

	signal sig_ir: std_logic_vector(NumBit-1 downto 0);
	signal sig_rega,sig_regb,sig_regb_decode,sig_imm,sig_regb_ex,sig_regalu,sig_rf_datain,sig_alu_ma,sig_lmd,sig_mux_sel_jal_imm,sig_npc_ex_in : std_logic_vector(NumBit-1 downto 0);
	signal sig_flush : std_logic;
	signal sig_reg_delay1, sig_reg_delay2, sig_reg_delay3, sig_reg_delay4 : std_logic_vector(5 downto 0);
begin 
	
	decode_map: decode_stage port map(	RST				=> RST, 
										CLK				=> CLK,
										SOURCE1			=> SOURCE1,	
										SOURCE2			=> SOURCE2,	
										DESTINATION 	=> DESTINATION, 
										IMMEDIATE 		=> IMMEDIATE,
										NPC 			=>  NPC, -- from top entity
									
										RD1_EN			=> RD1_EN,			-- cu
										RD2_EN			=> RD2_EN,			-- cu
										WR_EN_WB		=> RF_WE,		-- cu (cw5, is called RF_WE)
										RF_DATAIN 		=> sig_rf_datain,	-- comes from WB stage 
										REGA_LATCH_EN	=> REGA_LATCH_EN,   -- cu
										REGB_LATCH_EN	=> REGB_LATCH_EN,	-- cu
										REGIMM_LATCH_EN	=> REGIMM_LATCH_EN,	-- cu
										MUX_SEL_IMM		=> MUX_SEL_IMM,		-- cu 
										
										MUX_SEL_JAL_ADDR_LW=> MUX_SEL_JAL_ADDR_LW,-- cu 
										JUMPFC			=> JUMPFC,			-- cu
										NPC_LATCH_DEC_EN=>NPC_LATCH_DEC_EN,

										REGA_OUT		=> sig_rega,		-- goes to execute stage
										REGB_OUT		=> sig_regb_decode, -- goes to execute stage
										REGIMM_OUT		=> sig_imm,		    -- goes to execute stage
										NPC_EXECUTE_IN	=> sig_npc_ex_in,	-- goes to execute stage
										NPC_DECODE_OUT	=> NPC_DATAPATH_OUT, -- goes to fetch stage (combinatorial)
										FLUSH 			=> sig_flush,
										
										REG_DELAY1		=> sig_reg_delay1,
										REG_DELAY2		=> sig_reg_delay2,
										REG_DELAY3		=> sig_reg_delay3,
										REG_DELAY4		=> sig_reg_delay4,
										EN_IN 			=> EN_IN);	
	
	REG_DELAY1	<= sig_reg_delay1;
	REG_DELAY2 	<= sig_reg_delay2;
	REG_DELAY3	<= sig_reg_delay3;
	REG_DELAY4	<= sig_reg_delay4;
	

	execute_map: execute_stage port map(REGA_OUT			=> sig_rega,    -- comes from decode stage
										REGB_OUT			=> sig_regb_decode,	-- comes from decode stage
										REGIMM_OUT			=> sig_imm,		-- comes from decode stage
										CLK					=> CLK,		
										RST					=> RST,
										ALU_OPCODE			=> ALU_OPCODE,		-- cu
										MUX_SEL_JAL_IMM		=> MUX_SEL_JAL_IMM, -- cu
										MUX_SEL_BIMM		=> MUX_SEL_BIMM,	-- cu
										MUX_SEL_ANPC		=> MUX_SEL_ANPC,	-- cu
										MUX_SEL_ALU_32		=> MUX_SEL_ALU_32,	-- cu
										MUX_SEL_ALU_1		=> MUX_SEL_ALU_1,	-- cu
										ALU_OUTREG_EN		=> ALU_OUTREG_EN,	-- cu
										REGBDELAY_LATCH_EN	=> REGBDELAY_LATCH_EN,	-- cu
										NPC_EXECUTE_IN		=> sig_npc_ex_in,		-- comes from decode stage
										REGALU_OUT			=> sig_regalu,			-- goes to memory access stage
										REGB_EX_OUT			=> sig_regb_ex );		-- goes to memory access stage

	mem_access_map: mem_access_stage port map(	ALU_OUT			=> sig_regalu,		-- comes from execute stage
			   									REGB_EX_OUT		=> sig_regb_ex,		-- comes from execute stage
												DRAM_WE			=> DRAM_WE,			-- cu 
												LMD_LATCH_EN	=> LMD_LATCH_EN,	-- cu 
												DRAM_EN			=> DRAM_EN,			-- cu
												RST				=> RST,
												CLK				=> CLK,
												ALU_MA_LATCH_EN	=> ALU_MA_LATCH_EN,	-- cu
												FLUSH			=> sig_flush, 
												ALU_MA_OUT		=> sig_alu_ma,		-- goes to wb stage
												LMD_OUT			=> sig_lmd);		-- goes to wb stage

	write_back_map: write_back_stage port map(	LMD_OUT 		=> sig_lmd,			-- comes from ma stage
												ALU_MA_OUT 		=> sig_alu_ma,		-- comes from ma stage
												
												MUX_SEL_WB 		=> MUX_SEL_WB,		-- cu
												RF_DATA_IN		=> sig_rf_datain);	-- goes to decode stage

end architecture;
