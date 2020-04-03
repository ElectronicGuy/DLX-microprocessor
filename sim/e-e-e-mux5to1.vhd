library ieee;
use ieee.std_logic_1164.all;

entity mux5to1 is

  generic (N : integer );
  port ( A         : in  std_logic_vector (N-1 downto 0);
         B         : in  std_logic_vector (N-1 downto 0);
         C         : in  std_logic_vector (N-1 downto 0);
         D         : in  std_logic_vector (N-1 downto 0);
         E         : in  std_logic_vector (N-1 downto 0);
         Y         : out std_logic_vector (N-1 downto 0);
         SEL       : in  std_logic_vector (2 downto 0) );
end entity;

architecture Behavioral of mux5to1 is
begin
  process (SEL)
  begin
    case SEL is 
      when "000" => Y <= A;
      when "001" => Y <= B;
      when "010" => Y <= C;
      when "011" => Y <= D;
      when "100" => Y <= E;
      when others => Y <= A;
   end case;
  end process;

end architecture Behavioral;
