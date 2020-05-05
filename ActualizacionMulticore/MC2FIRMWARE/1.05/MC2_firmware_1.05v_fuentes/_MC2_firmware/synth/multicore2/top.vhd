

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.ALL;

entity top is
	port (
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
		SDRAM_A				: out std_logic_vector(12 downto 0);
		SDRAM_DQ				: inout std_logic_vector(15 downto 0);

		SDRAM_BA				: out std_logic_vector(1 downto 0);
		SDRAM_DQMH			: out std_logic;
		SDRAM_DQML			: out std_logic;	

		SDRAM_nRAS			: out std_logic;
		SDRAM_nCAS			: out std_logic;
		SDRAM_CKE			: out std_logic;
		SDRAM_CLK			: out std_logic;
		SDRAM_nCS			: out std_logic;
		SDRAM_nWE			: out std_logic;
	
		-- PS2
		ps2_clk_io			: inout std_logic								:= 'Z';
		ps2_data_io			: inout std_logic								:= 'Z';
		ps2_mouse_clk_io  : inout std_logic								:= 'Z';
		ps2_mouse_data_io : inout std_logic								:= 'Z';

		-- SD Card
		sd_cs_n_o			: out   std_logic								:= 'Z';
		sd_sclk_o			: out   std_logic								:= 'Z';
		sd_mosi_o			: out   std_logic								:= 'Z';
		sd_miso_i			: in    std_logic;

		-- Joysticks
		joy1_up_i			: inout    std_logic;
		joy1_down_i			: inout    std_logic;
		joy1_left_i			: in    std_logic;
		joy1_right_i		: in    std_logic;
		joy1_p6_i			: in    std_logic;
		joy1_p9_i			: in    std_logic;
		joy2_up_i			: inout    std_logic;
		joy2_down_i			: inout    std_logic;
		joy2_left_i			: in    std_logic;
		joy2_right_i		: in    std_logic;
		joy2_p6_i			: in    std_logic;
		joy2_p9_i			: in    std_logic;
		joyX_p7_o			: out   std_logic								:= '1';

		-- Audio
		AUDIO_L				: out   std_logic								:= '0';
		AUDIO_R				: out   std_logic								:= '0';
		ear_i					: in    std_logic;
		mic_o					: out   std_logic								:= '0';

		-- VGA
		VGA_R					: out   std_logic_vector(4 downto 0)	:= (others => '0');
		VGA_G					: out   std_logic_vector(4 downto 0)	:= (others => '0');
		VGA_B					: out   std_logic_vector(4 downto 0)	:= (others => '0');
		VGA_HS				: out   std_logic								:= '1';
		VGA_VS				: out   std_logic								:= '1';

		-- HDMI
		--tmds_o				: out   std_logic_vector(7 downto 0)	:= (others => '0');

		--STM32
		stm_rx_o				: out std_logic		:= 'Z'; -- stm RX pin, so, is OUT on the slave
		stm_tx_i				: in  std_logic		:= 'Z'; -- stm TX pin, so, is IN on the slave
		stm_rst_o			: out std_logic		:= 'Z'; -- '0' to hold the microcontroller reset line, to free the SD card
		
		--stm_a15_io			: inout std_logic;
		--stm_b8_io			: inout std_logic		:= 'Z';
		--stm_b9_io			: inout std_logic		:= 'Z';
		
		SPI_SCK				: inout std_logic		:= 'Z';
		SPI_DO				: inout std_logic		:= 'Z';
		SPI_DI				: inout std_logic		:= 'Z';
		SPI_SS2				: inout std_logic		:= 'Z'
	);
end entity;

architecture Behavior of top is

	type config_array is array(natural range 15 downto 0) of std_logic_vector(7 downto 0);

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

	component vga is
	port
	(
		-- pixel clock
		pclk			: in std_logic;

		-- enable/disable scanlines
		scanlines	: in std_logic;
		
		-- output to VGA screen
		hs	: out std_logic;
		vs	: out std_logic;
		r	: out std_logic_vector(3 downto 0);
		g	: out std_logic_vector(3 downto 0);
		b	: out std_logic_vector(3 downto 0);
		blank : out std_logic
		
		--debug
		--joy_i	: in std_logic_vector(11 downto 0)
	);
	end component;
	
	component osd is
	generic
	(
		OSD_VISIBLE 	: std_logic_vector(1 downto 0) := (others=>'0');
		OSD_X_OFFSET 	: std_logic_vector(9 downto 0) := (others=>'0');
		OSD_Y_OFFSET 	: std_logic_vector(9 downto 0) := (others=>'0');
		OSD_COLOR    	: std_logic_vector(2 downto 0) := (others=>'0')
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
		
		-- Data in
		data_in 	: in std_logic_vector(7 downto 0);
		
		--data pump to sram
		pump_active_o	: out std_logic;
		sram_a_o			: out std_logic_vector(18 downto 0);
		sram_d_o			: out std_logic_vector(7 downto 0);
		sram_we_n_o		: out std_logic;
		config_buffer_o: out config_array
	
	);
	end component;
	
	component top_test_mc2 is
	port
	(
		clk100				: in  std_logic;
		clk100n				: in  std_logic;
		clk25					: in  std_logic;
		pll_locked			: in  std_logic;
		
		sram_addr_o  		: out std_logic_vector(18 downto 0);
		sram_data_io		: inout std_logic_vector(7 downto 0);
		sram_we_n_o			: out std_logic;
		sram_oe_n_o			: out std_logic;
			
		SDRAM_A				: out std_logic_vector(12 downto 0);
		SDRAM_BA				: out std_logic_vector(1 downto 0);
		SDRAM_DQ 			: inout std_logic_vector(15 downto 0);
		SDRAM_DQMH			: out std_logic;
		SDRAM_DQML			: out std_logic;
		SDRAM_CKE			: out std_logic;
		SDRAM_nCS			: out std_logic;
		SDRAM_nWE			: out std_logic;
		SDRAM_nRAS			: out std_logic;
		SDRAM_nCAS			: out std_logic;
		SDRAM_CLK			: out std_logic;

		ps2_clk_io			: inout std_logic;
		ps2_data_io			: inout std_logic;
		ps2_mouse_clk_io  : inout std_logic;
		ps2_mouse_data_io : inout std_logic;

		sd_cs_n_o			: out std_logic;
		sd_sclk_o			: out std_logic;
		sd_mosi_o			: out std_logic;
		sd_miso_i			: in  std_logic;

		joy1_up_i			: inout std_logic;
		joy1_down_i			: inout std_logic;
		joy1_left_i			: in  std_logic;
		joy1_right_i		: in  std_logic;
		joy1_p6_i			: in  std_logic;
		joy1_p9_i			: in  std_logic;
		joy2_up_i			: inout std_logic;
		joy2_down_i			: inout std_logic;
		joy2_left_i			: in  std_logic;
		joy2_right_i		: in  std_logic;
		joy2_p6_i			: in  std_logic;
		joy2_p9_i			: in  std_logic;
		joyX_p7_o			: out std_logic;

		AUDIO_L				: out std_logic;
		AUDIO_R 				: out std_logic;

		VGA_R 				: out std_logic_vector(4 downto 0);
		VGA_G 				: out std_logic_vector(4 downto 0);
		VGA_B 				: out std_logic_vector(4 downto 0);
		VGA_HS 				: out std_logic;
		VGA_VS				: out std_logic;
		VGA_BLANK			: out std_logic;
		
		stm_rst_o 			: out std_logic
	);
	end component;

	-- clocks
	signal clk100				: std_logic;		
	signal clk100n				: std_logic;	
	signal pll_locked			: std_logic;	
	signal pixel_clock		: std_logic;		
	signal clk_dvi				: std_logic;		
	signal pMemClk				: std_logic;		
	signal clock_div_q		: unsigned(7 downto 0) 				:= (others => '0');	
	
	-- Reset 
	signal reset_s				: std_logic;		-- Reset geral	
	signal power_on_s			: std_logic_vector(7 downto 0)	:= (others => '1');
	signal btn_reset_s		: std_logic;
	
	-- Video
	signal video_r_s				: std_logic_vector(3 downto 0)	:= (others => '0');
	signal video_g_s				: std_logic_vector(3 downto 0)	:= (others => '0');
	signal video_b_s				: std_logic_vector(3 downto 0)	:= (others => '0');
	signal video_hsync_n_s		: std_logic								:= '1';
	signal video_vsync_n_s		: std_logic								:= '1';
	
	signal osd_r_s				: std_logic_vector(3 downto 0)	:= (others => '0');
	signal osd_g_s				: std_logic_vector(3 downto 0)	:= (others => '0');
	signal osd_b_s				: std_logic_vector(3 downto 0)	:= (others => '0');

	signal info_r_s				: std_logic_vector(3 downto 0)	:= (others => '0');
	signal info_g_s				: std_logic_vector(3 downto 0)	:= (others => '0');
	signal info_b_s				: std_logic_vector(3 downto 0)	:= (others => '0');
	
	-- VGA
	signal vga_r_s				: std_logic_vector( 3 downto 0);
	signal vga_g_s				: std_logic_vector( 3 downto 0);
	signal vga_b_s				: std_logic_vector( 3 downto 0);
	signal vga_hsync_n_s 		: std_logic;
	signal vga_vsync_n_s 		: std_logic;
	signal vga_blank_s 			: std_logic;

	-- HDMI
	signal tdms_r_s			: std_logic_vector( 9 downto 0);
	signal tdms_g_s			: std_logic_vector( 9 downto 0);
	signal tdms_b_s			: std_logic_vector( 9 downto 0);
	signal hdmi_p_s			: std_logic_vector( 3 downto 0);
	signal hdmi_n_s			: std_logic_vector( 3 downto 0);
	
	-- Keyboard
	signal keys_s			: std_logic_vector( 7 downto 0) := (others => '1');	
	signal FKeys_s			: std_logic_vector(12 downto 1);
	
	-- joystick
	signal joy1_s			: std_logic_vector(15 downto 0) := (others => '1'); 
	signal joy2_s			: std_logic_vector(15 downto 0) := (others => '1'); 
	signal joyP7_s			: std_logic;
	
	-- config string
	constant STRLEN		: integer := 1;
--	constant CONF_STR		: std_logic_vector((STRLEN * 8)-1 downto 0) := to_slv("P,config.ini");
	constant CONF_STR		: std_logic_vector(7 downto 0) := X"00";
	
	signal config_buffer_s : config_array;
	
	-- keyboard
	signal kbd_intr      : std_logic;
	signal kbd_scancode  : std_logic_vector(7 downto 0);
	
	
	signal HDMI_R  : std_logic_vector(7 downto 0);
	signal HDMI_G  : std_logic_vector(7 downto 0);
	signal HDMI_B  : std_logic_vector(7 downto 0);
	signal HDMI_HS : std_logic;
	signal HDMI_VS : std_logic;
	signal HDMI_BL : std_logic;
				
	----------------------------------
	
	-- auto test

	signal auto_test_disabled : std_logic := '1';
	signal btn_mode_s : std_logic;
	
	signal test_vga_r_s 	: std_logic_vector(4 downto 0);
	signal test_vga_g_s 	: std_logic_vector(4 downto 0);
	signal test_vga_b_s  : std_logic_vector(4 downto 0);
	signal test_vga_hs_s : std_logic;
	signal test_vga_vs_s : std_logic;
	signal test_vga_blank_s : std_logic;

	signal test_audiol_s : std_logic;
	signal test_audior_s : std_logic;
		
	signal test_joyp7_s : std_logic;
	signal menu_joyp7_s : std_logic;

	-- Teclas unamiga
	signal changeScandoubler : std_logic;
	signal esc_reset : std_logic;
	signal f2_test : std_logic;		
		
begin	

	btnscl: entity work.debounce
	generic map (
		counter_size	=> 16
	)
	port map (
		clk_i				=> pixel_clock,
		--button_i			=> btn_n_i(1) and btn_n_i(2) and btn_n_i(3),
		button_i			=> not esc_reset, 
		result_o			=> btn_reset_s
	);
		
	process (pixel_clock)
	begin
	
		if rising_edge(pixel_clock) then
		
			if btn_reset_s = '0' then
				power_on_s <= (others=>'1');
			end if;
			
			if power_on_s /= x"00" then
				reset_s <= '1';
				stm_rst_o <= '0';
				power_on_s <= power_on_s - 1;
			else
				reset_s <= '0';
				stm_rst_o <= 'Z';
			end if;
			
		end if;
	end process;
  
	U00 : work.pll
	  port map(
		inclk0   => clock_50_i,              
		c0       => pixel_clock,             -- 25.200Mhz
		c1       => clk_dvi,                 -- 126 MHz
		c2 		=> clk100,
		c3 		=> clk100n,
		locked 	=> pll_locked
	  );

	--generate a black screen with proper sync VGA timing
	vga1 : vga 
	port map
	(
		pclk     => pixel_clock,

		scanlines => '0',
		
		hs    	=> video_hsync_n_s,
		vs    	=> video_vsync_n_s,
		r     	=> video_r_s,
		g     	=> video_g_s,
		b     	=> video_b_s,
		blank 	=> vga_blank_s
		
	);
	  

	osd1 : osd 
	generic map
	(	
		--STRLEN => STRLEN,
		OSD_VISIBLE => "01",
		OSD_COLOR => "001", -- RGB
		OSD_X_OFFSET => "0000010010", -- 50
		OSD_Y_OFFSET => "0000001111"  -- 15
	)
	port map
	(
		pclk        => pixel_clock,

		-- spi for OSD
		sdi        => SPI_DI,
		sck        => SPI_SCK,
		ss         => SPI_SS2,
		sdo        => SPI_DO,
		
		red_in     => video_r_s & '0',
		green_in   => video_g_s & '0',
		blue_in    => video_b_s & '0',
		hs_in      => video_hsync_n_s,
		vs_in      => video_vsync_n_s,

		red_out(4 downto 1)    => osd_r_s,
		green_out(4 downto 1)  => osd_g_s,
		blue_out(4 downto 1)   => osd_b_s,
		hs_out     => vga_hsync_n_s,
		vs_out     => vga_vsync_n_s ,

		data_in		=> keys_s,
	--	conf_str		=> CONF_STR,
		
		config_buffer_o=> config_buffer_s
	);
   
	info1 : work.core_info 
	generic map
	(
		xOffset => 380,
		yOffset => 408
	)
	port map
	(
		clk_i 	=> pixel_clock,
		
		r_i 		=> osd_r_s,
		g_i 		=> osd_g_s,
		b_i 		=> osd_b_s,
		hSync_i 	=> vga_hsync_n_s,
		vSync_i 	=> vga_vsync_n_s ,

		r_o 		=> info_r_s,
		g_o 		=> info_g_s,
		b_o 		=> info_b_s,
		
		core_char1_s => "000001",  -- V 1.05 for the core
		core_char2_s => "000000",
		core_char3_s => "000101",

		stm_char1_s => unsigned(config_buffer_s(0)(5 downto 0)), 	
		stm_char2_s => unsigned(config_buffer_s(1)(5 downto 0)),
		stm_char3_s => unsigned(config_buffer_s(2)(5 downto 0))
	);
	
	info2 : work.core_copyright
	generic map
	(
		xOffset => 320,
		yOffset => 420
	)
	port map
	(
		clk_i 	=> pixel_clock,
		
		r_i 		=> info_r_s,
		g_i 		=> info_g_s,
		b_i 		=> info_b_s,
		hSync_i 	=> vga_hsync_n_s,
		vSync_i 	=> vga_vsync_n_s ,

		r_o 		=> vga_r_s,
		g_o 		=> vga_g_s,
		b_o 		=> vga_b_s
	);
			  

	
--	kb: entity work.ps2keyb
--	port map (
--		enable_i			=> '1',
--		clock_i			=> pixel_clock,
--		clock_ps2_i		=> clock_div_q(1),
--		reset_i			=> reset_s,
--		--
--		ps2_clk_io		=> ps2_clk_io,
--		ps2_data_io		=> ps2_data_io,
--		--
--		keys_o			=> keys_s,
--		functionkeys_o	=> FKeys_s
--
--	);
--	
--	-- Keyboard clock
--	process(pixel_clock)
--	begin
--		if rising_edge(pixel_clock) then 
--			clock_div_q <= clock_div_q + 1;
--		end if;
--	end process;
	
	-- get scancode from keyboard
	keyboard : entity work.io_ps2_keyboard
	port map (
	  clk       => pixel_clock,
	  kbd_clk   => ps2_clk_io,
	  kbd_dat   => ps2_data_io,
	  interrupt => kbd_intr,
	  scancode  => kbd_scancode
	);

	-- translate scancode to joystick
--	joystick : entity work.kbd_joystick
--	generic map 
--	(
--		osd_cmd		=> "111"
--	)
--	port map 
--	(
--		clk         => pixel_clock,
--		kbdint      => kbd_intr,
--		kbdscancode => std_logic_vector(kbd_scancode), 
--		osd_o			=> keys_s,
--		   
--		joystick_0 	=> joy1_p6_i & joy1_p9_i & joy1_up_i & joy1_down_i & joy1_left_i & joy1_right_i,
--		joystick_1	=> joy2_p6_i & joy2_p9_i & joy2_up_i & joy2_down_i & joy2_left_i & joy2_right_i,
--
--		-- joystick_0 and joystick_1 should be swapped
--		joyswap 		=> '0',
--
--		-- player1 and player2 should get both joystick_0 and joystick_1
--		oneplayer	=> '1',
--
--		-- tilt, coin4-1, start4-1
--		controls   => open,
--
--		-- fire12-1, up, down, left, right
--
--		player1    => joy1_s,
--		player2    => joy2_s,
--
--		-- sega joystick
--		sega_clk  	=>  vga_hsync_n_s,
--		sega_strobe	=> menu_joyp7_s
--	);


	joystick : entity work.kbd_joystick
	generic map 
	(
		osd_cmd		=> "111"
	)
	port map 
	(
		clk         => pixel_clock,
		kbdint      => kbd_intr,
		kbdscancode => std_logic_vector(kbd_scancode), 
		osd_o			=> keys_s,
		   
		joystick_0 	=> joy1_p6_i & joy1_p9_i & joy1_up_i & joy1_down_i & joy1_left_i & joy1_right_i,
		joystick_1	=> joy2_p6_i & joy2_p9_i & joy2_up_i & joy2_down_i & joy2_left_i & joy2_right_i,

		-- joystick_0 and joystick_1 should be swapped
		joyswap 		=> '0',

		-- player1 and player2 should get both joystick_0 and joystick_1
		oneplayer	=> '1',

		-- tilt, coin4-1, start4-1
		controls   => open,

		-- fire12-1, up, down, left, right

		player1    => joy1_s,
		player2    => joy2_s,

		-- sega joystick
		sega_clk  	=>  vga_hsync_n_s,
		sega_strobe	=> menu_joyp7_s, 
		changeScandoubler	=> changeScandoubler, 
		esc_reset	=> esc_reset, 
		f2_test	=> f2_test 

	);	
	
	
	
	---------
	
	-- HDMI
 		inst_dvid: entity work.hdmi
 		generic map (
 			FREQ	=> 25200000,	-- pixel clock frequency 
 			FS		=> 48000,		-- audio sample rate - should be 32000, 41000 or 48000 = 48KHz
 			CTS	=> 25200,		-- CTS = Freq(pixclk) * N / (128 * Fs)
 			N		=> 6144			-- N = 128 * Fs /1000,  128 * Fs /1500 <= N <= 128 * Fs /300 (Check HDMI spec 7.2 for details)
 		) 
 		port map (
 			I_CLK_PIXEL		=> pixel_clock,
			
			I_R				=> HDMI_R,
			I_G				=> HDMI_G,
			I_B				=> HDMI_B,
			I_BLANK			=> HDMI_BL,
			I_HSYNC			=> HDMI_HS,
			I_VSYNC			=> HDMI_VS,
			
			-- PCM audio
			I_AUDIO_ENABLE	=> '1',
			I_AUDIO_PCM_L 	=> (others=>'0'),
			I_AUDIO_PCM_R	=> (others=>'0'),
			-- TMDS parallel pixel synchronous outputs (serialize LSB first)
 			O_RED				=> tdms_r_s,
			O_GREEN			=> tdms_g_s,
			O_BLUE			=> tdms_b_s
		);
		

			hdmio: entity work.hdmi_out_altera
		port map (
			clock_pixel_i		=> pixel_clock,
			clock_tdms_i		=> clk_dvi,
			red_i					=> tdms_r_s,
			green_i				=> tdms_g_s,
			blue_i				=> tdms_b_s,
			tmds_out_p			=> hdmi_p_s,
			tmds_out_n			=> hdmi_n_s
		);
 		
		
		-- tmds_o(7)	<= hdmi_p_s(2);	-- 2+		
		-- tmds_o(6)	<= hdmi_n_s(2);	-- 2-		
		-- tmds_o(5)	<= hdmi_p_s(1);	-- 1+			
		-- tmds_o(4)	<= hdmi_n_s(1);	-- 1-		
		-- tmds_o(3)	<= hdmi_p_s(0);	-- 0+		
		-- tmds_o(2)	<= hdmi_n_s(0);	-- 0-	
		-- tmds_o(1)	<= hdmi_p_s(3);	-- CLK+	
		-- tmds_o(0)	<= hdmi_n_s(3);	-- CLK-	
		
		
	btnmode: entity work.debounce
	generic map (
		counter_size	=> 16
	)
	port map (
		clk_i				=> pixel_clock,
		--button_i			=> not btn_n_i(4),
		button_i			=> f2_test, --not btn_n_i(4),
		result_o			=> btn_mode_s
	);
	
	process (btn_mode_s)
	begin
		if rising_edge(btn_mode_s) then
			auto_test_disabled <= not auto_test_disabled;
		end if;
	
	end process;
		
		process(pixel_clock)
		begin
			if auto_test_disabled = '1' then
				VGA_R		<= vga_r_s & '0';
				VGA_G		<= vga_g_s & '0';
				VGA_B		<= vga_b_s & '0';
				VGA_HS	<= vga_hsync_n_s;
				VGA_VS	<= vga_vsync_n_s;
				
				HDMI_R  <= vga_r_s & vga_r_s;
				HDMI_G  <= vga_g_s & vga_g_s;
				HDMI_B  <= vga_b_s & vga_b_s;
				HDMI_HS <= vga_hsync_n_s;
				HDMI_VS <= vga_vsync_n_s;
				HDMI_BL <= vga_blank_s;
				
				AUDIO_L <= '0';
				AUDIO_R <= '0';
				stm_rst_o <= 'Z';
				joyX_p7_o <= menu_joyp7_s;
			else
				VGA_R		<= test_vga_r_s;
				VGA_G		<= test_vga_g_s;
				VGA_B		<= test_vga_b_s;
				VGA_HS	<= test_vga_hs_s;
				VGA_VS	<= test_vga_vs_s;
				
				HDMI_R  <= test_vga_r_s & test_vga_r_s(4 downto 2);
				HDMI_G  <= test_vga_g_s & test_vga_g_s(4 downto 2);
				HDMI_B  <= test_vga_b_s & test_vga_b_s(4 downto 2);
				HDMI_HS <= test_vga_hs_s;
				HDMI_VS <= test_vga_vs_s;
				HDMI_BL <= test_vga_blank_s;
			
				AUDIO_L	<= test_audiol_s;
				AUDIO_R 	<= test_audior_s;
				stm_rst_o <= '0';
				joyX_p7_o <= test_joyp7_s;
			end if;
		
		end process;
		
-----------------------------------------------------		
------------- AUTO TEST -----------------------------

	autotest : top_test_mc2 
	port map
	(
		clk100				=> clk100,
		clk100n				=> clk100n,
		clk25					=> pixel_clock, 
		pll_locked			=> pll_locked,

		sram_addr_o  		=> sram_addr_o,
		sram_data_io		=> sram_data_io,
		sram_we_n_o			=> sram_we_n_o,
		sram_oe_n_o			=> sram_oe_n_o,	
			                  	
		SDRAM_A				=> SDRAM_A,		
		SDRAM_BA				=> SDRAM_BA,		
		SDRAM_DQ 			=> SDRAM_DQ,	
		SDRAM_DQMH			=> SDRAM_DQMH,	
		SDRAM_DQML			=> SDRAM_DQML,	
		SDRAM_CKE			=> SDRAM_CKE,	
		SDRAM_nCS			=> SDRAM_nCS,	
		SDRAM_nWE			=> SDRAM_nWE,	
		SDRAM_nRAS			=> SDRAM_nRAS,	
		SDRAM_nCAS			=> SDRAM_nCAS,	
		SDRAM_CLK			=> SDRAM_CLK,	

		ps2_clk_io			=> ps2_clk_io,
		ps2_data_io			=> ps2_data_io,
		ps2_mouse_clk_io  => ps2_mouse_clk_io,
		ps2_mouse_data_io => ps2_mouse_data_io,

		sd_cs_n_o			=> sd_cs_n_o,
		sd_sclk_o			=> sd_sclk_o,
		sd_mosi_o			=> sd_mosi_o,
		sd_miso_i			=> sd_miso_i,

		joy1_up_i			=> joy1_up_i,
		joy1_down_i			=> joy1_down_i,
		joy1_left_i			=> joy1_left_i,
		joy1_right_i		=> joy1_right_i,
		joy1_p6_i			=> joy1_p6_i,
		joy1_p9_i			=> joy1_p9_i,
		joy2_up_i			=> joy2_up_i,
		joy2_down_i			=> joy2_down_i,
		joy2_left_i			=> joy2_left_i,
		joy2_right_i		=> joy2_right_i,
		joy2_p6_i			=> joy2_p6_i,
		joy2_p9_i			=> joy2_p9_i,
		joyX_p7_o			=> test_joyp7_s,

		AUDIO_L				=> test_audiol_s,
		AUDIO_R 				=> test_audior_s,

		VGA_R 				=> test_vga_r_s,
		VGA_G 				=> test_vga_g_s,
		VGA_B 				=> test_vga_b_s,
		VGA_HS 				=> test_vga_hs_s,
		VGA_VS				=> test_vga_vs_s,
		VGA_BLANK			=> test_vga_blank_s,
		stm_rst_o 			=> open
	);


		


end architecture;
