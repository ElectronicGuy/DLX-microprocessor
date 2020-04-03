library ieee;
use ieee.std_logic_1164.all;
use work.globals.all;

entity write_back_stage is

	port (	LMD_OUT : 		in std_logic_vector (NumBit-1 downto 0);
			ALU_MA_OUT : 		in std_logic_vector (NumBit-1 downto 0);

			MUX_SEL_WB : 	in std_logic;

			RF_DATA_IN : 		out std_logic_vector (NumBit-1 downto 0) );
end entity;

architecture Structural of write_back_stage is

	component mux21_generic
		generic (N: integer:= NumBit);
		port (	A:	In	std_logic_vector(N-1 downto 0);
				B:	In	std_logic_vector(N-1 downto 0);
				SEL:In	std_logic;
				Y:	Out	std_logic_vector(N-1 downto 0)); 
	end component;

begin

	Mux_wb : mux21_generic 		generic map(N => NumBit)
								port map(	B => LMD_OUT,
											A => ALU_MA_OUT,
											SEL => MUX_SEL_WB,
											Y => RF_DATA_IN );
end architecture;
