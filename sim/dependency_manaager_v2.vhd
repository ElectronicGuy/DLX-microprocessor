library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;

entity dependency_manager is
	port( 	RST				: in std_logic;
			IR				: in std_logic_vector(31 downto 0);
			IR_OUT			: out std_logic_vector(31 downto 0);
			DIRTY_BIT		: out std_logic;
			EN_OUT			: out std_logic;
			REG_DELAY1		: in std_logic_vector(5 downto 0);  
			REG_DELAY2		: in std_logic_vector(5 downto 0); 
			REG_DELAY3		: in std_logic_vector(5 downto 0); 
			REG_DELAY4		: in std_logic_vector(5 downto 0));
end entity;

architecture behavioural of dependency_manager is

	signal source1, source2 : std_logic_vector(5 downto 0);
	signal opcode 			: std_logic_vector(5 downto 0);
	
begin

	comaparison: process(RST, REG_DELAY1, REG_DELAY2, REG_DELAY3, REG_DELAY4, IR) is
		
	begin 
		source2 <= '0' & IR(20 downto 16);
		source1 <= '0' & IR(25 downto 21);
		opcode 	<= IR(31 downto 26); 
 		
		if (RST = '1') then
			IR_OUT <= IR;
			EN_OUT <= '1';
		else
			case opcode is
				when RTYPE =>
					if ( REG_DELAY1 = source1 ) then
						IR_OUT <= (others => '0');
						DIRTY_BIT <= '1';
						EN_OUT <= '0';
					elsif( REG_DELAY1 = source2 ) then
						IR_OUT <= (others => '0');
						DIRTY_BIT <= '1';
						EN_OUT <= '0';
					elsif( REG_DELAY2 = source1 ) then
						IR_OUT <= (others => '0');
						DIRTY_BIT <= '1';
						EN_OUT <= '0';
					elsif( REG_DELAY2 = source2 ) then
						IR_OUT <= (others => '0');
						DIRTY_BIT <= '1';
						EN_OUT <= '0';
					elsif( REG_DELAY3 = source1 ) then
						IR_OUT <= (others => '0');
						DIRTY_BIT <= '1';
						EN_OUT <= '0';
					elsif( REG_DELAY3 = source2 ) then
						IR_OUT <= (others => '0');
						DIRTY_BIT <= '1';
						EN_OUT <= '0';
					elsif( REG_DELAY4 = source1 ) then
						IR_OUT <= (others => '0');
						DIRTY_BIT <= '1';
						EN_OUT <= '0';
					elsif( REG_DELAY4 = source2 ) then
						IR_OUT <= (others => '0');
						DIRTY_BIT <= '1';
						EN_OUT <= '0';
					else
						IR_OUT <= IR;
						DIRTY_BIT <= '0';
						EN_OUT <= '1';
					end if;
			
				when JTYPE_J => 	IR_OUT <= IR;
									DIRTY_BIT <= '0';
									EN_OUT <= '1';
				when JTYPE_JAL => 	IR_OUT <= IR;
									DIRTY_BIT <= '0';
									EN_OUT <= '1';
				

				when others => -- ITYPE + BRANCHES
					if ( REG_DELAY1 = source1) then
						IR_OUT <= (others => '0');
						DIRTY_BIT <= '1';
						EN_OUT <= '0';
					elsif ( REG_DELAY2 = source1 ) then
						IR_OUT <= (others => '0');
						DIRTY_BIT <= '1';
						EN_OUT <= '0';
					elsif( REG_DELAY3 = source1 ) then
						IR_OUT <= (others => '0');
						DIRTY_BIT <= '1';
						EN_OUT <= '0';	
					elsif( REG_DELAY4 = source1 ) then
						IR_OUT <= (others => '0');
						DIRTY_BIT <= '1';
						EN_OUT <= '0';	
					else
						IR_OUT <= IR;
						DIRTY_BIT <= '0';
						EN_OUT <= '1';
					end if;
			end case;
		end if;
	end process;
end architecture; 
