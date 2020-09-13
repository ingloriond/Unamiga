library ieee;   
use ieee.std_logic_1164.all;  
use ieee.std_logic_unsigned.all; 
 
entity spram is 
  generic (
      addr_width_g : integer := 8;
      data_width_g : integer := 8
   ); 
  port (clk : in std_logic;  
        we  : in std_logic;   
        a   : in std_logic_vector(addr_width_g-1 downto 0);   
        di  : in std_logic_vector(data_width_g-1 downto 0);  
        do  : out std_logic_vector(data_width_g-1 downto 0); 
end spram;
   
architecture syn of raminfr is   
  type ram_type is array ((2**addr_width_g-1) downto 0)   
        of std_logic_vector ((data_width_g-1) downto 0);   
  signal ram : ram_type := (others => (others => '0'));   

begin   
  process (clk)   
  begin   
    if (clk'event and clk = '1') then   
      if (we = '1') then   
        RAM(conv_integer(a)) <= di;   
      end if;   
    end if;   
  end process;   
  do <= RAM(conv_integer(a));   
end syn; 