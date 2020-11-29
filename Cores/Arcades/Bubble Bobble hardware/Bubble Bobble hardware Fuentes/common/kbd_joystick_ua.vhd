library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity Kbd_Joystick_ua is
generic
(
		OSD_CMD		 	: in   std_logic_vector(2 downto 0) := "001"
);
port 
(
		Clk          	: in std_logic;
		KbdInt      	: in std_logic;
		KbdScanCode  	: in std_logic_vector(7 downto 0);
		  
		joystick_0 		: in std_logic_vector(5 downto 0);
		joystick_1 		: in std_logic_vector(5 downto 0);
		  
		-- joystick_0 and joystick_1 should be swapped
		joyswap 			: in std_logic := '0';
		
		-- player1 and player2 should get both joystick_0 and joystick_1
		oneplayer		: in std_logic := '0';

		-- tilt, coin4-1, start4-1
		controls			: out std_logic_vector(8 downto 0);
		
		
		-- tilt, coin4-1, start4-1
		F_keys			: out std_logic_vector(12 downto 1);
		
		direct_video    : out std_logic := '0';
		osd_rotate      : out std_logic_vector(1 downto 0) := "00";
		-- fire12-1, up, down, left, right
		player1			: out std_logic_vector(15 downto 0);
		player2			: out std_logic_vector(15 downto 0);
		
		osd_o			 	: out   std_logic_vector(7 downto 0);
		osd_enable		: in std_logic := '1';
		
		-- sega joystick
		sega_clk  		: in std_logic;
		sega_strobe		: out std_logic;
		-- Vector para pulsaciones y switches -- delgrom 
		fn_pulse      : inout std_logic_vector(7 downto 0);
		fn_toggle     : inout std_logic_vector(7 downto 0)
);
end Kbd_Joystick_ua;

architecture Behavioral of Kbd_Joystick_ua is

signal IsReleased : std_logic;
signal osd_s		: std_logic_vector(7 downto 0) := (others=>'1');
signal F_keys_s	: std_logic_vector(12 downto 1) := (others=>'0');

-- keyboard controls
signal btn_tilt : std_logic := '0';
signal btn_one_player : std_logic := '0';
signal btn_two_players : std_logic := '0';
signal btn_three_players : std_logic := '0';
signal btn_four_players : std_logic := '0';
signal btn_left : std_logic := '0';
signal btn_right : std_logic := '0';
signal btn_down : std_logic := '0';
signal btn_up : std_logic := '0';
signal btn_fireA : std_logic := '0';
signal btn_fireB : std_logic := '0';
signal btn_fireC : std_logic := '0';
signal btn_fireD : std_logic := '0';
signal btn_fireE : std_logic := '0';
signal btn_fireF : std_logic := '0';
signal btn_fireG : std_logic := '0';
signal btn_fireH : std_logic := '0';
signal btn_fireI : std_logic := '0';
signal btn_coin  : std_logic := '0';
signal btn_start1_mame : std_logic := '0';
signal btn_start2_mame : std_logic := '0';
signal btn_start3_mame : std_logic := '0';
signal btn_start4_mame : std_logic := '0';
signal btn_coin1_mame : std_logic := '0';
signal btn_coin2_mame : std_logic := '0';
signal btn_coin3_mame : std_logic := '0';
signal btn_coin4_mame : std_logic := '0';
signal btn_up2 : std_logic := '0';
signal btn_down2 : std_logic := '0';
signal btn_left2 : std_logic := '0';
signal btn_right2 : std_logic := '0';
signal btn_fire2A : std_logic := '0';
signal btn_fire2B : std_logic := '0';
signal btn_fire2C : std_logic := '0';
signal btn_fire2D : std_logic := '0';
signal btn_fire2E : std_logic := '0';
signal btn_fire2F : std_logic := '0';
signal btn_fire2G : std_logic := '0';
signal btn_fire2H : std_logic := '0';
signal btn_fire2I : std_logic := '0';

signal btn_scroll : std_logic := '0';									 
signal joy0 : std_logic_vector(5 downto 0);
signal joy1 : std_logic_vector(5 downto 0);

signal p1 : std_logic_vector(15 downto 0);
signal p2 : std_logic_vector(15 downto 0);

-- sega
signal joyP7_s : std_logic := '0';
signal sega1_s : std_logic_vector(11 downto 0) := (others=>'1');
signal sega2_s : std_logic_vector(11 downto 0) := (others=>'1');

signal fn_pulse_r : std_logic_vector(7 downto 0); -- delgrom
signal osd_rotate_s : std_logic_vector(1 downto 0);
signal direct_video_s : std_logic := '1';


begin 

osd_rotate <= osd_rotate_s;
direct_video <= direct_video_s;						   
joy0 <= joystick_1 when joyswap = '1' else joystick_0;
joy1 <= joystick_0 when joyswap = '1' else joystick_1;

controls <= btn_tilt &
            (btn_coin or btn_coin4_mame) & 
				(btn_coin or btn_coin3_mame) &
				(btn_coin or btn_coin2_mame) & 
				(btn_coin or btn_coin1_mame) &
				(btn_four_players  or btn_start4_mame) & 
				(btn_three_players or btn_start3_mame) & 
				(btn_two_players   or btn_start2_mame) &
				(btn_one_player    or btn_start1_mame);
				
				--                1098 7654 3210      
				-- sega1_s format MXYZ SACB UDLR
p1 <= ("0000" & (not ( sega1_s (7) & sega1_s (11) & sega1_s (8) & sega1_s (9) & sega1_s (10) & sega1_s (5) & sega1_s (4) & sega1_s (6) & sega1_s(3 downto 0) )) )
  or "000" & btn_fireI & btn_fireH  &  btn_fireG  & btn_fireF  & btn_fireE  & btn_fireD  & btn_fireC  & btn_fireB  & btn_fireA  & btn_up  & btn_down  & btn_left  & btn_right   when osd_enable = '0' else (others=>'0');

p2 <= ("0000" & (not ( sega2_s (7) & sega2_s (11) & sega2_s (8) & sega2_s (9) & sega2_s (10) & sega2_s (5) & sega2_s (4) & sega2_s (6) & sega2_s(3 downto 0) )) )
  or "000" & btn_fire2I & btn_fire2H &  btn_fire2G & btn_fire2F & btn_fire2E & btn_fire2D & btn_fire2C & btn_fire2B & btn_fire2A & btn_up2 & btn_down2 & btn_left2 & btn_right2 when osd_enable = '0' else (others=>'0');

	  
-- p1 <= (not sega1_s) or "000" & btn_fireI & btn_fireH  &  btn_fireG  & btn_fireF  & btn_fireE  & btn_fireD  & btn_fireC  & btn_fireB  & btn_fireA  & btn_up  & btn_down  & btn_left  & btn_right  when osd_enable = '0' else (others=>'0');
-- p2 <= (not sega2_s) or "000" & btn_fire2I & btn_fire2H &  btn_fire2G & btn_fire2F & btn_fire2E & btn_fire2D & btn_fire2C & btn_fire2B & btn_fire2A & btn_up2 & btn_down2 & btn_left2 & btn_right2 when osd_enable = '0' else (others=>'0');
			
				
player1 <= p1 or p2 when oneplayer = '1' else p1;
player2 <= p1 or p2 when oneplayer = '1' else p2;

osd_o <= osd_s and ("111" & (sega1_s(4) and sega1_s(5) and sega1_s(6) and sega1_s(7) ) & sega1_s(0) & sega1_s(1) & sega1_s(2) & sega1_s(3)) when osd_enable = '1' else osd_s(7 downto 5) & "11111";

F_keys <= F_keys_s;
	 
process(Clk)
begin
								
  if rising_edge(Clk) then
  
    fn_pulse_r <= fn_pulse; -- delgrom 	 
	 
    if KbdInt = '1' then
      
			if KbdScanCode = "11110000" then IsReleased <= '1'; else IsReleased <= '0'; end if; 

			if KbdScanCode = x"05" then F_keys_s(1)    	 <= not(IsReleased); end if; -- F1
			if KbdScanCode = x"06" then F_keys_s(2)   	 <= not(IsReleased); end if; -- F2
			if KbdScanCode = x"04" then F_keys_s(3) 		 <= not(IsReleased); end if; -- F3
			if KbdScanCode = x"0C" then F_keys_s(4)  		 <= not(IsReleased); end if; -- F4
			if KbdScanCode = x"7E" then btn_scroll        <= not(IsReleased); end if; -- Scroll Lock
			
			if KbdScanCode = x"75" then btn_up            <= not(IsReleased); end if; -- up
			if KbdScanCode = x"72" then btn_down          <= not(IsReleased); end if; -- down
			if KbdScanCode = x"6B" then btn_left          <= not(IsReleased); end if; -- left
			if KbdScanCode = x"74" then btn_right         <= not(IsReleased); end if; -- right
			if KbdScanCode = x"76" then btn_coin          <= not(IsReleased); end if; -- ESC

			if KbdScanCode = x"12" then btn_fireD         <= not(IsReleased); end if; -- l-shift
			if KbdScanCode = x"14" then btn_fireC         <= not(IsReleased); end if; -- ctrl
			if KbdScanCode = x"11" then btn_fireB         <= not(IsReleased); end if; -- alt
			if KbdScanCode = x"29" then btn_fireA         <= not(IsReleased); end if; -- Space
			if KbdScanCode = x"1A" then btn_fireE         <= not(IsReleased); end if; -- Z
			if KbdScanCode = x"22" then btn_fireF         <= not(IsReleased); end if; -- X
			if KbdScanCode = x"21" then btn_fireG         <= not(IsReleased); end if; -- C
			if KbdScanCode = x"2A" then btn_fireH         <= not(IsReleased); end if; -- V
			if KbdScanCode = x"32" then btn_fireI         <= not(IsReleased); end if; -- B
			if KbdScanCode = x"66" then btn_tilt          <= not(IsReleased); end if; -- Backspace

			-- JPAC/IPAC/MAME Style Codes
			if KbdScanCode = x"16" then btn_start1_mame   <= not(IsReleased); end if; -- 1
			if KbdScanCode = x"1E" then btn_start2_mame   <= not(IsReleased); end if; -- 2
			if KbdScanCode = x"26" then btn_start3_mame   <= not(IsReleased); end if; -- 3
			if KbdScanCode = x"25" then btn_start4_mame   <= not(IsReleased); end if; -- 4
			if KbdScanCode = x"2E" then btn_coin1_mame    <= not(IsReleased); end if; -- 5
			if KbdScanCode = x"36" then btn_coin2_mame    <= not(IsReleased); end if; -- 6
			if KbdScanCode = x"3D" then btn_coin3_mame    <= not(IsReleased); end if; -- 7
			if KbdScanCode = x"3E" then btn_coin4_mame    <= not(IsReleased); end if; -- 8
			if KbdScanCode = x"2D" then btn_up2           <= not(IsReleased); end if; -- R
			if KbdScanCode = x"2B" then btn_down2         <= not(IsReleased); end if; -- F
			if KbdScanCode = x"23" then btn_left2         <= not(IsReleased); end if; -- D
			if KbdScanCode = x"34" then btn_right2        <= not(IsReleased); end if; -- G
			if KbdScanCode = x"1C" then btn_fire2A        <= not(IsReleased); end if; -- A
			if KbdScanCode = x"1B" then btn_fire2B        <= not(IsReleased); end if; -- S
			if KbdScanCode = x"15" then btn_fire2C        <= not(IsReleased); end if; -- Q
			if KbdScanCode = x"1D" then btn_fire2D        <= not(IsReleased); end if; -- W
			if KbdScanCode = x"43" then btn_fire2E        <= not(IsReleased); end if; -- I
			if KbdScanCode = x"42" then btn_fire2F        <= not(IsReleased); end if; -- K
			if KbdScanCode = x"3B" then btn_fire2G        <= not(IsReleased); end if; -- J
			if KbdScanCode = x"4B" then btn_fire2H        <= not(IsReleased); end if; -- L
			
			-- OSD
			osd_s (4 downto 0) <= "11111";
			if (IsReleased = '0') then	
					if KbdScanCode = x"75" then osd_s(4 downto 0) <= "11110"; end if; -- up    arrow : 0x75
					if KbdScanCode = x"72" then osd_s(4 downto 0) <= "11101"; end if; -- down  arrow : 0x72
					if KbdScanCode = x"6b" then osd_s(4 downto 0) <= "11011"; end if; -- left  arrow : 0x6B
					if KbdScanCode = x"74" then osd_s(4 downto 0) <= "10111"; end if; -- right arrow : 0x74
					if KbdScanCode = x"5A" then osd_s(4 downto 0) <= "01111"; end if; -- ENTER
						
					if KbdScanCode = x"1c" then osd_s(4 downto 0) <= "00000"; end if;	-- A
					if KbdScanCode = x"32" then osd_s(4 downto 0) <= "00001"; end if;	-- B
					if KbdScanCode = x"21" then osd_s(4 downto 0) <= "00010"; end if;	-- C
					if KbdScanCode = x"23" then osd_s(4 downto 0) <= "00011"; end if;	-- D
					if KbdScanCode = x"24" then osd_s(4 downto 0) <= "00100"; end if;	-- E
					if KbdScanCode = x"2b" then osd_s(4 downto 0) <= "00101"; end if;	-- F
					if KbdScanCode = x"34" then osd_s(4 downto 0) <= "00110"; end if;	-- G
					if KbdScanCode = x"33" then osd_s(4 downto 0) <= "00111"; end if;	-- H
					if KbdScanCode = x"43" then osd_s(4 downto 0) <= "01000"; end if;	-- I
					if KbdScanCode = x"3b" then osd_s(4 downto 0) <= "01001"; end if;	-- J
					if KbdScanCode = x"42" then osd_s(4 downto 0) <= "01010"; end if;	-- K
					if KbdScanCode = x"4b" then osd_s(4 downto 0) <= "01011"; end if;	-- L
					if KbdScanCode = x"3a" then osd_s(4 downto 0) <= "01100"; end if;	-- M
					if KbdScanCode = x"31" then osd_s(4 downto 0) <= "01101"; end if;	-- N
					if KbdScanCode = x"44" then osd_s(4 downto 0) <= "01110"; end if;	-- O
					if KbdScanCode = x"4d" then osd_s(4 downto 0) <= "10000"; end if;	-- P
					if KbdScanCode = x"15" then osd_s(4 downto 0) <= "10001"; end if;	-- Q
					if KbdScanCode = x"2d" then osd_s(4 downto 0) <= "10010"; end if;	-- R
					if KbdScanCode = x"1b" then osd_s(4 downto 0) <= "10011"; end if;	-- S
					if KbdScanCode = x"2c" then osd_s(4 downto 0) <= "10100"; end if;	-- T
					if KbdScanCode = x"3c" then osd_s(4 downto 0) <= "10101"; end if;	-- U
					if KbdScanCode = x"2a" then osd_s(4 downto 0) <= "10110"; end if;	-- V
					if KbdScanCode = x"1d" then osd_s(4 downto 0) <= "11000"; end if;	-- W
					if KbdScanCode = x"22" then osd_s(4 downto 0) <= "11001"; end if;	-- X
					if KbdScanCode = x"35" then osd_s(4 downto 0) <= "11010"; end if;	-- Y
					if KbdScanCode = x"1a" then osd_s(4 downto 0) <= "11100"; end if;	-- Z
					
			end if;
			
			if (KbdScanCode = x"07" and IsReleased = '0') or  -- key F12
			   (KbdScanCode = x"76" and IsReleased = '0' and osd_enable = '1') then -- ESC to abort an opened menu
	
				osd_s(7 downto 5) <= OSD_CMD; -- OSD Menu command
		--	elsif (KbdScanCode = x"78" and IsReleased = '0') then  -- key F11
		--		osd_s(7 downto 5) <= "111"; -- OSD Menu command
			else
				osd_s(7 downto 5) <= "111"; -- release
			end if;
			
	 end if;
	 
	 -- delgrom pulsadores
	 --if fn_pulse_r(0) = '1' and fn_pulse(0) = '0' then fn_toggle(0) <= not fn_toggle(0); end if;
 	 --if fn_pulse_r(1) = '1' and fn_pulse(1) = '0' then fn_toggle(1) <= not fn_toggle(1); end if;
 	 --if fn_pulse_r(2) = '1' and fn_pulse(2) = '0' then fn_toggle(2) <= not fn_toggle(2); end if;
 	 --if fn_pulse_r(3) = '1' and fn_pulse(3) = '0' then fn_toggle(3) <= not fn_toggle(3); end if;
 	 --if fn_pulse_r(4) = '1' and fn_pulse(4) = '0' then fn_toggle(4) <= not fn_toggle(4); end if;
 	 --if fn_pulse_r(5) = '1' and fn_pulse(5) = '0' then fn_toggle(5) <= not fn_toggle(5); end if;
 	 --if fn_pulse_r(6) = '1' and fn_pulse(6) = '0' then fn_toggle(6) <= not fn_toggle(6); end if;
 	 --if fn_pulse_r(7) = '1' and fn_pulse(7) = '0' then fn_toggle(7) <= not fn_toggle(7); end if;
	 
 
  end if;
end process;

--
--process(F_keys_s(11))
--begin                            
--  if rising_edge(F_keys_s(11)) then
--        if osd_enable = '1' then
--            osd_rotate_s <= osd_rotate_s + 1;
--        end if;
--  end if;
--end process;

process(btn_scroll)
begin                            
  if rising_edge(btn_scroll) then
        direct_video_s <= not direct_video_s;
  end if;
end process;					 

--- Joystick read with sega 6 button support----------------------

	process(sega_clk)
		variable state_v : unsigned(8 downto 0) := (others=>'0');
		variable j1_sixbutton_v : std_logic := '0';
		variable j2_sixbutton_v : std_logic := '0';
	begin
		if falling_edge(sega_clk) then
		
			state_v := state_v + 1;
			
			case state_v is
				-- joy_s format MXYZ SACB UDLR
				
				when '0'&X"01" =>  
					joyP7_s <= '0';
					
				when '0'&X"02" =>  
					joyP7_s <= '1';
					
				when '0'&X"03" => 
					sega1_s(5 downto 0) <= joy0(5 downto 0); -- C, B, up, down, left, right 
					sega2_s(5 downto 0) <= joy1(5 downto 0);		
					
					j1_sixbutton_v := '0'; -- Assume it's not a six-button controller
					j2_sixbutton_v := '0'; -- Assume it's not a six-button controller

					joyP7_s <= '0';

				when '0'&X"04" =>
					if joy0(0) = '0' and joy0(1) = '0' then -- it's a megadrive controller
								sega1_s(7 downto 6) <= joy0(5 downto 4); -- A, Start
					else
								--sega1_s(7 downto 4) <= "11" & joy0(5 downto 4); -- read A/B as master System
								
								--              1098 7654 3210
								-- joy_s format MXYZ SACB UDLR
								sega1_s(7 downto 4) <= '1' & joy0(4) & '1' & joy0(5); -- read A/B as master System								
					end if;
							
					if joy1(0) = '0' and joy1(1) = '0' then -- it's a megadrive controller
								sega2_s(7 downto 6) <=  joy1(5 downto 4); -- A, Start
					else
								--sega2_s(7 downto 4) <= "11" & joy1(5 downto 4); -- read A/B as master System
								--              1098 7654 3210
								-- joy_s format MXYZ SACB UDLR
								sega2_s(7 downto 4) <= '1' & joy1(4) & '1' & joy1(5); -- read A/B as master System																
								
									
					end if;
					
										
					joyP7_s <= '1';
			
				when '0'&X"05" =>  
					joyP7_s <= '0';
					
				when '0'&X"06" =>
					if joy0(2) = '0' and joy0(3) = '0' then 
						j1_sixbutton_v := '1'; --it's a six button
					end if;
					
					if joy1(2) = '0' and joy1(3) = '0' then 
						j2_sixbutton_v := '1'; --it's a six button
					end if;
					
					joyP7_s <= '1';
					
				when '0'&X"07" =>
					if j1_sixbutton_v = '1' then
						sega1_s(11 downto 8) <= joy0(0) & joy0(1) & joy0(2) & joy0(3); -- Mode, X, Y e Z
					end if;
					
					if j2_sixbutton_v = '1' then
						sega2_s(11 downto 8) <= joy1(0) & joy1(1) & joy1(2) & joy1(3); -- Mode, X, Y e Z
					end if;
					
					joyP7_s <= '0';
					


				when others =>
					joyP7_s <= '1';
					
			end case;

		end if;
	end process;
	
	sega_strobe <= joyP7_s;
---------------------------

end Behavioral;


