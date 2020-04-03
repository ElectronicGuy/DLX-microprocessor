library ieee;
use ieee.std_logic_1164.all;

entity tb_top_entity is
end entity;

architecture tb_top_entity_TEST of tb_top_entity is

component top_entity 
port (CLK, RST 	: in std_logic);
end component;
	signal sig_clk: std_logic:= '0';
	signal rst: std_logic;
begin 

process_clock: process (sig_clk) is
	begin 
		sig_clk <= not(sig_clk) after 1 ns;
	end process;
 rst<= '1','0' after 4 ns;

map_0: top_entity port map (CLK=>sig_clk,
							RST=>rst);
end architecture;
