library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Data memory for DLX (combinational)
entity DRAM is
  generic (	MEM_DEPTH 	: integer := 80;
    		D_SIZE 		: integer := 32);
  port (	RESET 		: in  std_logic;
			CLK			: in  std_logic;
	 		DATAIN		: in  std_logic_vector(D_SIZE-1 downto 0);
			ENABLE		: in  std_logic;
			WR_enable	: in  std_logic;
    		Addr 		: in  std_logic_vector(D_SIZE - 1 downto 0);
    		Dout 		: out std_logic_vector(D_SIZE - 1 downto 0) );

end DRAM;

architecture Structutal of DRAM is

  type MEMtype is array (0 to MEM_DEPTH-1) of std_logic_vector (D_SIZE-1 downto 0);-- std_logic_vector(I_SIZE - 1 downto 0);
  signal DRAM_mem : MEMtype;

begin

	proc_0 : process(RESET, CLK, WR_enable, ENABLE) is		
	begin 
		if ( CLK'event and CLK = '1') then
			if (RESET = '1') then 
				for i in 0 to MEM_DEPTH-1 loop
					DRAM_mem(i) <= (others => '0');
				end loop;

			elsif (ENABLE = '1') then 
	
				if ( WR_enable = '1') then
					DRAM_mem(to_integer(unsigned(Addr))) <= DATAIN;
				else
					Dout <= DRAM_mem(to_integer(unsigned(Addr)));
                
				end if;
			end if;  
		end if ;
	end process;

end architecture;
