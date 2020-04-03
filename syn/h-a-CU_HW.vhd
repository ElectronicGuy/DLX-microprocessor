library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;
use work.globals.all;

entity dlx_cu is
  	generic (
    	FUNC_SIZE          :     integer := 11;  -- Func Field Size for R-Type Ops
    	OP_CODE_SIZE       :     integer := 6;  -- Op Code Size 
   	 	CW_SIZE            :     integer := 35);  -- Control Word Size
 	port( 
				IR	: in std_logic_vector(Numbit-1 downto 0); 
				CLK : in std_logic;
				RST : in std_logic;
		
			----------------------------------------------------decode
				RD1_EN 				: out std_logic;
				RD2_EN 				: out std_logic;
				NPC_LATCH_DEC_EN	: out std_logic; -- new
				REGA_LATCH_EN 		: out std_logic;
				REGB_LATCH_EN 		: out std_logic;
				REGIMM_LATCH_EN 	: out std_logic;
				MUX_SEL_IMM			: out std_logic;
				JUMPFC				: out std_logic_vector(1 downto 0);
				MUX_SEL_JAL_ADDR_LW	: out std_logic_vector(1 downto 0);  -- 00 normal, 01 31, 10 lw/immediate, 11 nop
				
			---------------------------------------------------execute
				
				MUX_SEL_ANPC		: out std_logic;  -- 1: npc, 0:regA
				MUX_SEL_JAL_IMM		: out std_logic;  --1:imm, 0:4
				MUX_SEL_BIMM		: out std_logic;  --1:regB, 0: imm or 4
				ALU_OPCODE			: out std_logic_vector(7 downto 0);
				MUX_SEL_ALU_32		: out std_logic_vector(2 downto 0);
				MUX_SEL_ALU_1		: out std_logic_vector(1 downto 0);
				ALU_OUTREG_EN		: out std_logic;
				REGBDELAY_LATCH_EN	: out std_logic;
				
			----------------------------------------memory access
		 		DRAM_WE 			: out std_logic;
				LMD_LATCH_EN		: out std_logic;
				DRAM_EN				: out std_logic;
				ALU_MA_LATCH_EN		: out std_logic;
			---------------------------------------write back 
				MUX_SEL_WB			: out std_logic;
				RF_WE 				: out std_logic );
end entity;

architecture dlx_cu_structural of dlx_cu is
 
  	signal OPCODE_sig	: std_logic_vector(OP_CODE_SIZE-1 downto 0);
	signal FUNC_sig		: std_logic_vector(FUNC_SIZE-1 downto 0);
  	signal cw        	: std_logic_vector(CW_SIZE -1 downto 0);

 	-- control word is shifted to the correct stage	
 	signal cw1 : std_logic_vector(CW_SIZE-1 				downto 0); 		-- dec stage
 	signal cw2 : std_logic_vector(CW_SIZE-1	-11				downto 0); 		-- exe stage
	signal cw3 : std_logic_vector(CW_SIZE-1	-11 -18			downto 0); 		-- ma  stage
	signal cw4 : std_logic_vector(CW_SIZE-1	-11 -18 -4		downto 0); 		-- wb  stage

begin
 	OPCODE_sig	<= IR(31 downto 26);
	FUNC_sig	<= IR(10 downto 0);
    
	--decode
	RD1_EN 				<= cw(CW_SIZE-1);
	RD2_EN 				<= cw(CW_SIZE-2);
	NPC_LATCH_DEC_EN	<= cw1(CW_SIZE-3);
	REGA_LATCH_EN 		<= cw1(CW_SIZE-4);
	REGB_LATCH_EN 		<= cw1(CW_SIZE-5);
	REGIMM_LATCH_EN 	<= cw1(CW_SIZE-6);
	MUX_SEL_IMM			<= cw1(CW_SIZE-7);
	JUMPFC				<= cw1(CW_SIZE-8 downto CW_SIZE -9);
	MUX_SEL_JAL_ADDR_LW	<= cw1(CW_SIZE-10 downto CW_SIZE -11);
	
	--execute
	MUX_SEL_ANPC		<= cw2(CW_SIZE-12);
	MUX_SEL_JAL_IMM		<= cw2(CW_SIZE-13);
	MUX_SEL_BIMM		<= cw2(CW_SIZE-14);
	ALU_OPCODE			<= cw2(CW_SIZE-15 downto CW_SIZE -22);
	MUX_SEL_ALU_32		<= cw2(CW_SIZE-23 downto CW_SIZE -25);
	MUX_SEL_ALU_1		<= cw2(CW_SIZE-26 downto CW_SIZE -27);
	ALU_OUTREG_EN		<= cw2(CW_SIZE-28);
	REGBDELAY_LATCH_EN	<= cw2(CW_SIZE-29);
	
	--memory access
	DRAM_WE 			<= cw3(CW_SIZE-30);
	LMD_LATCH_EN		<= cw3(CW_SIZE-31);
	DRAM_EN				<= cw3(CW_SIZE-32);
	ALU_MA_LATCH_EN		<= cw3(CW_SIZE-33);
	--write back 
	MUX_SEL_WB			<= cw4(CW_SIZE-34);
	RF_WE 				<= cw4(CW_SIZE-35);
 
	-- purpose: generation of cu outputs 
  	-- type   : sequential
  	-- inputs : Rst, CLK, cw
  	-- outputs: cw1, cw2, cw3, cw4
 
  	CW_PIPE: process (Clk, Rst)
  	begin  -- process Clk
    	if Rst = '1' then    -- asynchronous reset (active low)
     		cw1 <= (others => '0');
      		cw2 <= (others => '0');
      		cw3 <= (others => '0');
			cw4 <= (others => '0');
  
    	elsif (Clk'event and Clk = '1') then  
      		cw1 <= cw;  									-- this represent clock cycle delay (next stage in datapath)
			cw2 <= cw1(CW_SIZE - 1- 11        downto 0); 	-- this represent clock cycle delay (next stage in datapath)		
			cw3 <= cw2(CW_SIZE - 1 -11 -18    downto 0);	-- this represent clock cycle delay (next stage in datapath)
			cw4 <= cw3(CW_SIZE - 1 -11 -18 -4 downto 0);	-- this represent clock cycle delay (next stage in datapath)
    	end if;
  	end process CW_PIPE;

 	-- purpose: Generation of cw
  	-- type   : combinational
  	-- inputs : opcode, func [opcode+func = IR]
  	-- outputs: cw
   	cw_selection : process (OPCODE_sig, FUNC_sig)  -- represent the LUT
  	begin 
		--flag <= 0;
		case to_integer(unsigned(OPCODE_sig)) is
	    	-- case of R type requires analysis of FUNC
			when to_integer(unsigned(RTYPE)) =>
				case to_integer(unsigned(FUNC_sig)) is
					when to_integer(unsigned(RTYPE_ADD)) 	=>	cw <= "11011010000011000000000000010000111"; -- ok
					when to_integer(unsigned(RTYPE_SUB)) 	=>	cw <= "11011010000011000100000000010000111";
					-- logic
					when to_integer(unsigned(RTYPE_OR))		=>	cw <= "11011010000011000001110010010000111"; 
					--when to_integer(unsigned(RTYPE_NOR))	=>	cw <= "11011010000011000010000010010000111";
					when to_integer(unsigned(RTYPE_AND)) 	=>	cw <= "11011010000011000000010010010000111";
					--when to_integer(unsigned(RTYPE_NAND))	=> 	cw <= "11011010000011000011100010010000111";
					when to_integer(unsigned(RTYPE_XOR))	=>	cw <= "11011010000011000001100010010000111"; 
					--when to_integer(unsigned(RTYPE_XNOR))	=>	cw <= "11011010000011000010010010010000111";
					-- set
					when to_integer(unsigned(RTYPE_SGE))	=>	cw <= "11011010000011000100000110110000111"; 
					when to_integer(unsigned(RTYPE_SLE))	=>	cw <= "11011010000011000100000111010000111"; 
					when to_integer(unsigned(RTYPE_SNE))	=>	cw <= "11011010000011000100000110010000111"; 
					--when to_integer(unsigned(RTYPE_SEE))	=>	cw <= "11011010000011000100000111110000111";
					-- shift
					when to_integer(unsigned(RTYPE_SLL))	=>	cw <= "11011010000011111000000100010000111";
					when to_integer(unsigned(RTYPE_SRL))	=>	cw <= "11011010000011101000000100010000111"; 
					--when to_integer(unsigned(RTYPE_SLA))	=>	cw <= "11011010000011011000000110110000111";
					when to_integer(unsigned(RTYPE_SRA))	=>	cw <= "11011010000011001000000100010000111";
					--when to_integer(unsigned(RTYPE_RL))		=>	cw <= "11011010000011110000000110110000111";
					--when to_integer(unsigned(RTYPE_RR))		=>	cw <= "11011010000011100000000110110000111";					
					when others 							=> 	cw <= "00000000000000000000000000000000000"; -- nop
				end case;											   

--11011010000 011 00000000 0000010 0001 11 add
--11011010000 011 00010000 0000010 0001 11 sub
--11011010000 011 00000111 0010010 0001 11 or
--11011010000 011 00000001 0010010 0001 11 and
--11011010000 011 00001000 0010010 0001 11 nor
--11011010000 011 00001110 0010010 0001 11 nand
--11011010000 011 00000110 0010010 0001 11 xor
--11011010000 011 00001001 0010010 0001 11 xnor

--11011010000 011 00010000 0110110 0001 11 sge
--11011010000 011 00010000 0111010 0001 11 sle
--11011010000 011 00010000 0110010 0001 11 sne
--11011010000 011 00010000 0111110 0001 11 see

--11011010000 011 11100000 0100010 0001 11 sll
--11011010000 011 10100000 0100010 0001 11 srl
--11011010000 011 01100000 0100010 0001 11 sla
--11011010000 011 00100000 0100010 0001 11 sra
--11011010000 011 11000000 0100010 0001 11 rll  -- da cotrollare il se logic o arith
--11011010000 011 10000000 0100010 0001 11 rrl  -- same here

--10010110000 010 00000000 0000010 0001 11 addi
--10010110000 010 00010000 0000010 0001 11 subi
--10010110000 010 00000001 0010010 0001 11 andi
--10010110000 010 00001110 0010010 0001 11 nandi
--10010110000 010 00000111 0010010 0001 11 ori
--10010110000 010 00001000 0010010 0001 11 nori
--10010110000 010 00000110 0010010 0001 11 xori
--10010110000 010 00001001 0010010 0001 11 xnori
--10010110000 010 00010000 0110110 0001 11 sgei
--10010110000 010 00010000 0111010 0001 11 slei
--10010110000 010 00010000 0110010 0001 11 snei
--10010110000 010 00010000 0111110 0001 11 seei
--shift
--10010110010 010 11100000 0100010 0001 11 slli
--10010110010 010 10100000 0100010 0001 11 srli
--10010110010 010 00100000 0100010 0001 11 srai


-- Stype
--11011110000 010 00000000 0000011 1010 10 sw
--11011110010 010 00000000 0000011 0110 11 lw
--mult 
		-------------------------------------------------------------
			when to_integer(unsigned(ITYPE_ADDI))	=> 	cw <= "10010110010010000000000000010000111";
			when to_integer(unsigned(ITYPE_SUBI))	=> 	cw <= "10010110010010000100000000010000111";			
			when to_integer(unsigned(ITYPE_ANDI))	=> 	cw <= "10010110010010000000010010010000111";
			--when to_integer(unsigned(ITYPE_NANDI))	=> 	cw <= "10010110000010000011100010010000111";
			when to_integer(unsigned(ITYPE_ORI))	=> 	cw <= "10010110010010000001110010010000111";
			--when to_integer(unsigned(ITYPE_NORI))	=> 	cw <= "10010110000010000010000010010000111";
			when to_integer(unsigned(ITYPE_XORI))	=> 	cw <= "10010110010010000001100010010000111";
			--when to_integer(unsigned(ITYPE_XNORI))	=> 	cw <= "10010110000010000001100010010000111";
			when to_integer(unsigned(ITYPE_SGEI))	=> 	cw <= "10010110010010000100000110110000111";
			when to_integer(unsigned(ITYPE_SLEI))	=> 	cw <= "10010110010010000100000111010000111";
			--when to_integer(unsigned(ITYPE_SEEI))	=> 	cw <= "10010110000010000100000111110000111";
			when to_integer(unsigned(ITYPE_SNEI))	=> 	cw <= "10010110010010000100000110010000111";
			when to_integer(unsigned(ITYPE_SRLI))	=> 	cw <= "10010110010010101000000100010000111";
			when to_integer(unsigned(ITYPE_SLLI))	=> 	cw <= "10010110010010111000000100010000111";
			when to_integer(unsigned(ITYPE_SRAI))	=> 	cw <= "10010110010010001000000100010000111";
		--------------------------------------------------------------	
			when to_integer(unsigned(JTYPE_BEQZ))	=> 	cw <= "01000011000000000000000000000000000"; -- ok
			when to_integer(unsigned(JTYPE_BNEZ))	=> 	cw <= "01000011100000000000000000000000000"; -- ok
			when to_integer(unsigned(JTYPE_J))		=> 	cw <= "00000000100000000000000000000000000"; -- ok
			when to_integer(unsigned(JTYPE_JAL))	=> 	cw <= "00100000101100000000000000010000111"; -- ok
		---------------------------------------------------------------
			--when to_integer(unsigned(MTYPE_MULT))	=>	cw <= "11011010000011000000001000010000111";
			when to_integer(unsigned(STYPE_SW))		=> 	cw <= "11011110000010000000000000011101010";
			when to_integer(unsigned(LTYPE_LW))		=> 	cw <= "11011110010010000000000000011011011";
			when to_integer(unsigned(NTYPE_NOP))	=> 	cw <= "00000000000000000000000000000000000"; -- nop

			when others 							=> 	cw <= "00000000000000000000000000000000000";
	 end case;
	end process cw_selection;
end architecture;
