---------------------------------------------------------------------------------
-- unamiga 2 Top level for Time Pilot 
-- delgrom (17/11/2019)
-- Based on Multicore 2 Top level for Time pilot by Victor Trucco
--
-- New scandoubler with scanlines support ( Till Harbaum)
-- 15/31khz switch with Bloq Desp key
-- Reset with Esc key
-- Rotatory scanlines with F4 key (0, 25%, 50%, 75%)
---------------------------------------------------------------------------------
-- Multicore 2 Top level for Time Pilot 
-- Victor Trucco 2018
-- Based on DE10_lite Top level for Time pilot by Dar (darfpga@aol.fr) (29/10/2017)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------
-- Use time_pilot_lite.sdc to compile (Timequest constraints)
-- /!\
-- Don't forget to set device configuration mode with memory initialization 
--  (Assignments/Device/Pin options/Configuration mode)
---------------------------------------------------------------------------------
--
-- Main features :
--  PS2 keyboard input @gpio pins 35/34 (beware voltage translation/protection) 
--  Audio pwm output   @gpio pins 1/3 (beware voltage translation/protection) 
--
-- Uses 1 pll for 12MHz and 14MHz generation from 50MHz
--
-- Board key :
--   0 : reset game
--
-- Keyboard players inputs :
--
--   F3 : Add coin
--   F2 : Start 2 players
--   F1 : Start 1 player
--   SPACE       : Fire  
--   RIGHT arrow : rotate right
--   LEFT  arrow : rotate left
--   UP    arrow : rotate up 
--   DOWN  arrow : rotate down
--
-- Other details : see time_pilot.vhd
-- For USB inputs and SGT5000 audio output see my other project: xevious_de10_lite
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
--use work.usb_report_pkg.all;

entity time_pilot_top is
port(
-- Clocks
		clock_50_i			: in    std_logic;

		-- Buttons
		btn_n_i				: in    std_logic_vector(4 downto 1);

		-- SRAMs (AS7C34096)
		sram_addr_o			: out   std_logic_vector(18 downto 0)	:= (others => '0');
		sram_data_io		: inout std_logic_vector(7 downto 0)	:= (others => 'Z');
		sram_we_n_o			: out   std_logic								:= '1';
		sram_oe_n_o			: out   std_logic								:= '1';
		
		-- SDRAM	(H57V256)
		sdram_ad_o			: out std_logic_vector(12 downto 0);
		sdram_da_io			: inout std_logic_vector(15 downto 0);

		sdram_ba_o			: out std_logic_vector(1 downto 0);
		sdram_dqm_o			: out std_logic_vector(1 downto 0);

		sdram_ras_o			: out std_logic;
		sdram_cas_o			: out std_logic;
		sdram_cke_o			: out std_logic;
		sdram_clk_o			: out std_logic;
		sdram_cs_o			: out std_logic;
		sdram_we_o			: out std_logic;
	

		-- PS2
		ps2_clk_io			: inout std_logic								:= 'Z';
		ps2_data_io			: inout std_logic								:= 'Z';
		ps2_mouse_clk_io  : inout std_logic								:= 'Z';
		ps2_mouse_data_io : inout std_logic								:= 'Z';

		-- SD Card
		sd_cs_n_o			: out   std_logic								:= 'Z';
		sd_sclk_o			: out   std_logic								:= 'Z';
		sd_mosi_o			: out   std_logic								:= 'Z';
		sd_miso_i			: in    std_logic								:= 'Z';

		-- Joysticks
		joy1_up_i			: in    std_logic;
		joy1_down_i			: in    std_logic;
		joy1_left_i			: in    std_logic;
		joy1_right_i		: in    std_logic;
		joy1_p6_i			: in    std_logic;
		joy1_p9_i			: in    std_logic;
		joy2_up_i			: in    std_logic;
		joy2_down_i			: in    std_logic;
		joy2_left_i			: in    std_logic;
		joy2_right_i		: in    std_logic;
		joy2_p6_i			: in    std_logic;
		joy2_p9_i			: in    std_logic;
		joyX_p7_o			: out   std_logic								:= '1';

		-- Audio
		dac_l_o				: out   std_logic								:= '0';
		dac_r_o				: out   std_logic								:= '0';
		ear_i					: in    std_logic;
		mic_o					: out   std_logic								:= '0';

		-- VGA
		vga_r_o				: out   std_logic_vector(4 downto 0)	:= (others => '0');
		vga_g_o				: out   std_logic_vector(4 downto 0)	:= (others => '0');
		vga_b_o				: out   std_logic_vector(4 downto 0)	:= (others => '0');
		vga_hsync_n_o		: out   std_logic								:= '1';
		vga_vsync_n_o		: out   std_logic								:= '1';

		--STM32
		stm_rx_o				: out std_logic		:= 'Z'; -- stm RX pin, so, is OUT on the slave
		stm_tx_i				: in  std_logic		:= 'Z'; -- stm TX pin, so, is IN on the slave
		stm_rst_o			: out std_logic		:= 'Z'; -- '0' to hold the microcontroller reset line, to free the SD card
		
		stm_a15_io			: inout std_logic;
		stm_b8_io			: inout std_logic		:= 'Z';
		stm_b9_io			: inout std_logic		:= 'Z';
		stm_b12_io			: inout std_logic		:= 'Z';
		stm_b13_io			: inout std_logic		:= 'Z';
		stm_b14_io			: inout std_logic		:= 'Z';
		stm_b15_io			: inout std_logic		:= 'Z'
);
end;

architecture struct of time_pilot_top is

	function to_slv(s: string) return std_logic_vector is 
        constant ss: string(1 to s'length) := s; 
        variable answer: std_logic_vector(1 to 8 * s'length); 
        variable p: integer; 
        variable c: integer; 
    begin 
        for i in ss'range loop
            p := 8 * i;
            c := character'pos(ss(i));
            answer(p - 7 to p) := std_logic_vector(to_unsigned(c,8)); 
        end loop; 
        return answer; 
    end function; 

 signal clock_12  : std_logic;
 signal clock_14  : std_logic;
 signal reset     : std_logic;
 signal clock_6   : std_logic;
 
-- signal max3421e_clk : std_logic;
 
 signal r         : std_logic_vector(2 downto 0);
 signal g         : std_logic_vector(2 downto 0);
 signal b         : std_logic_vector(2 downto 0);
 signal csync     : std_logic;
 signal blankn    : std_logic;

 signal audio           : std_logic_vector(10 downto 0);
 signal pwm_accumulator : std_logic_vector(12 downto 0);

 --alias reset_n         : std_logic is btn_n_i(4);
 alias ps2_clk         : std_logic is ps2_clk_io;
 alias ps2_dat         : std_logic is ps2_data_io;

 
 signal kbd_intr      : std_logic;
 signal kbd_scancode  : std_logic_vector(7 downto 0);
 signal joyPCFRLDU : std_logic_vector(7 downto 0);
 

 -- delgrom senales asociadas a teclas unamiga
 signal scandoublerD : std_logic := '0'; -- '1' 15khz, '0' VGA
 signal changeScandoubler : std_logic;
 signal changeScanlines : std_logic;
 signal reset_n : std_logic;
 signal scanlines : std_logic_vector(1 downto 0) := "00";
 
 
 
-- signal keys_HUA      : std_logic_vector(2 downto 0);

-- signal start : std_logic := '0';
-- signal usb_report : usb_report_t;
-- signal new_usb_report : std_logic := '0';
 
signal cpu_addr_s : std_logic_vector(14 downto 0);
signal rom_data_s : std_logic_vector(7 downto 0);
signal clock_6n_s : std_logic;

signal sram_addr_s : std_logic_vector(18 downto 0);
signal sram_data_s : std_logic_vector(7 downto 0);
signal sram_we_n_s : std_logic := '1';

		-- Video
	signal video_r_s				: std_logic_vector(4 downto 0)	:= (others => '0');
	signal video_g_s				: std_logic_vector(4 downto 0)	:= (others => '0');
	signal video_b_s				: std_logic_vector(4 downto 0)	:= (others => '0');
	signal video_hsync_n_s		: std_logic								:= '1';
	signal video_vsync_n_s		: std_logic								:= '1';
	signal vga_hsync_n_s		: std_logic								:= '1';
	signal vga_vsync_n_s		: std_logic								:= '1';
	
	
	 -- OSD
	 signal pump_active_s 	 : std_logic := '0';
	 signal osd_s  		 : std_logic_vector(7 downto 0) := "00111111";
	 signal clock_div_q	: unsigned(7 downto 0) 				:= (others => '0');
	 signal keys_s			: std_logic_vector( 7 downto 0) := (others => '1');	
	 signal power_on_reset     : std_logic := '0';

	
	-- HDMI
	signal clk_vga : std_logic;
	signal clk_dvi : std_logic;
	signal clk_dvi_180 : std_logic;
	
	signal video15_r_s				: std_logic_vector(2 downto 0)	:= (others => '0');
	signal video15_g_s				: std_logic_vector(2 downto 0)	:= (others => '0');
	signal video15_b_s				: std_logic_vector(2 downto 0)	:= (others => '0');
	signal video15_hs_s				: std_logic;
	signal video15_vs_s				: std_logic;
	signal video15_clk_s				: std_logic;
	
	signal genlock_r_s				: std_logic_vector(4 downto 0)	:= (others => '0');
	signal genlock_g_s				: std_logic_vector(4 downto 0)	:= (others => '0');
	signal genlock_b_s				: std_logic_vector(4 downto 0)	:= (others => '0');
	signal genlock_hs_s				: std_logic;
	signal genlock_vs_s				: std_logic;
	signal genlock_blank_s			: std_logic;
		
	signal pcm_audio_s				: std_logic_vector(4 downto 0);
	
	signal tdms_r_s					: std_logic_vector( 9 downto 0);
	signal tdms_g_s					: std_logic_vector( 9 downto 0);
	signal tdms_b_s					: std_logic_vector( 9 downto 0);
	signal hdmi_p_s					: std_logic_vector( 3 downto 0);
	signal hdmi_n_s					: std_logic_vector( 3 downto 0);

begin

reset <= power_on_reset or pump_active_s;



-- Clock 12.288MHz for time_pilot core, 14.318MHz for sound_board
clocks : entity work.pll1 
port map(
 inclk0 => clock_50_i,
 c0 => clock_12,
 c1 => clock_14,
 c2 =>  clk_vga,
 c3 =>  clk_dvi,
 c4 =>  clk_dvi_180,
 locked => open --pll_locked
);

-- Time pilot
time_pilot : entity work.time_pilot
port map(
 clock_12   => clock_12,
 clock_14   => clock_14,
 reset      => reset,
 
 tv15Khz_mode => scandoublerD, --'1', -- delgrom
 
 video_r      => r,
 video_g      => g,
 video_b      => b,
 video_csync  => csync,
 video_blankn => blankn,
 video_hs     => vga_hsync_n_s, 
 video_vs     => vga_vsync_n_s, 
 audio_out    => audio,
 
 video15_r     => video15_r_s,
 video15_g     => video15_g_s,
 video15_b     => video15_b_s,
 video15_hs    => video15_hs_s,
 video15_vs    => video15_vs_s,
 video15_clk   => video15_clk_s,
 
 dip_switch_1 => X"FF", -- Coinage_B / Coinage_A
 dip_switch_2 => X"4B", -- Sound(8)/Difficulty(7-5)/Bonus(4)/Cocktail(3)/lives(2-1)
 
 -- delgrom Asignación directa a joystick
 start2      => joyPCFRLDU(6),
 start1      => joyPCFRLDU(5),
 coin1       => joyPCFRLDU(7),
 
 fire1       => not (joy1_p6_i and joy1_p9_i) or joyPCFRLDU(4),
 right1      => not joy1_right_i or joyPCFRLDU(3),
 left1       => not joy1_left_i or joyPCFRLDU(2),
 down1       => not joy1_down_i or joyPCFRLDU(1),
 up1         => not joy1_up_i or joyPCFRLDU(0),

 fire2       => not (joy1_p6_i and joy1_p9_i) or joyPCFRLDU(4),
 right2      => not joy1_right_i or joyPCFRLDU(3),
 left2       => not joy1_left_i or joyPCFRLDU(2),
 down2       => not joy1_down_i or joyPCFRLDU(1),
 up2         => not joy1_up_i or joyPCFRLDU(0),
 -- ----------------------

 dbg_cpu_addr => open,
 
  
 clock_6n_o => clock_6n_s,
 rom_addr_o => cpu_addr_s,
 rom_data_i => rom_data_s,
 scanlines  => scanlines

);

-- delgrom 15khz o VGA
process (vga_hsync_n_s)
begin
  
  if (scandoublerD = '1') then
		
		vga_r_o <= r & r(1 downto 0);
		vga_g_o <= g & g(1 downto 0);
		vga_b_o <= b & b(1 downto 0);
		vga_hsync_n_o	<= csync;
		vga_vsync_n_o	<= '1';
  else
		vga_r_o <= r & r(1 downto 0);
		vga_g_o <= g & g(1 downto 0);
		vga_b_o <= b & b(1 downto 0);
		vga_hsync_n_o	<= vga_hsync_n_s;
		vga_vsync_n_o	<= vga_vsync_n_s;
  end if;
end process;


OSB_BLOCK: block 

	type config_array is array(natural range 15 downto 0) of std_logic_vector(7 downto 0);

		component osd is
		generic
		(
			STRLEN 		 : integer := 0;
			OSD_X_OFFSET : std_logic_vector(9 downto 0) := (others=>'0');
			OSD_Y_OFFSET : std_logic_vector(9 downto 0) := (others=>'0');
			OSD_COLOR    : std_logic_vector(2 downto 0) := (others=>'0')
		);
		port
		(
			-- OSDs pixel clock, should be synchronous to cores pixel clock to
			-- avoid jitter.
			pclk		: in std_logic;

			-- SPI interface
			sck		: in std_logic;
			ss			: in std_logic;
			sdi		: in std_logic;
			sdo		: out std_logic;

			-- VGA signals coming from core
			red_in 	: in std_logic_vector(4 downto 0);
			green_in : in std_logic_vector(4 downto 0);
			blue_in 	: in std_logic_vector(4 downto 0);
			hs_in		: in std_logic;
			vs_in		: in std_logic;
			
			-- VGA signals going to video connector
			red_out	: out std_logic_vector(4 downto 0);
			green_out: out std_logic_vector(4 downto 0);
			blue_out	: out std_logic_vector(4 downto 0);
			hs_out 	: out std_logic;
			vs_out 	: out std_logic;
			
			-- external data in to the microcontroller
			data_in 	: in std_logic_vector(7 downto 0);
			conf_str : in std_logic_vector( (STRLEN * 8)-1 downto 0);
			
			-- data pump to sram
			pump_active_o	: out std_logic := '0';
			sram_a_o 		: out std_logic_vector(18 downto 0);
			sram_d_o 		: out std_logic_vector(7 downto 0);
			sram_we_n_o 	: out std_logic := '1';
			
			config_buffer_o: out config_array
		);
		end component;
		
		alias SPI_DI  : std_logic is stm_b15_io;
		alias SPI_DO  : std_logic is stm_b14_io;
		alias SPI_SCK : std_logic is stm_b13_io;
		alias SPI_SS3 : std_logic is stm_b12_io;
		
		signal vga_r_out_s : std_logic_vector(3 downto 0);
		signal vga_g_out_s : std_logic_vector(3 downto 0);
		signal vga_b_out_s : std_logic_vector(3 downto 0);
		
		signal sram_addr_s : std_logic_vector(18 downto 0) := (others=>'1');
		signal sram_data_s : std_logic_vector(7 downto 0);
		signal sram_we_s 	 : std_logic := '1';
		
		signal power_on_s		: std_logic_vector(15 downto 0)	:= (others => '1');
		
		signal config_buffer_s : config_array;

		-- config string
		constant STRLEN		: integer := 14;
		constant CONF_STR		: std_logic_vector((STRLEN * 8)-1 downto 0) := to_slv("P,timepilo.dat");

		
	begin
		
		
		osd1 : osd 
		generic map
		(
			STRLEN => STRLEN,
			OSD_COLOR => "001", -- RGB
			OSD_X_OFFSET => "0000010010", -- 50
			OSD_Y_OFFSET => "0000001111"  -- 15
		)
		port map
		(
			pclk       => clock_12,

			-- spi for OSD
			sdi        => SPI_DI,
			sck        => SPI_SCK,
			ss         => SPI_SS3,
			sdo        => SPI_DO,
			
			red_in     => (others=>'1'),
			green_in   => (others=>'1'),
			blue_in    => (others=>'1'),
			hs_in      => '1',
			vs_in      => '1',

			red_out    => open,
			green_out  => open,
			blue_out   => open,
			hs_out     => open,
			vs_out     => open,

			data_in		=> osd_s,
			conf_str		=> CONF_STR,
						
			pump_active_o	=> pump_active_s,
			sram_a_o			=> sram_addr_s,
			sram_d_o			=> sram_data_s,
			sram_we_n_o		=> sram_we_n_s,
			config_buffer_o=> config_buffer_s		
		);
			
		
		sram_addr_o   <= sram_addr_s when pump_active_s = '1' else "0000" & cpu_addr_s;
		sram_data_io  <= sram_data_s when pump_active_s = '1' else (others=>'Z');
		rom_data_s 	   <= sram_data_io;
		sram_oe_n_o   <= '0';
		sram_we_n_o   <= sram_we_n_s;


		--start the microcontroller OSD menu after the power on
		process (clock_12, reset_n, osd_s)
		begin
			if rising_edge(clock_12) then
				--if reset_n = '0' then
				if not reset_n = '0' then --delgrom
					power_on_s <= (others=>'1');
				elsif power_on_s /= x"0000" then
					power_on_s <= power_on_s - 1;
					power_on_reset <= '1';
					osd_s <= "00111111";
				else
					power_on_reset <= '0';
					
				end if;
				
				if pump_active_s = '1' and osd_s <= "00111111" then
					osd_s <= "11111111";
				end if;
				
			end if;
		end process;

	end block;	



-- get scancode from keyboard
process (reset, clock_12)
begin
	if reset='1' then
		clock_6  <= '0';
	else 
		if rising_edge(clock_12) then
				clock_6  <= not clock_6;
		end if;
	end if;
end process;

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_6, -- synchrounous clock with core
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);

-- translate scancode to joystick
joystick : entity work.kbd_joystick
port map 
(
  clk           => clock_6, -- synchrounous clock with core
  kbdint        => kbd_intr,
  kbdscancode   => std_logic_vector(kbd_scancode), 
  joyPCFRLDU 	 => joyPCFRLDU,
  osd_o			 => keys_s,
  -- delgrom teclas unamiga
  changeScandoubler => changeScandoubler,
  changeScanlines   => changeScanlines,
  press_reset    => reset_n
);


-- pwm sound output
process(clock_14)  -- use same clock as time_pilot_sound_board
begin
  if rising_edge(clock_14) then
    pwm_accumulator  <=  std_logic_vector(unsigned('0' & pwm_accumulator(11 downto 0)) + unsigned(audio & "00"));
  end if;
end process;

dac_l_o <= pwm_accumulator(12);
dac_r_o <= pwm_accumulator(12); 


-- delgrom Pulsaciones de teclas unamiga		
process (changeScandoubler)
begin
	if rising_edge(changeScandoubler) then
			scandoublerD  <= not scandoublerD;
	end if;
end process;	

process (changeScanlines)
begin
	if rising_edge(changeScanlines) then
			scanlines  <= scanlines + '1';
	end if;
end process;	


end struct;
