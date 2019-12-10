library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity Kbd_Joystick is
port (
  Clk          : in std_logic;
  KbdInt       : in std_logic;
  KbdScanCode  : in std_logic_vector(7 downto 0);
  JoyBCPPFRLDU  : out std_logic_vector(12 downto 0);
  -- delgrom
  changeScandoubler  : out std_logic;
  changeScanlines  : out std_logic;
  reset : out std_logic  
);
end Kbd_Joystick;

architecture Behavioral of Kbd_Joystick is

signal IsReleased : std_logic;

begin 

process(Clk)
begin
  if rising_edge(Clk) then
  
    if KbdInt = '1' then
      if KbdScanCode = "11110000" then IsReleased <= '1'; else IsReleased <= '0'; end if; 
      if KbdScanCode = "01110101" then JoyBCPPFRLDU(0) <= not(IsReleased); end if; -- up    arrow : 0x75
      if KbdScanCode = "01110010" then JoyBCPPFRLDU(1) <= not(IsReleased); end if; -- down  arrow : 0x72
      if KbdScanCode = "01101011" then JoyBCPPFRLDU(2) <= not(IsReleased); end if; -- left  arrow : 0x6B
      if KbdScanCode = "01110100" then JoyBCPPFRLDU(3) <= not(IsReleased); end if; -- right arrow : 0x74
      if KbdScanCode = "00101001" then JoyBCPPFRLDU(4) <= not(IsReleased); end if; -- space : 0x29
      if KbdScanCode = "00000101" then JoyBCPPFRLDU(5) <= not(IsReleased); end if; -- F1 : 0x05
      if KbdScanCode = "00000110" then JoyBCPPFRLDU(6) <= not(IsReleased); end if; -- F2 : 0x06
      if KbdScanCode = "00000100" then JoyBCPPFRLDU(7) <= not(IsReleased); end if; -- F3 : 0x04
      if KbdScanCode = "00010100" then JoyBCPPFRLDU(8) <= not(IsReleased); end if; -- ctrl : 0x14		
	
      if KbdScanCode = x"1d" then JoyBCPPFRLDU(9)  <= not(IsReleased); end if; -- W
      if KbdScanCode = x"1b" then JoyBCPPFRLDU(10) <= not(IsReleased); end if; -- S
      if KbdScanCode = x"1c" then JoyBCPPFRLDU(11) <= not(IsReleased); end if; -- A
      if KbdScanCode = x"23" then JoyBCPPFRLDU(12) <= not(IsReleased); end if; -- D

		-- delgrom
		if KbdScanCode = "01111110" then changeScandoubler <= not(IsReleased); end if; -- ScrLock : 0x7E	
		if KbdScanCode = "00001100" then changeScanlines <= not(IsReleased); end if; -- F4 : 0x0C	
		if KbdScanCode = "01110110" then reset <= not(IsReleased); end if; -- ESC : 0x76			
    end if;
 
  end if;
end process;

end Behavioral;


