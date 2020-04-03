library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.globals.all;

entity register_file is
 	generic ( 	N: integer ;
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
	 		OUT2: 		OUT std_logic_vector(N-1 downto 0) );
end register_file;

architecture Behavioral of register_file is

    subtype REG_ADDR is natural range 0 to tot_regs-1; -- using natural type
	type REG_ARRAY is array(REG_ADDR) of std_logic_vector(N-1 downto 0); 
	signal REGISTERS : REG_ARRAY; 
	
begin 

-- policy for concurrency: WRITE and THEN read

	proc : process(RESET, CLK, RD1, RD2, WR, ENABLE) is	
	begin 
		if ( CLK'event and CLK = '1') then
			if (RESET = '1') then 
				for i in 0 to tot_regs-1 loop
					REGISTERS(i) <= std_logic_vector(to_unsigned(i, N));
				end loop;
			elsif (ENABLE = '1') then 
				if ( WR = '1' ) then 
  					REGISTERS(to_integer(unsigned(ADD_WR))) <= DATAIN;  
     			end if;
				if ( RD1 = '1') then
					OUT1 <= REGISTERS(to_integer(unsigned(ADD_RD1)));
                end if;
				if ( RD2 = '1' ) then
					OUT2 <= REGISTERS(to_integer(unsigned(ADD_RD2)));
				end if;	
			end if;  
		end if ;
	end process;

end architecture;
