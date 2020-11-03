library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity Kbd_Joystick is
port (
  Clk          : in std_logic;
  KbdInt       : in std_logic;
  KbdScanCode  : in std_logic_vector(7 downto 0);
  JoyPCFRLDU   : out std_logic_vector(8 downto 0);
  osd_o			 : out   std_logic_vector(7 downto 0);
  -- delgrom
  changeScandoubler  : out std_logic;
  changeScanlines  : out std_logic;
  reset : out std_logic;
  changeBlend  : out std_logic    
);
end Kbd_Joystick;

architecture Behavioral of Kbd_Joystick is

signal IsReleased : std_logic;
signal osd_s		: std_logic_vector(7 downto 0) := (others=>'1');

begin 

osd_o <= osd_s;

process(Clk)
begin
  if rising_edge(Clk) then
  
    if KbdInt = '1' then
      if KbdScanCode = "11110000" then IsReleased <= '1'; else IsReleased <= '0'; end if; 
      if KbdScanCode = "01110101" then JoyPCFRLDU(0) <= not(IsReleased); end if;
      if KbdScanCode = "01110010" then JoyPCFRLDU(1) <= not(IsReleased); end if;
      if KbdScanCode = "01101011" then JoyPCFRLDU(2) <= not(IsReleased); end if;
      if KbdScanCode = "01110100" then JoyPCFRLDU(3) <= not(IsReleased); end if;
      if KbdScanCode = "00101001" then JoyPCFRLDU(4) <= not(IsReleased); end if;
      if KbdScanCode = "00000101" then JoyPCFRLDU(5) <= not(IsReleased); end if; -- F1 : 0x05
      if KbdScanCode = "00000110" then JoyPCFRLDU(6) <= not(IsReleased); end if; -- F2 : 0x06
      if KbdScanCode = "00000100" then JoyPCFRLDU(7) <= not(IsReleased); end if; -- F3 : 0x04
	   if KbdScanCode = x"14" 		 then JoyPCFRLDU(8) <= not(IsReleased); end if; -- Left Control
		
		-- delgrom unamiga
		if KbdScanCode = "01111110" then changeScandoubler <= not(IsReleased); end if; -- ScrLock : 0x7E	
		if KbdScanCode = "00001100" then changeScanlines <= not(IsReleased); end if; -- F4 : 0x0C	
      if KbdScanCode = "00000011" then changeBlend <= not(IsReleased); end if; -- F5 : 0x03			
		if KbdScanCode = "01110110" then reset <= not(IsReleased); end if; -- ESC : 0x76			
		
					
		-- OSD
      if KbdScanCode = "01110101" then osd_s(0) <= (IsReleased); end if; -- up    arrow : 0x75
      if KbdScanCode = "01110010" then osd_s(1) <= (IsReleased); end if; -- down  arrow : 0x72
      if KbdScanCode = "01101011" then osd_s(2) <= (IsReleased); end if; -- left  arrow : 0x6B
      if KbdScanCode = "01110100" then osd_s(3) <= (IsReleased); end if; -- right arrow : 0x74
		if KbdScanCode = x"5A"		 then osd_s(4) <= (IsReleased); end if; -- ENTER 
		
		if KbdScanCode = x"07" and IsReleased = '0' then -- key F12
			osd_s(7 downto 5) <= "011"; -- OSD Menu command
		else
			osd_s(7 downto 5) <= "111"; -- release
		end if;
		
    end if;
 
  end if;
end process;

end Behavioral;


