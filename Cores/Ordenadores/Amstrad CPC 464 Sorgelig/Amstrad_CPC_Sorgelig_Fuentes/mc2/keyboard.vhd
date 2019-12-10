-----------------------------------------------------
--
--  Multicore 2 keyboard adapter by Victor Trucco
--
-----------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity Keyboard is
port (
  Clk          : in std_logic;
  KbdInt       : in std_logic;
  KbdScanCode  : in std_logic_vector(7 downto 0);
  Keyboarddata : out std_logic_vector(10 downto 0);
  osd_o			: out   std_logic_vector(7 downto 0)
);
end Keyboard;

architecture Behavioral of Keyboard is

signal IsReleased : std_logic;
signal osd_s : std_logic_vector(7 downto 0) := "11111111";

begin 

process(Clk)
begin
  if rising_edge(Clk) then
  
	osd_o <= osd_s;
  
    if KbdInt = '1' then
	 
			if KbdScanCode = "11110000" then IsReleased <= '1'; else IsReleased <= '0'; end if; 

			--[10] - toggles with every press/release, [9] - pressed, [8] - extended, [7:0] ps2 scan code
			
			Keyboarddata <= '1' & not IsReleased & '0' & KbdScanCode;
			
			
			if KbdScanCode = "01110101" then osd_s(0) <= (IsReleased); end if; -- up    arrow : 0x75
			if KbdScanCode = "01110010" then osd_s(1) <= (IsReleased); end if; -- down  arrow : 0x72
			if KbdScanCode = "01101011" then osd_s(2) <= (IsReleased); end if; -- left  arrow : 0x6B
			if KbdScanCode = "01110100" then osd_s(3) <= (IsReleased); end if; -- right arrow : 0x74	
			if KbdScanCode = x"5A" 	    then osd_s(4) <= (IsReleased); end if; -- ENTER	
			
			if KbdScanCode = x"07" then -- F12
				if IsReleased = '0' then 
					osd_s(7 downto 5) <= "001"; 
				else
					osd_s(7 downto 5) <= "111";
				end if; 
			end if;
				
				
	 
	 else
	 
			Keyboarddata <= (others=>'0');
    
	 end if;
 
  end if;
end process;

end Behavioral;


