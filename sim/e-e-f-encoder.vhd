library ieee;
use ieee.std_logic_1164.all;

entity encoder is
	port ( X : in  std_logic_vector(2 downto 0);
	       Y : out std_logic_vector(2 downto 0));
end entity;

architecture Behavioral of encoder is
begin

  process (X)
  begin 
    case X is
      when "000" | "111" => Y <= "000";
      when "001" | "010" => Y <= "001";
      when "011" =>  Y <= "011";
      when "100" => Y <= "100";
      when "101" | "110" => Y <= "010";
      when others => Y <= "000"; 
    end case;
  end process;
end architecture Behavioral;
