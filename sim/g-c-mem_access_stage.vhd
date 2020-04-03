library ieee;
use ieee.std_logic_1164.all;
use work.globals.all;

entity mem_access_stage is

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
end entity;

architecture Structural of mem_access_stage is

	component DRAM
  	generic (	MEM_DEPTH 	: integer := 80;
    			D_SIZE 		: integer := 32);
  	port (		RESET 		: in  std_logic;
				CLK			: in  std_logic;
	 			DATAIN		: in  std_logic_vector(D_SIZE-1 downto 0);
				ENABLE		: in  std_logic;
				WR_enable	: in  std_logic;
    			Addr 		: in  std_logic_vector(D_SIZE - 1 downto 0);
    			Dout 		: out std_logic_vector(D_SIZE - 1 downto 0) );
	end component;

	component reg_generic
		generic (N: integer );
		port(	D	:	in	std_logic_vector(N-1 downto 0);
				CLK, RST, EN : 	in	std_logic;
				Q	:	out std_logic_vector(N-1 downto 0));
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

	signal reg_lmd_in: std_logic_vector (NumBit-1 downto 0);
	signal sig_alu:std_logic_vector (NumBit-1 downto 0);

	signal sig_wr_enable, sig_fd_1, sig_fd_2 : std_logic;

begin
sig_alu<=ALU_OUT;
	DRAM_0 : DRAM 	port map (	RESET 		=> RST,
								CLK			=> CLK,
	 							DATAIN		=> REGB_EX_OUT,
								ENABLE		=> DRAM_EN,
								WR_enable	=> sig_wr_enable,
    							Addr 		=> sig_alu,
    							Dout 		=> reg_lmd_in );

	
	reg_lmd: reg_generic 	generic map(N => NumBit)
							port map(	D => reg_lmd_in,
										CLK => CLK,
										RST => RST,
										EN => LMD_LATCH_EN,
										Q => LMD_OUT );

	reg_alu_MA:  reg_generic 	generic map(N => NumBit)
							port map(	D => sig_alu,
										CLK => CLK,
										RST => RST,
										EN => ALU_MA_LATCH_EN,
										Q => ALU_MA_OUT );

	------------------ flush logic
	ff_1 : FD_s port map( 	D 	=> FLUSH,
							CLK	=> CLK,
							RST => RST,
							EN 	=> '1',
							Q	=> sig_fd_1 );
	ff_2 : FD_s port map(	D 	=> sig_fd_1,
							CLK	=> CLK,
							RST => RST,
							EN 	=> '1',
							Q	=> sig_fd_2 );

	mux_dram_flush: mux21 port map(	A 	=> '0',
									B	=> DRAM_WE, 
									SEL => sig_fd_2,
									Y 	=> sig_wr_enable);

end architecture;


