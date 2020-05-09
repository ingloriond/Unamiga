---------------------------------------------------------------------------------
-- Intellivision

---------------------------------------------------------------------------------
-- Developed with the help of the JZINTV emulator
---------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

--USE std.textio.ALL;

LIBRARY work;
USE work.base_pack.ALL;

ENTITY Intv_mc15 IS
  PORT (
      	-- Clocks
		clock_50_i			: in    std_logic;

		-- Buttons
		btn_n_i				: in    std_logic_vector(4 downto 1);

		-- SRAMs (AS7C34096)
		sram2_addr_o		: out   std_logic_vector(18 downto 0)	:= (others => '0');
		sram2_data_io		: inout std_logic_vector(7 downto 0)	:= (others => 'Z');
		sram2_we_n_o		: out   std_logic								:= '1';
		sram2_oe_n_o		: out   std_logic								:= '1';

		sram3_addr_o		: out   std_logic_vector(18 downto 0)	:= (others => '0');
		sram3_data_io		: inout std_logic_vector(7 downto 0)	:= (others => 'Z');
		sram3_we_n_o		: out   std_logic								:= '1';
		sram3_oe_n_o		: out   std_logic								:= '1';
		
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
		sd_cs_n_o			: out   std_logic								:= '1';
		sd_sclk_o			: out   std_logic								:= '0';
		sd_mosi_o			: out   std_logic								:= '0';
		sd_miso_i			: inout    std_logic;

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
		vga_r_o				: out   std_logic_vector(3 downto 0)	:= (others => '0');
		vga_g_o				: out   std_logic_vector(3 downto 0)	:= (others => '0');
		vga_b_o				: out   std_logic_vector(3 downto 0)	:= (others => '0');
		vga_hsync_n_o		: out   std_logic								:= '1';
		vga_vsync_n_o		: out   std_logic								:= '1';

		-- HDMI
		tmds_o				: out   std_logic_vector(7 downto 0)	:= (others => '0');

		--STM32
		stm_rx_i				: in std_logic			:= 'Z';
		stm_tx_o				: out std_logic		:= 'Z';
		stm_rst_o			: out std_logic		:= 'Z'; -- '0' to hold the microcontroller reset line, to free the SD card
		
		stm_a15_io			: inout 	std_logic;	
		stm_b8_io			: inout std_logic		:= 'Z';
		stm_b9_io			: inout std_logic		:= 'Z';
		stm_b12_io			: in std_logic			:= 'Z';
		stm_b13_io			: in std_logic			:= 'Z';
		stm_b14_io			: out std_logic		:= 'Z';
		stm_b15_io			: in std_logic			:= 'Z'

		);
END Intv_mc15;

ARCHITECTURE struct OF Intv_mc15 IS

	alias SPI_DO   is stm_b14_io;
	alias SPI_DI   is stm_b15_io;
	alias SPI_SCK  is stm_b13_io;
	alias SPI_SS3  is stm_b12_io;
	
  CONSTANT CDIV : natural := 12 * 8;
  
  COMPONENT pll IS
    PORT (
      refclk   : in  std_logic; -- clk
      rst      : in  std_logic; -- reset
      outclk_0 : out std_logic; -- clk
      outclk_1 : out std_logic; -- clk
      locked   : out std_logic  -- export
      );
  END COMPONENT pll;
  
  CONSTANT CONF_STR : string := 
    "S,INT,Load *.INT;" &
    "O47,MAP,Auto,0,1,2,3,4,5,6,7,8,9;" &
    "O8,ECS,Off,On;" &
	 "O9,Voice,On,Off;" &
--    "OA,Video standard,NTSC,PAL;" &
--  "O46,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;" &
    "O1,Swap Joystick,Off,On;" &
    "O2,Debug Info,Off,On;" &
    "V1.0";
  
  FUNCTION to_slv(s: string) return std_logic_vector is 
    CONSTANT ss : string(1 to s'length) := s; 
    VARIABLE rval : std_logic_vector(1 to 8 * s'length); 
    VARIABLE p : integer; 
    VARIABLE c : integer; 
  BEGIN
    FOR i in ss'range LOOP
      p := 8 * i;
      c := character'pos(ss(i));
      rval(p - 7 to p) := std_logic_vector(to_unsigned(c,8)); 
    END LOOP;
    RETURN rval;
  END FUNCTION; 
  
    component mist_video is
	port
	(
		clk_sys 	: in std_logic;

		scanlines  : in std_logic_vector(1 downto 0);

		ce_divider: in std_logic;
		
		scandoubler_disable: in std_logic;
		ce_x1: in std_logic;
		ce_x2: in std_logic;
				
		blend : in std_logic;

		R : in std_logic_vector(5 downto 0);
		G : in std_logic_vector(5 downto 0);
		B : in std_logic_vector(5 downto 0);

		HSync: in std_logic;
		VSync: in std_logic;

		VGA_R	: out std_logic_vector(5 downto 0);
		VGA_G	: out std_logic_vector(5 downto 0);
		VGA_B	: out std_logic_vector(5 downto 0);
		VGA_VS: out std_logic;
		VGA_HS: out std_logic;
		osd_enable : out std_logic
	);
	end component;
	

  SIGNAL joystick_0      : std_logic_vector(31 DOWNTO 0);
  SIGNAL joystick_1      : std_logic_vector(31 DOWNTO 0);
  SIGNAL joystick_analog_0 : std_logic_vector(15 DOWNTO 0);
  SIGNAL joystick_analog_1 : std_logic_vector(15 DOWNTO 0);
  SIGNAL buttons         : std_logic_vector(1 DOWNTO 0);
  SIGNAL status          : std_logic_vector(15 DOWNTO 0);
  SIGNAL status_in       : std_logic_vector(31 DOWNTO 0):=x"00000000";
  SIGNAL status_set      : std_logic :='0';
  SIGNAL status_menumask : std_logic_vector(15 DOWNTO 0):=x"0000";
  SIGNAL new_vmode       : std_logic :='0';
  
  SIGNAL ioctl_download : std_logic := '0';
  SIGNAL ioctl_download2: std_logic := '0';
  SIGNAL ioctl_index    : std_logic_vector(7 DOWNTO 0);
  SIGNAL ioctl_wr       : std_logic;
  SIGNAL ioctl_addr     : unsigned(24 DOWNTO 0);
  SIGNAL ioctl_dout     : std_logic_vector(7 DOWNTO 0);
  SIGNAL ioctl_wait     : std_logic :='0';

  SIGNAL w_wrl,w_wrh    : std_logic;
  SIGNAL w_d : uv8;
  SIGNAL w_a : uv15;
  
  SIGNAL ps2_key,ps2_key_delay,ps2_key_mem : std_logic_vector(10 DOWNTO 0);
  
  SIGNAL key_0,key_1,key_2,key_3,key_4,key_5,key_6,key_7 : std_logic;
  SIGNAL key_8,key_9,key_a,key_b,key_c,key_d,key_e,key_f : std_logic;
  SIGNAL key_g,key_h,key_i,key_j,key_k,key_l,key_m,key_n : std_logic;
  SIGNAL key_o,key_p,key_q,key_r,key_s,key_t,key_u,key_v : std_logic;
  SIGNAL key_w,key_x,key_y,key_z : std_logic;
  SIGNAL key_space,key_colon,key_period,key_comma : std_logic;
  SIGNAL key_up,key_down,key_right,key_left : std_logic;
  SIGNAL key_enter,key_esc,key_lshift,key_rshift,key_lctrl,key_rctrl : std_logic;

  SIGNAL key_backspace : std_logic;
  
  SIGNAL key_rc   ,key_wc  ,key_bp ,key_pc  : std_logic;
  SIGNAL key_minus,key_plus,key_reg,key_mem : std_logic;
  
  ----------------------------------------
  SIGNAL reset_na : std_logic;
  SIGNAL clksys,clksys_ntsc,clksys_pal,pll_locked : std_logic;
  
  SIGNAL clkdiv,clkdivsnd,clkdivivoice : uint6 :=0;
  SIGNAL tick_cpu,tick_cpup,tick_snd,tick_ivoice : std_logic;

  SIGNAL ram : arr_uv16(0 TO 2047);
  
  --SIGNAL carth : arr_uv8(0 TO 8191);--16383);--32767);
  signal cartl : arr_uv8(0 TO 16383);--32767);
  ATTRIBUTE ramstyle : string;
  --ATTRIBUTE ramstyle OF carth : SIGNAL IS "no_rw_check";
  ATTRIBUTE ramstyle OF cartl : SIGNAL IS "no_rw_check";
  SIGNAL cad : uv16;
  SIGNAL selram : std_logic;
  
  SIGNAL pal,ecs,ecs2,swap : std_logic;

  SIGNAL dr,dw,ad,cart_dr,cart_dw,rom_dr,ram_dr : uv16;
  
  SIGNAL snd_dr,snd_dw,snd2_dr,snd2_dw : uv8;
  SIGNAL snd_wr,snd2_wr,cart_wr : std_logic;
  SIGNAL ivoice_dr,ivoice_dw : uv16;
  SIGNAL ivoice_wr,ivoice : std_logic;
  SIGNAL ivoice_divi : uint9;
  SIGNAL sound,sound2 : sv8;
  SIGNAL sound_iv : sv16;
  
  SIGNAL bdic : uv3;
  SIGNAL bdrdy,busrq,busak,halt,intrm : std_logic;
  SIGNAL pa_i,pb_i,pa_o,pb_o : uv8;
  SIGNAL pa2_i,pb2_i,pa2_o,pb2_o : uv8;
  SIGNAL pa_en,pb_en,pa2_en,pb2_en : std_logic;
  SIGNAL map_reset : std_logic := '0';
  SIGNAL map_cpt : uint4;

  -- OVO -----------------------------------------
  FUNCTION CC(i : character) RETURN unsigned IS
  BEGIN
    CASE i IS
      WHEN '0' => RETURN "00000";
      WHEN '1' => RETURN "00001";
      WHEN '2' => RETURN "00010";
      WHEN '3' => RETURN "00011";
      WHEN '4' => RETURN "00100";
      WHEN '5' => RETURN "00101";
      WHEN '6' => RETURN "00110";
      WHEN '7' => RETURN "00111";
      WHEN '8' => RETURN "01000";
      WHEN '9' => RETURN "01001";
      WHEN 'A' => RETURN "01010";
      WHEN 'B' => RETURN "01011";
      WHEN 'C' => RETURN "01100";
      WHEN 'D' => RETURN "01101";
      WHEN 'E' => RETURN "01110";
      WHEN 'F' => RETURN "01111";
      WHEN ' ' => RETURN "10000";
      WHEN '=' => RETURN "10001";
      WHEN '+' => RETURN "10010";
      WHEN '-' => RETURN "10011";
      WHEN '<' => RETURN "10100";
      WHEN '>' => RETURN "10101";
      WHEN '^' => RETURN "10110";
      WHEN 'v' => RETURN "10111";
      WHEN '(' => RETURN "11000";
      WHEN ')' => RETURN "11001";
      WHEN ':' => RETURN "11010";
      WHEN '.' => RETURN "11011";
      WHEN ',' => RETURN "11100";
      WHEN '?' => RETURN "11101";
      WHEN '|' => RETURN "11110";
      WHEN '#' => RETURN "11111";
      WHEN OTHERS => RETURN "10000";
    END CASE;
  END FUNCTION CC;
  FUNCTION CS(s : string) RETURN unsigned IS
    VARIABLE r : unsigned(0 TO s'length*5-1);
    VARIABLE j : natural :=0;
  BEGIN
    FOR i IN s'RANGE LOOP
      r(j TO j+4) :=CC(s(i));
      j:=j+5;
    END LOOP;
    RETURN r;
  END FUNCTION CS;
  
  SIGNAL vga_r_i,vga_r_u  : unsigned(7 DOWNTO 0);
  SIGNAL vga_g_i,vga_g_u  : unsigned(7 DOWNTO 0);
  SIGNAL vga_b_i,vga_b_u  : unsigned(7 DOWNTO 0);
  SIGNAL vga_de_u,vga_de_v : std_logic;
  SIGNAL vga_hs_i,vga_vs_i : std_logic;
  SIGNAL vga_blank_i : std_logic;
  SIGNAL vga_de_i,vga_ce,vga_ce2,vga_ce3,vga_ce4,vga_ce5,vga_ce2x  : std_logic;
  
  SIGNAL ovo_ena  : std_logic;
  SIGNAL ovo_in0  : unsigned(0 TO 32*5-1) :=(OTHERS =>'0');
  SIGNAL ovo_in1  : unsigned(0 TO 32*5-1) :=(OTHERS =>'0');
  
  SIGNAL hits : uv64;
  SIGNAL hitbg,hitbo : uv8;

  TYPE type_jmap IS RECORD
    crc : uv32;
    m   : uint4;
  END RECORD;
  TYPE arr_jmap IS ARRAY (natural RANGE <>) OF type_jmap;
  CONSTANT MAPS : arr_jmap := (
    (x"4CC46A04",1),(x"D5F038B6",1),(x"A3ACD160",1),(x"4422868E",1),
    (x"C2063C08",1),(x"A12C27E1",1),
    (x"515E1D7E",2),(x"0BF464C6",2),(x"3289C8BA",2),(x"16BFB8EB",2),
    (x"6802B191",2),(x"13EE56F1",2),(x"FF83FF80",2),(x"2C5FD5FA",2),
    (x"632F6ADF",2),(x"B745C1CA",2),(x"BB939881",2),(x"800B572F",2),
    (x"32076E9D",2),(x"A95021FC",2),
    (x"D1D352A0",3),
    (x"3825C25B",4),
    (x"4B23A757",5),(x"D8F99AA2",5),(x"159AF7F7",5),(x"A21C31C3",5),
    (x"6E4E8EB4",5),
    (x"D5363B8C",6),
    (x"13FF363C",7),(x"C047D487",7),(x"5E6A8CD8",7),(x"E806AD91",7),
    (x"C83EEA4C",8),
    (x"CE8FC699",9),(x"095638C0",9));

  SIGNAL crc,xcrc : uv32;
  SIGNAL search,found : std_logic;
  SIGNAL mapcpt : natural RANGE 0 TO MAPS'length+1;
  SIGNAL smap,mmap,mmap2 : uint4;
  
  ----------------------------------------------------
	  
	signal vga_r_s : std_logic_vector(5 downto 0);
	signal vga_g_s : std_logic_vector(5 downto 0);
	signal vga_b_s : std_logic_vector(5 downto 0);
	
	signal osd_r_s : std_logic_vector(5 downto 0);
	signal osd_g_s : std_logic_vector(5 downto 0);
	signal osd_b_s : std_logic_vector(5 downto 0);

	signal vga_hs_s : std_logic;
	signal vga_vs_s : std_logic;
	
	signal vga_hsync_n_s : std_logic;
	signal vga_vsync_n_s : std_logic;
	  
	signal kbd_intr : std_logic;
	signal kbd_scancode  : std_logic_vector(7 downto 0);
	signal osd_s  : std_logic_vector(7 downto 0);
	  
	signal  audio_out_l          :    std_logic_vector(15 DOWNTO 0);
	signal  audio_out_r          :    std_logic_vector(15 DOWNTO 0);
	  
	signal JoyKeys : std_logic_vector(15 downto 0);
  
  signal IsReleased : Std_logic;
  
  signal osd_enable :std_logic;
  
	-- LOADER -----------------------------------
	signal clk_zpu : std_logic;	
	signal osd_window : std_logic;
	signal osd_pixel : std_logic;
	signal dipswitches : std_logic_vector(15 downto 0);

	signal host_reset_n : std_logic;
	signal host_reset_loader : std_logic;
	signal host_divert_sdcard : std_logic;
	signal host_divert_keyboard : std_logic;
	signal host_select : std_logic;
	signal host_start : std_logic;

	signal bootdata : std_logic_vector(31 downto 0);
	signal bootdata_req : std_logic;
	signal bootdata_ack : std_logic := '0';
	  
	signal rom_size : std_logic_vector(31 downto 0);
	
	signal bytesloaded : unsigned(31 downto 0);
	signal data : std_logic_vector(31 downto 0);
	signal boot_state : std_logic_vector(3 downto 0) := "0000";
	
	signal dio_data : std_logic_vector(15 downto 0);
	
	signal btn_scandb_s		: std_logic;
	
	signal scandblctrl : std_logic := '0';
	
	signal controls_s			: std_logic_vector(8 downto 0);
	
  
BEGIN
		stm_rst_o		<= '0'; -- '0' to hold the microcontroller reset line, to free the SD card
		
--   d_io : data_io
--    GENERIC MAP 
--	 (
--      STRLEN => CONF_STR'length
--	 )
--    PORT MAP 
--	 (
--		clk_sys            => clksys,
--
--		SPI_SCK => SPI_SCK,
--		SPI_SS2 => SPI_SS2,
--		SPI_DI  => SPI_DI,
--		SPI_DO  => SPI_DO,
--
--		data_in => osd_s,
--		conf_str           => to_slv(CONF_STR),
--		status => status,
--
--		ioctl_download     => ioctl_download,
--		ioctl_index        => ioctl_index,
--		ioctl_wr           => ioctl_wr,
--		ioctl_addr         => ioctl_addr,
--		ioctl_dout         => ioctl_dout
--
--	);

  pal<='0';--status(10);
  swap<=status(1);
  ecs<='0';--status(8);
  ivoice<='1';--NOT status(9);
  
  control: work.CtrlModule
	port map
	(
			clk						=> clk_zpu, 
			reset_n					=> btn_n_i(1), 
			
			vga_hsync				=> vga_hsync_n_s, 
			vga_vsync				=> vga_vsync_n_s, 
			scandoubler_disable  => scandblctrl,
			osd_window				=> osd_window, 
			osd_pixel				=> osd_pixel, 
			
			ps2k_clk_in				=> ps2_clk_io, 
			ps2k_dat_in				=> ps2_data_io,
			
			spi_miso					=> sd_miso_i, 
			spi_mosi					=> sd_mosi_o, 
			spi_clk					=> sd_sclk_o, 
			spi_cs					=> sd_cs_n_o, 
			
			dipswitches				=> status, 
			size						=> rom_size, 
			index						=> open, --dio_index,
			joy_pins					=> not(btn_n_i(4) or btn_n_i(3)) & not joy1_up_i & not joy1_down_i & not joy1_left_i & not joy1_right_i & not joy1_p6_i, 
			
			host_divert_sdcard	=> host_divert_sdcard, 
			host_divert_keyboard	=> host_divert_keyboard, 
			host_reset_n			=> host_reset_n, 
			host_reset_loader		=> host_reset_loader,
			
			host_bootdata			=> bootdata, 
			host_bootdata_req		=> bootdata_req, 
			host_bootdata_ack		=> bootdata_ack
	);
	
	osd_overlay: work.OSD_Overlay  
	port map
	(
			clk					=> clk_zpu,
			red_in				=> osd_r_s & "00",
			green_in				=> osd_g_s & "00",
			blue_in				=> osd_b_s & "00",
			window_in			=> '1',
			hsync_in				=> '1',
			
			osd_window_in		=> osd_window,
			osd_pixel_in		=> osd_pixel,
			red_out(7 downto 4)		=> vga_r_o,
			green_out(7 downto 4)	=> vga_g_o,
			blue_out(7 downto 4)		=> vga_b_o,
			window_out			=> open,
			scanline_ena		=> '0'
	);	

  ----------------------------------------------------------
  ipll : entity work.pll
    PORT MAP (
      inclk0   => clock_50_i,
      c0 => clksys_ntsc, -- 3.579545MHz * 12 = 42.95454MHz
      c1 => clksys_pal,  -- 4MHz * 12 = 48MHz
		c2 => clk_zpu,
      locked   => pll_locked
      );
  
  clksys<=clksys_ntsc;
  
  -- NTSC : 3.579545MHz
  -- PAL  : 4MHz

  -- STIC : CLK * 12
  -- IVOICE : CLK
  Clepsydre:PROCESS(clksys) IS
  BEGIN
    IF rising_edge(clksys) THEN
      tick_cpup<='0';
      IF clkdiv/=12*4-1 THEN
        clkdiv<=clkdiv+1;
      ELSE
        clkdiv<=0;
        tick_cpup<='1';
      END IF;
      tick_cpu<=tick_cpup;
      
      tick_snd<='0';
      IF tick_cpu='1' THEN
        clkdivsnd<=(clkdivsnd+1) MOD 4;
        IF clkdivsnd=0 THEN
          tick_snd<='1';
        END IF;
      END IF;
		
		
      IF clkdivivoice=11 THEN
        tick_ivoice<='1';
        clkdivivoice<=0;
      ELSE
        tick_ivoice<='0';
        clkdivivoice<=clkdivivoice+1;
      END IF;
		
    END IF;
  END PROCESS Clepsydre;
  
  ----------------------------------------------------------
  -- CPU
  i_cp1610: ENTITY work.cp1610
    PORT MAP (
      dr       => dr,
      dw       => dw,
      bdic     => bdic,
      ebci     => x"0000",
      msync    => '0',
      bdrdy    => bdrdy,
      intr     => '0',
      intrm    => intrm,
      tci      => OPEN,
      pci      => '0',
      pct      => OPEN,
      busrq    => busrq,
      busak    => busak,
      stpst    => '0',
      halt     => halt,
      phi      => tick_cpu,
      phip     => tick_cpup,
      clk      => clksys,
      reset_na => reset_na);
  
  -- STIC + SYSRAM + GRAM + GROM + Decoder
  i_stic: ENTITY work.stic
    PORT MAP (
      dw       => dw,
      dr       => dr,
      bdic     => bdic,
      bdrdy    => bdrdy,
      busrq    => busrq,
      busak    => busak,
      intrm    => intrm,
      phi      => tick_cpu,
		 pal       => pal,
		ecs      => ecs,
		ivoice    => ivoice,
      ad       => ad,
      snd_dr   => snd_dr,
      snd_dw   => snd_dw,
      snd_wr   => snd_wr,
		snd2_dr  => snd2_dr,
      snd2_dw  => snd2_dw,
      snd2_wr  => snd2_wr,
		 ivoice_dr => ivoice_dr,
      ivoice_dw => ivoice_dw,
      ivoice_wr => ivoice_wr,
      cart_dr  => cart_dr,
      cart_dw  => cart_dw,
      cart_wr  => cart_wr,
      hits => hits,
      hitbg => hitbg,
      hitbo => hitbo,
      vid_r    => vga_r_i,
      vid_g    => vga_g_i,
      vid_b    => vga_b_i,
      vid_de   => vga_de_i,
      vid_hs   => vga_hs_i,
      vid_vs   => vga_vs_i,
      vid_ce   => vga_ce,
      vid_ce2x   => vga_ce2x,
		vid_blank => vga_blank_i,
      clk      => clksys,
      reset_na => reset_na);

		
  -- Intellivoice
  i_ivoice: ENTITY work.ivoice
    PORT MAP (
      ad       => ad,
      dw       => ivoice_dw,
      dr       => ivoice_dr,
      wr       => ivoice_wr,
      tick_cpu => tick_cpu,
      tick     => tick_ivoice,
      divi     => ivoice_divi,
      sound    => sound_iv,
      clksys   => clksys,
      reset_na => reset_na);

  ivoice_divi<=358 WHEN pal='0' ELSE 400;
  
  -- AUDIO+IO AY-3-8914
  i_snd: ENTITY work.snd
    PORT MAP (
      ad       => ad,
      dw       => snd_dw,
      dr       => snd_dr,
      wr       => snd_wr,
      sound    => sound,
      pa_i     => pa_i,
      pa_o     => pa_o,
      pa_en    => pa_en,
      pb_i     => pb_i,
      pb_o     => pb_o,
      pb_en    => pb_en,
      tick     => tick_snd,
      clk      => clksys,
      reset_na => reset_na);
		
		  -- Second audio ECS
  i_snd2: ENTITY work.snd
    PORT MAP (
      ad       => ad,
      dw       => snd2_dw,
      dr       => snd2_dr,
      wr       => snd2_wr,
      sound    => sound2,
      pa_i     => pa2_i,
      pa_o     => pa2_o,
      pa_en    => pa2_en,
      pb_i     => pb2_i,
      pb_o     => pb2_o,
      pb_en    => pb2_en,
      tick     => tick_snd,
      clk      => clksys,
      reset_na => reset_na);
			  
 audio_out_l<=std_logic_vector(sound + signed(mux(ecs,unsigned(sound2),x"00")) +
    signed(mux(ivoice,unsigned(sound_iv(15 DOWNTO 8)),x"00")) & x"00");

  audio_out_r<=std_logic_vector(sound + signed(mux(ecs,unsigned(sound2),x"00")) +
    signed(mux(ivoice,unsigned(sound_iv(15 DOWNTO 8)),x"00")) & x"00");

   dac_L : work.dac
	generic map
	(
		C_bits  => 16
	)
	port map
	(
		clk_i   => clksys,
		res_n_i => reset_na,
		dac_i   => "00" & audio_out_l(15 downto 2),
		dac_o   => dac_l_o
	);

	dac_R : work.dac
	generic map
	(
		C_bits  => 16
	)
	port map
	(
		clk_i   => clksys,
		res_n_i => reset_na,
		dac_i   => "00" & audio_out_r(15 downto 2),
		dac_o   => dac_r_o
	);
	
  ----------------------------------------------------------
  -- MAPPINGS
  -- MAP 0
  --   $0000 - $1FFF = $5000   ;  8K to $5000 - $6FFF
  --   $2000 - $2FFF = $D000   ;  4K to $D000 - $DFFF
  --   $3000 - $3FFF = $F000   ;  4K to $F000 - $FFFF
 
  -- MAP 1
  --   $0000 - $1FFF = $5000   ;  8K to $5000 - $6FFF
  --   $2000 - $4FFF = $D000   ; 12K to $D000 - $FFFF

  -- MAP 2
  --   $0000 - $1FFF = $5000   ;  8K to $5000 - $6FFF
  --   $2000 - $4FFF = $9000   ; 12K to $9000 - $BFFF
  --   $5000 - $5FFF = $D000   ;  4K to $D000 - $DFFF

  -- MAP 3
  --   $0000 - $1FFF = $5000   ;  8K to $5000 - $6FFF
  --   $2000 - $3FFF = $9000   ;  8K to $9000 - $AFFF
  --   $4000 - $4FFF = $D000   ;  4K to $D000 - $DFFF
  --   $5000 - $5FFF = $F000   ;  4K to $F000 - $FFFF

  -- MAP 4
  --   $0000 - $1FFF = $5000   ;  8K to $5000 - $6FFF
  --   RAM $D000 - $D3FF = RAM 8

  -- MAP 5
  --   $0000 - $2FFF = $5000   ; 12K to $5000 - $7FFF
  --   $3000 - $5FFF = $9000   ; 12K to $9000 - $BFFF

  -- MAP 6
  --   $0000 - $1FFF = $6000   ;  8K to $6000 - $7FFF

  -- MAP 7
  --   $0000 - $1FFF = $4800   ;  8K to $4800 - $67FF

  -- MAP 8
  --   $0000 - $0FFF = $5000   ;  4K to $5000 - $6000
  --   $1000 - $1FFF = $7000   ;  4K to $7000 - $7FFF

  -- MAP 9
  --   $0000 - $1FFF = $5000   ;  8K to $5000 - $6FFF
  --   $2000 - $3FFF = $9000   ;  8K to $9000 - $AFFF
  --   $4000 - $4FFF = $D000   ;  4K to $D000 - $DFFF
  --   $5000 - $5FFF = $F000   ;  4K to $F000 - $FFFF
  --   RAM $8800 - $8FFF = RAM 8

  PROCESS(ad,mmap) IS
    VARIABLE aad : uv12;
    FUNCTION sel(ad : uv15;
                 c  : boolean) RETURN unsigned IS
    BEGIN
      IF c THEN RETURN '1' & ad;
           ELSE RETURN x"0000";
           END IF;
    END FUNCTION;
  BEGIN
    aad:=ad(11 DOWNTO 0);
    selram<='0';
    
    CASE mmap IS
      WHEN 0 =>
        cad<=sel("000" & aad,ad(15 DOWNTO 12)=x"5") OR
             sel("001" & aad,ad(15 DOWNTO 12)=x"6") OR
             sel("010" & aad,ad(15 DOWNTO 12)=x"D") OR
             sel("011" & aad,ad(15 DOWNTO 12)=x"F");
        
      WHEN 1 =>
        cad<=sel("000" & aad,ad(15 DOWNTO 12)=x"5") OR
            sel("001" & aad,ad(15 DOWNTO 12)=x"6") OR
            sel("010" & aad,ad(15 DOWNTO 12)=x"D") OR
            sel("011" & aad,ad(15 DOWNTO 12)=x"E") OR
            sel("100" & aad,ad(15 DOWNTO 12)=x"F");
        
      WHEN 2 =>
        cad<=sel("000" & aad,ad(15 DOWNTO 12)=x"5") OR
             sel("001" & aad,ad(15 DOWNTO 12)=x"6") OR
             sel("010" & aad,ad(15 DOWNTO 12)=x"9") OR
             sel("011" & aad,ad(15 DOWNTO 12)=x"A") OR
             sel("100" & aad,ad(15 DOWNTO 12)=x"B") OR
             sel("101" & aad,ad(15 DOWNTO 12)=x"D");
        
      WHEN 3 =>
        cad<=sel("000" & aad,ad(15 DOWNTO 12)=x"5") OR
             sel("001" & aad,ad(15 DOWNTO 12)=x"6") OR
             sel("010" & aad,ad(15 DOWNTO 12)=x"9") OR
             sel("011" & aad,ad(15 DOWNTO 12)=x"A") OR
             sel("100" & aad,ad(15 DOWNTO 12)=x"D") OR
             sel("101" & aad,ad(15 DOWNTO 12)=x"F");
        
      WHEN 4 =>
        cad<=sel("000" & aad,ad(15 DOWNTO 12)=x"5") OR
             sel("001" & aad,ad(15 DOWNTO 12)=x"6");
        
        selram<=to_std_logic(ad(15 DOWNTO 10)="110100");
        
      WHEN 5 =>
        cad<=sel("000" & aad,ad(15 DOWNTO 12)=x"5") OR
             sel("001" & aad,ad(15 DOWNTO 12)=x"6") OR
             sel("010" & aad,ad(15 DOWNTO 12)=x"7") OR
             sel("011" & aad,ad(15 DOWNTO 12)=x"9") OR
             sel("100" & aad,ad(15 DOWNTO 12)=x"A") OR
             sel("101" & aad,ad(15 DOWNTO 12)=x"B");
        
      WHEN 6 =>
        cad<=sel("000" & aad,ad(15 DOWNTO 12)=x"6") OR
             sel("001" & aad,ad(15 DOWNTO 12)=x"7");
        
      WHEN 7 =>
        cad<=sel("0000" & aad(10 DOWNTO 0),ad(15 DOWNTO 11)="01001") OR -- 48
             sel("0001" & aad(10 DOWNTO 0),ad(15 DOWNTO 11)="01010") OR -- 50
             sel("0010" & aad(10 DOWNTO 0),ad(15 DOWNTO 11)="01011") OR -- 58
             sel("0011" & aad(10 DOWNTO 0),ad(15 DOWNTO 11)="01100");   -- 60
        
      WHEN 8 =>
        cad<=sel("000" & aad,ad(15 DOWNTO 12)=x"5") OR
             sel("001" & aad,ad(15 DOWNTO 12)=x"7");

      WHEN 9 =>
        cad<=sel("000" & aad,ad(15 DOWNTO 12)=x"5") OR
             sel("001" & aad,ad(15 DOWNTO 12)=x"6") OR
             sel("010" & aad,ad(15 DOWNTO 12)=x"9") OR
             sel("011" & aad,ad(15 DOWNTO 12)=x"A") OR
             sel("100" & aad,ad(15 DOWNTO 12)=x"D") OR
             sel("101" & aad,ad(15 DOWNTO 12)=x"F");
        selram<=to_std_logic(ad(15 DOWNTO 10)="110100");
        
      WHEN OTHERS =>
        cad<=sel("000" & aad,ad(15 DOWNTO 12)=x"5") OR
             sel("001" & aad,ad(15 DOWNTO 12)=x"6") OR
             sel("010" & aad,ad(15 DOWNTO 12)=x"D") OR
             sel("011" & aad,ad(15 DOWNTO 12)=x"F");
        
    END CASE;
  END PROCESS;

  Map_Change:PROCESS(clksys) IS
  BEGIN
    IF rising_edge(clksys) THEN
      
      IF status(7 DOWNTO 4)="0000" THEN
        mmap<=mux(found='1',smap,0);
      ELSE
        mmap<=to_integer(unsigned(status(7 DOWNTO 4)))-1;
      END IF;
      
      mmap2<=mmap;
		ecs2<=ecs;
      
      IF mmap2/=mmap OR ecs2/=ecs THEN
        map_cpt<=0;
      END IF;
      IF map_cpt<15 THEN
        map_cpt<=map_cpt+1;
        map_reset<='1';        
      ELSE
        map_reset<='0';
      END IF;
    END IF;
  END PROCESS;
  
  ----------------------------------------------------------
  CRCCalc:PROCESS(clksys) IS
    FUNCTION crc8 (
      CONSTANT d   : IN unsigned(7 DOWNTO 0);
      CONSTANT crc : IN unsigned(31 DOWNTO 0)) RETURN unsigned IS
      VARIABLE co : unsigned(31 DOWNTO 0);
      VARIABLE h  : unsigned(7 DOWNTO 0);
    BEGIN
      h(0):=d(0) XOR crc(31);
      h(1):=d(1) XOR crc(30);
      h(2):=d(2) XOR crc(29);
      h(3):=d(3) XOR crc(28);
      h(4):=d(4) XOR crc(27);
      h(5):=d(5) XOR crc(26);
      h(6):=d(6) XOR crc(25) XOR h(0);
      h(7):=d(7) XOR crc(24) XOR h(1);
      co(0) :=h(7);
      co(1) :=h(6) XOR h(7);
      co(2) :=h(5) XOR h(6) XOR h(7);
      co(3) :=h(4) XOR h(5) XOR h(6);
      co(4) :=h(3) XOR h(4) XOR h(5) XOR h(7);
      co(5) :=h(2) XOR h(3) XOR h(4) XOR h(6) XOR h(7);
      co(6) :=h(1) XOR h(2) XOR h(3) XOR h(5) XOR h(6);
      co(7) :=h(0) XOR h(1) XOR h(2) XOR h(4) XOR h(5) XOR h(7);
      co(8) := crc(0) XOR h(0) XOR h(1) XOR h(3) XOR h(4) XOR h(6) XOR h(7);
      co(9) := crc(1) XOR h(0) XOR h(2) XOR h(3) XOR h(5) XOR h(6);
      co(10):= crc(2) XOR h(1) XOR h(2) XOR h(4) XOR h(5) XOR h(7);
      co(11):= crc(3) XOR h(0) XOR h(1) XOR h(3) XOR h(4) XOR h(6) XOR h(7);
      co(12):= crc(4) XOR h(0) XOR h(2) XOR h(3) XOR h(5) XOR h(6) XOR h(7);
      co(13):= crc(5) XOR h(1) XOR h(2) XOR h(4) XOR h(5) XOR h(6);
      co(14):= crc(6) XOR h(0) XOR h(1) XOR h(3) XOR h(4) XOR h(5);
      co(15):= crc(7) XOR h(0) XOR h(2) XOR h(3) XOR h(4);
      co(16):= crc(8) XOR h(1) XOR h(2) XOR h(3) XOR h(7);
      co(17):= crc(9) XOR h(0) XOR h(1) XOR h(2) XOR h(6);
      co(18):=crc(10) XOR h(0) XOR h(1) XOR h(5);
      co(19):=crc(11) XOR h(0) XOR h(4);
      co(20):=crc(12) XOR h(3);
      co(21):=crc(13) XOR h(2);
      co(22):=crc(14) XOR h(1) XOR h(7);
      co(23):=crc(15) XOR h(0) XOR h(6) XOR h(7);
      co(24):=crc(16) XOR h(5) XOR h(6);
      co(25):=crc(17) XOR h(4) XOR h(5);
      co(26):=crc(18) XOR h(3) XOR h(4) XOR h(7);
      co(27):=crc(19) XOR h(2) XOR h(3) XOR h(6);
      co(28):=crc(20) XOR h(1) XOR h(2) XOR h(5);
      co(29):=crc(21) XOR h(0) XOR h(1) XOR h(4);
      co(30):=crc(22) XOR h(0) XOR h(3);
      co(31):=crc(23) XOR h(2);
      RETURN co;
    END crc8;
  BEGIN
    IF rising_edge(clksys) THEN
      IF ioctl_wr='1' THEN
        crc<=crc8(unsigned(ioctl_dout), --aqui pega o byte do loader para fazer o CRC
                  mux(to_integer(unsigned(ioctl_addr))=0,x"FFFFFFFF",crc));
      END IF;
      
      FOR i IN 0 TO 31 LOOP
        xcrc(i)<=NOT crc(31-i);
      END LOOP;

      ioctl_download2<=ioctl_download;
      
      IF search='0' THEN
        IF ioctl_download='0' AND ioctl_download2='1' THEN
          search<='1';
          found<='0';
        END IF;
        mapcpt<=0;
      ELSE
        mapcpt<=mapcpt+1;
        IF xcrc=MAPS(mapcpt).crc THEN
          smap<=MAPS(mapcpt).m;
          found<='1';
        END IF;
        IF mapcpt=MAPS'length THEN
          search<='0';
        END IF;
      END IF;
    END IF;
  END PROCESS CRCCalc;
  
  ----------------------------------------------------------

  
  IRAM:PROCESS(clksys) IS
  BEGIN
    IF rising_edge(clksys) THEN
      ram_dr<=ram(to_integer(cad(10 DOWNTO 0)));
      IF cart_wr='1' AND selram='1' THEN
        ram(to_integer(cad(10 DOWNTO 0)))<=cart_dw;
      END IF;
    END IF;
  END PROCESS IRAM;
  
  cart_dr<=rom_dr WHEN cad(15)='1' ELSE
           ram_dr WHEN selram='1' ELSE
           x"FFFF";
  

  
  ioctl_wait<='0';
  
  ----------------------------------------------------------
  -- IO MAPPING
  
  PROCESS (key_1,key_2,key_3,key_4,key_5,key_6,key_7,key_8,key_9,
           key_0,key_r,key_w,key_space,key_enter,swap,
           joystick_0,joystick_1,joystick_analog_0,joystick_analog_1
           ) IS
    
    CONSTANT dirtable : arr_uv8(0 TO 15):= (-- NDLR
      x"00", -- 0000 : no press
      x"02", -- 0001 : E
      x"08", -- 0010 : W
      x"00", -- 0011 : WE = no press
      x"01", -- 0100 : S
      x"13", -- 0101 : SE
      x"19", -- 0110 : SW
      x"01", -- 0111 : SWE = S
      x"04", -- 1000 : N
      x"16", -- 1001 : NE
      x"1C", -- 1010 : NW
      x"04", -- 1011 : NWE = N
      x"00", -- 1100 : NS = no press
      x"02", -- 1101 : NSE = E
      x"08", -- 1110 : NSW = W
      x"00"); -- 1111 : NSWE = no press
    
    CONSTANT dir16 : arr_uv8(0 TO 255) := (
      x"1C",x"1C",x"1C",x"18",x"18",x"08",x"08",x"08",x"08",x"08",x"08",x"09",x"09",x"19",x"19",x"19",
      x"1C",x"1C",x"1C",x"18",x"18",x"18",x"08",x"08",x"08",x"08",x"09",x"09",x"09",x"19",x"19",x"19",
      x"1C",x"1C",x"1C",x"1C",x"18",x"18",x"08",x"08",x"08",x"08",x"09",x"09",x"19",x"19",x"19",x"19",
      x"0C",x"0C",x"1C",x"1C",x"1C",x"18",x"18",x"08",x"08",x"09",x"09",x"19",x"19",x"19",x"11",x"11",
      x"0C",x"0C",x"0C",x"1C",x"1C",x"00",x"00",x"00",x"00",x"00",x"00",x"19",x"19",x"11",x"11",x"11",
      x"04",x"0C",x"0C",x"0C",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"11",x"11",x"11",x"01",
      x"04",x"04",x"04",x"0C",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"11",x"01",x"01",x"01",
      x"04",x"04",x"04",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"01",x"01",
      x"04",x"04",x"04",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"01",x"01",
      x"04",x"04",x"04",x"14",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"03",x"01",x"01",x"01",
      x"04",x"14",x"14",x"14",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"03",x"03",x"03",x"01",
      x"14",x"14",x"14",x"16",x"16",x"00",x"00",x"00",x"00",x"00",x"00",x"13",x"13",x"03",x"03",x"03",
      x"14",x"14",x"16",x"16",x"16",x"06",x"06",x"02",x"02",x"12",x"12",x"13",x"13",x"13",x"03",x"03",
      x"16",x"16",x"16",x"16",x"06",x"06",x"02",x"02",x"02",x"02",x"12",x"12",x"13",x"13",x"13",x"13",
      x"16",x"16",x"16",x"06",x"06",x"06",x"02",x"02",x"02",x"02",x"12",x"12",x"12",x"13",x"13",x"13",
      x"16",x"16",x"16",x"06",x"06",x"02",x"02",x"02",x"02",x"02",x"02",x"12",x"12",x"13",x"13",x"13");
    
      VARIABLE io_v,io2_v : uv8;
  BEGIN
    -- PORT A
   -- io_v:=dirtable(to_integer(unsigned(joystick_0(3 DOWNTO 0)))); -- Direction cross
	 
	 io_v:=dirtable(to_integer(unsigned(JoyKeys(3 downto 0)))); -- Direction cross
	 
    
--	 io_v:=io_v OR dir16(to_integer((unsigned(joystick_analog_0( 7 DOWNTO 4)) + x"8") &
 --                                  (unsigned(joystick_analog_0(15 DOWNTO 12))  + x"8")));
 
	 
	 io_v:=io_v OR ("10100000" AND sext((key_z 		OR JoyKeys( 4)),8)); -- Action UP
    io_v:=io_v OR ("01100000" AND sext((key_x 		OR JoyKeys( 5)),8)); -- Action BL
    io_v:=io_v OR ("11000000" AND sext((key_c 		OR JoyKeys( 6)),8)); -- Action BR
	
	io_v:=io_v OR ("10001000" AND sext((key_backspace  ),8)); -- Clear
   io_v:=io_v OR ("00101000" AND sext((key_enter ),8)); -- Enter 	 

   io_v:=io_v OR ("01001000" AND sext(( key_0 ),8)); -- 0
   io_v:=io_v OR ("10000001" AND sext(( key_1 ),8));
   io_v:=io_v OR ("01000001" AND sext(( key_2 ),8));
   io_v:=io_v OR ("00100001" AND sext(( key_3 ),8));
   io_v:=io_v OR ("10000010" AND sext(( key_4 ),8));
   io_v:=io_v OR ("01000010" AND sext(( key_5 ),8));
   io_v:=io_v OR ("00100010" AND sext(( key_6 ),8));
   io_v:=io_v OR ("10000100" AND sext(( key_7 ),8));
   io_v:=io_v OR ("01000100" AND sext(( key_8 ),8));
   io_v:=io_v OR ("00100100" AND sext(( key_9 ),8));
    
    ---------------------------------
    -- PORT B
    io2_v:=dirtable(to_integer(unsigned(joystick_1(3 DOWNTO 0))));
    io2_v:=io2_v OR dir16(to_integer((unsigned(joystick_analog_1( 7 DOWNTO 4)) + x"8") &
                                     (unsigned(joystick_analog_1(15 DOWNTO 12))  + x"8")));
    io2_v:=io2_v OR ("10100000" AND sext(joystick_1( 4),8)); -- Action UP
    io2_v:=io2_v OR ("01100000" AND sext(joystick_1( 5),8)); -- Action BL
    io2_v:=io2_v OR ("11000000" AND sext(joystick_1( 6),8)); -- Action BR
    io2_v:=io2_v OR ("10001000" AND sext(joystick_1( 7),8)); -- Clear
    io2_v:=io2_v OR ("00101000" AND sext(joystick_1( 8),8)); -- Enter 
    io2_v:=io2_v OR ("01001000" AND sext(joystick_1( 9),8)); -- 0
    io2_v:=io2_v OR ("10000001" AND sext(joystick_1(10),8));
    io2_v:=io2_v OR ("01000001" AND sext(joystick_1(11),8));
    io2_v:=io2_v OR ("00100001" AND sext(joystick_1(12),8));
    io2_v:=io2_v OR ("10000010" AND sext(joystick_1(13),8));
    io2_v:=io2_v OR ("01000010" AND sext(joystick_1(14),8));
    io2_v:=io2_v OR ("00100010" AND sext(joystick_1(15),8));
    io2_v:=io2_v OR ("10000100" AND sext(joystick_1(16),8));
    io2_v:=io2_v OR ("01000100" AND sext(joystick_1(17),8));
    io2_v:=io2_v OR ("00100100" AND sext(joystick_1(18),8));
    
    pa_i<=NOT mux(swap,io_v,io2_v);
    pb_i<=NOT mux(swap,io2_v,io_v);
    
  END PROCESS;

  
  ----------------------------------------------------------
  -- ECS Keyboard

  --bits | 0     1     2     3     4     5      6      7
  -------+----------------------------------------------------
  --  7  | n/a   n/a   n/a   n/a   n/a   n/a    n/a    n/a
  --  6  | shift n/a   n/a   n/a   n/a   n/a    n/a    n/a
  --  5  | a     ctrl  right 1     q     up     down   space
  --  4  | d     e     2     3     w     s      z      x
  --  3  | g     t     4     5     r     f      c      v
  --  2  | j     u     6     7     y     h      b      n
  --  1  | l     o     8     9     i     k      m      comma
  --  0  | n/a   enter 0     esc   p     scolon period left
  -------+----------------------------------------------------

  PROCESS(key_0,key_1,key_2,key_3,key_4,key_5,key_6,key_7,key_8,key_9,
          key_a,key_b,key_c,key_d,key_e,key_f,key_g,key_h,key_i,key_j,
          key_k,key_l,key_m,key_n,key_o,key_p,key_q,key_r,key_s,key_t,
          key_u,key_v,key_w,key_x,key_y,key_z,
          key_space,key_colon,key_period,key_comma,
          key_up,key_down,key_right,key_left,
          key_enter,key_esc,key_lshift,key_rshift,key_lctrl,key_rctrl,pa2_o,pb2_o,pa2_en,pb2_en) IS
    VARIABLE dr : uv8;
  BEGIN
    IF pa2_en='1' AND pb2_en='0' THEN
      dr:=x"00";
      dr:=dr OR mux(NOT pa2_o(7),
                    "00000000",x"00");
      dr:=dr OR mux(NOT pa2_o(6),
                    (key_rshift OR key_lshift) & "0000000",x"00");
      dr:=dr OR mux(NOT pa2_o(5),
                    key_a & (key_rctrl OR key_lctrl) & key_right & key_1 & key_q & key_up & key_down & key_space,x"00");
      dr:=dr OR mux(NOT pa2_o(4),
                    key_d & key_e & key_2 & key_3 & key_w & key_s & key_z & key_x,x"00");
      dr:=dr OR mux(NOT pa2_o(3),
                    key_g & key_t & key_4 & key_5 & key_r & key_f & key_c & key_v,x"00");
      dr:=dr OR mux(NOT pa2_o(2),
                    key_j & key_u & key_6 & key_7 & key_y  & key_h & key_b & key_n,x"00");
      dr:=dr OR mux(NOT pa2_o(1),
                    key_l & key_o & key_8 & key_9 & key_i & key_k & key_m & key_comma,x"00");
      dr:=dr OR mux(NOT pa2_o(0),
                    '0' & key_enter & key_0 & key_esc & key_p & key_colon & key_period & key_left,x"00");
      dr:=NOT dr;
    ELSIF pa2_en='0' AND pb2_en='1' THEN
      dr:=x"FF";
      -- <TODO>
    ELSE
      dr:=x"FF";
    END IF;
    pb2_i<=dr;
    pa2_i<=dr;

  END PROCESS;

  

  
  ----------------------------------------------------------
  i_ovo: ENTITY work.ovo
    PORT MAP (
      i_r     => vga_r_i,
      i_g     => vga_g_i,
      i_b     => vga_b_i,
      i_hs    => vga_hs_i,
      i_vs    => vga_vs_i,
      i_de    => vga_de_i,
      i_en    => vga_ce,
      i_clk   => clksys,
      o_r     => vga_r_u,
      o_g     => vga_g_u,
      o_b     => vga_b_u,
      o_hs    => vga_hs_s,
      o_vs    => vga_vs_s,
      o_de    => vga_de_u,
      ena     => ovo_ena,
      in0     => ovo_in0,
      in1     => ovo_in1);

  PROCESS(clksys) IS
  BEGIN
    IF rising_edge(clksys) THEN
	 
	 
	 		if vga_blank_i = '0' then
					IF vga_ce='1' THEN

						  vga_r_s <= std_logic_vector(vga_r_u(7 downto 2));
						  vga_g_s <= std_logic_vector(vga_g_u(7 downto 2));
						  vga_b_s <= std_logic_vector(vga_b_u(7 downto 2));
						
					  
						  vga_de_v <= vga_de_u;
						 -- vga_de<=vga_de_v;
					  
					END IF;
		   else
						  vga_r_s <= (others=>'0');
						  vga_g_s <= (others=>'0');
						  vga_b_s <= (others=>'0');

			end if;
			
			vga_ce2 <= vga_ce;
			vga_ce3 <= vga_ce2;
			vga_ce4 <= vga_ce3;
			vga_ce5 <= vga_ce4;

			--ce_pixel<=vga_ce;
      
    END IF;
  END PROCESS;

  --clk_video<=clksys;
  
 	video1 : mist_video
	port map
	(
		clk_sys 	=> clksys,

		scanlines  => "00",

		ce_divider => '1',
		ce_x1 => vga_ce,
		ce_x2 => vga_ce2x,
		
		scandoubler_disable => scandblctrl,

		blend => '0',

		R => vga_r_s,
		G => vga_g_s,
		B => vga_b_s,

		HSync => vga_hs_s,
		VSync => vga_vs_s,

		VGA_R => osd_r_s,
		VGA_G => osd_g_s,
		VGA_B => osd_b_s,
		VGA_VS => vga_vsync_n_s,
		VGA_HS => vga_hsync_n_s,
		osd_enable => osd_enable
	);
	
	--vga_hsync_n_o <= 	vga_hsync_n_s;
	--vga_vsync_n_o <= 	vga_vsync_n_s;
	
	vga_hsync_n_o <= not(vga_hsync_n_s xor vga_vsync_n_s) when scandblctrl = '1' else vga_hsync_n_s;
	vga_vsync_n_o <= '1' when scandblctrl = '1' else vga_vsync_n_s;


  
  
  ovo_in0<=
				CS("   ") & --chars outside screen
				'0' & pa_i(7 DOWNTO 4) &
            '0' & pa_i(3 DOWNTO 0) &
            CC(' ') &
            '0' & pb_i(7 DOWNTO 4) &
            '0' & pb_i(3 DOWNTO 0) &
            CC(' ') &
            "0000" & intrm &
            CC(' ') &
            '0' & ad(15 DOWNTO 12) &
            '0' & ad(11 DOWNTO 8) &
            '0' & ad(7 DOWNTO 4) &
            '0' & ad(3 DOWNTO 0) &
            CC(' ') &
            "0000" & bdic(2) &
            "0000" & bdic(1) &
            "0000" & bdic(0) &
            CC(' ') &
            '0' & unsigned(joystick_analog_0(15 DOWNTO 12)) &
            '0' & unsigned(joystick_analog_0(11 DOWNTO 8)) &
            '0' & unsigned(joystick_analog_0(7 DOWNTO 4)) &
            '0' & unsigned(joystick_analog_0(3 DOWNTO 0)) &
            CS("  ") &
            '0' & to_unsigned(mmap,4) &
            CC(' ') &
      --      "00" & unsigned(ps2_key_mem(10 DOWNTO 8)) &
      --      '0' & unsigned(ps2_key_mem(7 DOWNTO 4)) &
      --      '0' & unsigned(ps2_key_mem(3 DOWNTO 0)) &
      --      CC(' ') &
            "0000" & bdrdy &
            "0000" & busrq &
            "0000" & busak &
            CS(" ");
  
  ovo_in1<=
    CS("        ") &
    '0' & xcrc(31 DOWNTO 28) &
    '0' & xcrc(27 DOWNTO 24) &
    '0' & xcrc(23 DOWNTO 20) &
    '0' & xcrc(19 DOWNTO 16) &
    '0' & xcrc(15 DOWNTO 12) &
    '0' & xcrc(11 DOWNTO 8) &
    '0' & xcrc(7 DOWNTO 4) &
    '0' & xcrc(3 DOWNTO 0) &
    CC(' ') &
    '0' & hitbg(7 DOWNTO 4) &
    '0' & hitbg(3 DOWNTO 0) &
    CC(' ') &
    '0' & hitbo(7 DOWNTO 4) &
    '0' & hitbo(3 DOWNTO 0) &
    CS("          ");
  
  ovo_ena<='1'; --status(2);
  
  ----------------------------------------------------------
  reset_na<=btn_n_i(1) AND pll_locked AND NOT ioctl_download AND NOT map_reset;
  
    	keyboard : work.io_ps2_keyboard
	port map
	(
		clk       => clksys,
		kbd_clk   => ps2_clk_io,
		kbd_dat   => ps2_data_io,
		interrupt => kbd_intr,
		scancode  => kbd_scancode
	);

	k_joystick : work.kbd_joystick
	port map
	(
		clk        	=> clksys,
		kbdint     	=> kbd_intr,
		kbdscancode	=> kbd_scancode, 
		
		joystick_0 	=> joy1_p6_i & joy1_p9_i & joy1_up_i & joy1_down_i & joy1_left_i & joy1_right_i,
		joystick_1 	=> joy2_p6_i & joy2_p9_i & joy2_up_i & joy2_down_i & joy2_left_i & joy2_right_i,

		joyswap 		=> '0',
		oneplayer	=> '0',
		
		controls		=> controls_s,
		
		-- fire12-1, up, down, left, right
		player1		=> JoyKeys,
		player2		=> open,

		osd_o		   => osd_s,
		
		osd_enable	=> osd_enable,
		
		sega_clk  	=> vga_hs_s,
		sega_strobe	=> joyX_p7_o
		
	);
  
  ----------------------------------------------------------
  KeyCodes:PROCESS (clksys,reset_na) IS
  BEGIN
    IF reset_na='0' THEN
         key_0<='0';  key_1<='0';  key_2<='0';  key_3<='0';  key_4<='0';
         key_5<='0';  key_6<='0';  key_7<='0';  key_8<='0';  key_9<='0';
         key_a<='0';  key_b<='0';  key_c<='0';  key_d<='0';  key_e<='0';  key_f<='0';
         key_g<='0';  key_h<='0';  key_i<='0';  key_j<='0';  key_k<='0';  key_l<='0';
         key_m<='0';  key_n<='0';  key_o<='0';  key_p<='0';  key_q<='0';  key_r<='0';
         key_s<='0';  key_t<='0';  key_u<='0';  key_v<='0';  key_w<='0';  key_x<='0';
         key_y<='0';  key_z <='0';
         key_space<='0'; key_colon<='0'; key_period<='0'; key_comma <='0';
         key_up<='0';    key_down<='0';  key_right<='0';  key_left <='0';
         key_enter<='0'; key_esc<='0';   key_lshift<='0'; key_rshift<='0';
         key_lctrl<='0'; key_rctrl<='0';
			
         key_backspace <='0'; 
         
         
    ELSIF rising_edge(clksys) THEN
      IF kbd_intr = '1' THEN
		
			if kbd_scancode = "11110000" then IsReleased <= '1'; else IsReleased <= '0'; end if;
			
        CASE kbd_scancode(7 DOWNTO 0) IS
          WHEN x"45" => key_0 <=  not(IsReleased);
          WHEN x"16" => key_1 <=  not(IsReleased);
          WHEN x"1E" => key_2 <=  not(IsReleased);
          WHEN x"26" => key_3 <=  not(IsReleased);
          WHEN x"25" => key_4 <=  not(IsReleased);
          WHEN x"2E" => key_5 <=  not(IsReleased);
          WHEN x"36" => key_6 <=  not(IsReleased);
          WHEN x"3D" => key_7 <=  not(IsReleased);
          WHEN x"3E" => key_8 <=  not(IsReleased);
          WHEN x"46" => key_9 <=  not(IsReleased);
			 
          WHEN x"1C" => key_a<= not (IsReleased);
          WHEN x"32" => key_b<= not (IsReleased);
          WHEN x"21" => key_c<= not (IsReleased);
          WHEN x"23" => key_d<= not (IsReleased);
          WHEN x"24" => key_e<= not (IsReleased);
          WHEN x"2B" => key_f<= not (IsReleased);
          WHEN x"34" => key_g<= not (IsReleased);
          WHEN x"33" => key_h<= not (IsReleased);
          WHEN x"43" => key_i<= not (IsReleased);
          WHEN x"3B" => key_j<= not (IsReleased);
          WHEN x"42" => key_k<= not (IsReleased);
          WHEN x"4B" => key_l<= not (IsReleased);
          WHEN x"3A" => key_m<= not (IsReleased);
          WHEN x"31" => key_n<= not (IsReleased);
          WHEN x"44" => key_o<= not (IsReleased);
          WHEN x"4D" => key_p<= not (IsReleased);
          WHEN x"15" => key_q<= not (IsReleased);
          WHEN x"2D" => key_r<= not (IsReleased);
          WHEN x"1B" => key_s<= not (IsReleased);
          WHEN x"2C" => key_t<= not (IsReleased);
          WHEN x"3C" => key_u<= not (IsReleased);
          WHEN x"2A" => key_v<= not (IsReleased);
          WHEN x"1D" => key_w<= not (IsReleased);
          WHEN x"22" => key_x<= not (IsReleased);
          WHEN x"35" => key_y<= not (IsReleased);
          WHEN x"1A" => key_z<= not (IsReleased); 
			 
			 WHEN x"29" => key_space <= not (IsReleased);
          WHEN x"5A" => key_enter <= not (IsReleased);
          WHEN x"27" => key_colon <= not (IsReleased);
          WHEN x"49" => key_period<= not (IsReleased);
          WHEN x"41" => key_comma <= not (IsReleased);
          WHEN x"63" => key_up	 <= not (IsReleased);
          WHEN x"60" => key_down  <= not (IsReleased);
          WHEN x"6A" => key_right <= not (IsReleased);
          WHEN x"61" => key_left  <= not (IsReleased);
          WHEN x"08" => key_esc   <= not (IsReleased);
          WHEN x"12" => key_lshift<= not (IsReleased);
          WHEN x"59" => key_rshift<= not (IsReleased);
          WHEN x"11" => key_lctrl <= not (IsReleased);
          WHEN x"58" => key_rctrl <= not (IsReleased);			 
			 			 
          WHEN x"66" => key_backspace  <= not(IsReleased);

          WHEN OTHERS => NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS KeyCodes;
  
  ----------------------------------------------------------
  -- OLD ROM LOADER
--    icart:PROCESS(clksys) IS
--  BEGIN
--    IF rising_edge(clksys) THEN
--      -- Download
--      IF w_wrl='1' THEN
--        cartl(to_integer(w_a))<=w_d;
--      END IF;
--      IF w_wrh='1' THEN
--        carth(to_integer(w_a))<=w_d;
--      END IF;
--    END IF;
--  END PROCESS icart;
--  
--  PROCESS(clksys) IS
--  BEGIN
--    IF rising_edge(clksys) THEN
--      w_wrl<=ioctl_download AND ioctl_wr;-- AND     ioctl_addr(0);
--      w_wrh<=ioctl_download AND ioctl_wr AND NOT ioctl_addr(0);
--      w_d <=unsigned(ioctl_dout);
--	   w_a <=unsigned(ioctl_addr(14 DOWNTO 0));
--    END IF;
--  END PROCESS;
  
 -- ROM reading 
--  rom_dr<=carth(to_integer(cad(14 DOWNTO 0))) &
--          cartl(to_integer(cad(14 DOWNTO 0))) WHEN rising_edge(clksys);
		
		
  ----------------------------------------------------------
  -- LOADER
  
	sram2_oe_n_o <= '0';
	sram3_oe_n_o <= '0';
	
	sram2_addr_o <= std_logic_vector(ioctl_addr(18 downto 0)) when ioctl_download = '1' else "0000" & std_logic_vector(cad(14 DOWNTO 0));
	sram3_addr_o <= std_logic_vector(ioctl_addr(18 downto 0)) when ioctl_download = '1' else "0000" & std_logic_vector(cad(14 DOWNTO 0));
	
	sram2_we_n_o <= not ioctl_wr;
	sram3_we_n_o <= not ioctl_wr;

	sram2_data_io <= dio_data( 7 downto 0) when ioctl_wr = '1' else (others=>'Z');
	sram3_data_io <= dio_data(15 downto 8) when ioctl_wr = '1' else (others=>'Z');
			
	rom_dr(15 downto 8) <= unsigned(sram3_data_io) WHEN rising_edge(clksys); -- high byte
	rom_dr( 7 downto 0) <= cartl(to_integer(cad(14 DOWNTO 0))) WHEN rising_edge(clksys); -- low byte
   --rom_dr( 7 downto 0) <= unsigned(sram2_data_io) WHEN rising_edge(clksys); -- low byte
			 
  

  PROCESS(clksys) IS
  BEGIN
    IF rising_edge(clksys) THEN

		if (host_reset_loader = '1') then
			bootdata_ack <= '0';
			boot_state <= "0000";

			bytesloaded <= (others=>'0');
			
			ioctl_download <= '0';
			ioctl_addr <= (others=>'0');
			ioctl_wr <= '0';

		else


			case boot_state is
			
			when	"0000" => --ack
					if (bootdata_req = '1') then
								
								
								boot_state <= "0001"; 
								ioctl_download <= '1';
					
					else 
						
						--	ioctl_download <= '0';
							bootdata_ack <= '0';
							
							if (bytesloaded >= unsigned(rom_size) and (unsigned(rom_size) > 0)) then 
								boot_state <= "1111";
							end if;
					end if;
						
				when "0001" => --read 1. word
						
								bootdata_ack <= '1';
								data <= bootdata; --save a copy
								dio_data <= bootdata(31 downto 16);
								ioctl_wr <= '0';
								
							
								
								if (bytesloaded < unsigned(rom_size))  then
									boot_state <= "0010"; --still more bytes to transfer
								else
									boot_state <= "1111"; --end
								
								end if;
								
						
						
				when "0010" => --write 1. word
						cartl(to_integer(unsigned(ioctl_addr(14 downto 0)))) <= unsigned(dio_data( 7 downto 0));
						--carth(to_integer(unsigned(ioctl_addr(14 downto 0)))) <= unsigned(dio_data(15 downto 8));
						
					   bootdata_ack <= '0';
						ioctl_wr <= '1';
						bytesloaded <= bytesloaded + 2;
						
						boot_state <= "0011";
			
					
				when "0011" => --wait state
				
						boot_state <= "0100";
			
					
				when "0100" => --wait state
				
						boot_state <= "0101";
				
					
				when "0101" => --clear the write signal
			
						ioctl_wr <= '0';
						ioctl_addr <= ioctl_addr + 1;
						dio_data <= data(15 downto 0); --prepare the 2. word (from the copy)
						boot_state <= "0110";
					
				when "0110" => --write 2. word
						cartl(to_integer(unsigned(ioctl_addr(14 downto 0)))) <= unsigned(dio_data( 7 downto 0));
						--carth(to_integer(unsigned(ioctl_addr(14 downto 0)))) <= unsigned(dio_data(15 downto 8));
						
						ioctl_wr <= '1';
						bytesloaded <= bytesloaded + 2;
						boot_state <= "0111";
				
					
				when "0111" => --wait state
			
						boot_state <= "1000";
			
					
				when "1000" => --wait state
		
						boot_state <= "1001";
			
					
				when "1001" => --clear the write signal and loop
			
						ioctl_wr <= '0';
						ioctl_addr <= ioctl_addr + 1;
						boot_state <= "0000";
			
					
				when "1111" => --END
		
						ioctl_download <= '0';
						bootdata_ack <= '0';
		
				when others => NULL;
					
			end case;
		end if;
	end if;
	END process;
	
	  debounce_nmi : entity work.debounce
  GENERIC map
  (
    counter_size  => 8
  )
  PORT map
  (
    clk_i     => clksys,
    button_i  => controls_s(1),
    result_o  => btn_scandb_s    
	);
	
	process(btn_scandb_s)
	begin
		if rising_edge(btn_scandb_s) then
			scandblctrl <= not scandblctrl;
		end if;
	end process;
	
	
end architecture;