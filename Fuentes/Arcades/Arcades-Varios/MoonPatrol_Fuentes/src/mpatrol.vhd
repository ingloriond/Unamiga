library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.pace_pkg.all;
use work.video_controller_pkg.all;

entity mpatrol is
  port
    (
      CLOCK_27      	: in std_logic;

		LED_Y 				: out std_logic;
		LED_R 				: out std_logic;

      AUDIO_L        : out std_logic;
      AUDIO_R        : out std_logic;
      VGA_VS        	: out std_logic;
      VGA_HS        	: out std_logic;
      VGA_R         	: out std_logic_vector(5 downto 0);
      VGA_G         	: out std_logic_vector(5 downto 0);
      VGA_B         	: out std_logic_vector(5 downto 0);
		
		ps2_kbd_clk : inout std_logic;
		ps2_kbd_data : inout std_logic;
		
		joystick1_up		: in std_logic;
		joystick1_down	: in std_logic;
		joystick1_left	: in std_logic;
		joystick1_right	: in std_logic;
		joystick1_fire1	: in std_logic;
		joystick1_fire2	: in std_logic;
		
		joystick2_up		: in std_logic;
		joystick2_down	: in std_logic;
		joystick2_left	: in std_logic;
		joystick2_right	: in std_logic;
		joystick2_fire1	: in std_logic;
		joystick2_fire2	: in std_logic
  );    
  
end mpatrol;

architecture SYN of mpatrol is

  signal   SPI_SCK 			: std_logic;
  signal    SPI_DI 			: std_logic;
  signal SPI_SS2 			: std_logic;
  signal	SPI_SS3 			: std_logic;
  signal	SPI_SS4 			: std_logic;
  signal   SPI_DO 			: std_logic;
  signal    CONF_DATA0 		: std_logic;
  signal init       		: std_logic := '1';  
  signal clk_sys        : std_logic;
  signal clk_vid        : std_logic;
  signal clk_osd			: std_logic;  
  signal clkrst_i       : from_CLKRST_t;
  signal buttons_i      : from_BUTTONS_t;
  signal switches_i     : from_SWITCHES_t;
  signal leds_o         : to_LEDS_t;
  signal inputs_i       : from_INPUTS_t;
  signal video_i        : from_VIDEO_t;
  signal video_o        : to_VIDEO_t;
  --MIST
  signal audio       	: std_logic;
  signal status     		: std_logic_vector(31 downto 0); 
  signal joystick1      : std_logic_vector(7 downto 0);
  signal joystick2      : std_logic_vector(7 downto 0);
  signal kbd_joy 			: std_logic_vector(9 downto 0);	 
  signal switches       : std_logic_vector(1 downto 0);
  signal buttons        : std_logic_vector(1 downto 0);
  signal scan_disable   : std_logic;
  signal ypbpr   			: std_logic;
  signal r  				: std_logic_vector(5 downto 0);
  signal g  				: std_logic_vector(5 downto 0);
  signal b  				: std_logic_vector(5 downto 0);
  signal hs 				: std_logic;
  signal vs 				: std_logic;  
  signal reset 			: std_logic;  
  signal clock_3p58 		: std_logic;
  signal audio_out 		: std_logic_vector(11 downto 0);
  signal sound_data     : std_logic_vector(7 downto 0);
  
component keyboard
   port  (
		clk						:in STD_LOGIC;
		reset						:in STD_LOGIC;
		ps2_kbd_clk				:in STD_LOGIC;
		ps2_kbd_data			:in STD_LOGIC;
		joystick					:out STD_LOGIC_VECTOR(9 downto 0));
end component;
  
component mist_io
   port  (
		clk_sys 					:in STD_LOGIC;
      SPI_SCK 					:in STD_LOGIC;
      CONF_DATA0 				:in STD_LOGIC;
      SPI_DI 					:in STD_LOGIC;
      SPI_DO 					:out STD_LOGIC;
		SPI_SS2					:in STD_LOGIC;
      switches 				:out STD_LOGIC_VECTOR(1 downto 0);
      buttons  				:out STD_LOGIC_VECTOR(1 downto 0);
		scan_disable  			:out STD_LOGIC;
		ypbpr  					:out STD_LOGIC;
      joystick_1  			:out STD_LOGIC_VECTOR(7 downto 0);
      joystick_0 				:out STD_LOGIC_VECTOR(7 downto 0);
      status					:out STD_LOGIC_VECTOR(31 downto 0));

end component;

component video_mist
   port  (
		clk_sys					:in STD_LOGIC;
		ce_pix					:in STD_LOGIC;
		ce_pix_actual			:in STD_LOGIC;
		SPI_SCK					:in STD_LOGIC;
		SPI_SS3					:in STD_LOGIC;
		SPI_DI					:in STD_LOGIC;
		R							:in STD_LOGIC_VECTOR(5 downto 0);
		G							:in STD_LOGIC_VECTOR(5 downto 0);
		B							:in STD_LOGIC_VECTOR(5 downto 0);
		HSync						:in STD_LOGIC;
		VSync						:in STD_LOGIC;		
		VGA_R						:out STD_LOGIC_VECTOR(5 downto 0);
		VGA_G						:out STD_LOGIC_VECTOR(5 downto 0);
		VGA_B						:out STD_LOGIC_VECTOR(5 downto 0);
		VGA_HS					:out STD_LOGIC;
		VGA_VS					:out STD_LOGIC;
		scan_disable			:in STD_LOGIC;
		scanlines				:in STD_LOGIC_VECTOR(1 downto 0);
		hq2x						:in STD_LOGIC;
		ypbpr_full				:in STD_LOGIC;
		line_start				:in STD_LOGIC;
		mono						:in STD_LOGIC);
end component;


begin
--CLOCK
Clock_inst : entity work.Clock
	port map (
		inclk0  			=> CLOCK_27,
		c0					=> clock_3p58,--3.58
		c1 				=> clk_osd,--10
		c2 				=> clk_sys,--30
		c3 				=> clk_vid--40
	);	

    clkrst_i.clk_ref <= CLOCK_27;
	 clkrst_i.clk(0)	<=	clk_sys;
	 clkrst_i.clk(1)	<=	clk_vid;
	 
--RESET
	process (clk_sys)
		variable count : std_logic_vector (11 downto 0) := (others => '0');
	begin
		if rising_edge(clk_sys) then
			if count = X"FFF" then
				init <= '0';
			else
				count := count + 1;
				init <= '1';
			end if;
		end if;
	end process;

  clkrst_i.arst 		<= init or status(5) or buttons(1);
  clkrst_i.arst_n 	<= not clkrst_i.arst;

  GEN_RESETS : for i in 0 to 3 generate

    process (clkrst_i)
      variable rst_r : std_logic_vector(2 downto 0) := (others => '0');
    begin
      if clkrst_i.arst = '1' then
        rst_r := (others => '1');
      elsif rising_edge(clkrst_i.clk(i)) then
        rst_r := rst_r(rst_r'left-1 downto 0) & '0';
      end if;
      clkrst_i.rst(i) <= rst_r(rst_r'left);
    end process;

  end generate GEN_RESETS;	 
	 
mist_io_inst : mist_io
   port map (
		clk_sys 			=> clk_sys,
      SPI_SCK 			=> SPI_SCK,
      CONF_DATA0 		=> CONF_DATA0,
      SPI_DI 			=> SPI_DI,
      SPI_DO 			=> SPI_DO,
		SPI_SS2			=> SPI_SS2,
      switches 		=> switches,
      buttons  		=> buttons,
		scan_disable 	=> scan_disable,
		ypbpr  			=> ypbpr,
      joystick_1  	=> joystick2,
      joystick_0 		=> joystick1,
      status			=> status
--      ps2_kbd_clk 	=> ps2_kbd_clk,
--      ps2_kbd_data	=> ps2_kbd_data
    );
	 
video_mist_inst : video_mist	 
   port map (
		clk_sys 			=> clk_sys,
		ce_pix			=> clk_osd,
		ce_pix_actual	=> clk_osd,
		SPI_SCK			=> SPI_SCK,
		SPI_SS3			=> SPI_SS3,
		SPI_DI			=> SPI_DI,
		R					=> video_o.rgb.r(9 downto 4),
		G					=> video_o.rgb.g(9 downto 4),
		B					=> video_o.rgb.b(9 downto 4),
		HSync				=> video_o.hsync,
		VSync				=> video_o.vsync,
		VGA_R				=> VGA_R,
		VGA_G				=> VGA_G,
		VGA_B				=> VGA_B,
		VGA_HS			=> VGA_HS,
		VGA_VS			=> VGA_VS,
		--ToDo
		scan_disable	=> '1',--scan_disable,
		scanlines		=> status(4 downto 3),
		hq2x				=> status(2),
		ypbpr_full		=> '1',
		line_start		=> '0',
		mono				=> '0'
	 );

    video_i.clk 		<= clk_vid;
    video_i.clk_ena 	<= '1';
    video_i.reset 	<= clkrst_i.rst(1);

		
u_keyboard : keyboard
	port  map(
		clk 				=> clk_sys,
		reset 			=> '0',
		ps2_kbd_clk 	=> ps2_kbd_clk,
		ps2_kbd_data 	=> ps2_kbd_data,
		joystick 		=> kbd_joy
);

		inputs_i.jamma_n.coin(1) <= kbd_joy(3) or status(1);--ESC
		inputs_i.jamma_n.p(1).start <= not kbd_joy(1);--TECLA 1	
		inputs_i.jamma_n.p(1).up <= joystick1_up and joystick2_up;
		inputs_i.jamma_n.p(1).down <= joystick1_down and joystick2_down;
		inputs_i.jamma_n.p(1).left <= not kbd_joy(6) and joystick1_left and joystick2_left;
		inputs_i.jamma_n.p(1).right <= not kbd_joy(7) and joystick1_right and joystick2_right;		
		inputs_i.jamma_n.p(1).button(1) <=not kbd_joy(0) and joystick1_fire1 and joystick2_fire1;--Fire
		inputs_i.jamma_n.p(1).button(2) <= not kbd_joy(4) and joystick1_fire2 and joystick2_fire2;--Jump
		inputs_i.jamma_n.p(1).button(3) <= '1';
		inputs_i.jamma_n.p(1).button(4) <= '1';
		inputs_i.jamma_n.p(1).button(5) <= '1';		
		
		inputs_i.jamma_n.p(2).start <= not kbd_joy(2);-- TECLA 2		

		inputs_i.jamma_n.p(2).button(3) <= '1';
		inputs_i.jamma_n.p(2).button(4) <= '1';
		inputs_i.jamma_n.p(2).button(5) <= '1';	

		-- not currently wired to any inputs
		inputs_i.jamma_n.coin_cnt <= (others => '1');
		inputs_i.jamma_n.coin(2) <= '1';
		inputs_i.jamma_n.service <= '1';
		inputs_i.jamma_n.tilt <= '1';
		inputs_i.jamma_n.test <= '1';

  LED_Y <= kbd_joy(3);
  LED_R <= kbd_joy(1);
  
moon_patrol_sound_board : entity work.moon_patrol_sound_board
	port map(
		clock_3p58    	=> clock_3p58,
		reset     		=> clkrst_i.arst, 
		select_sound  	=> sound_data,
		audio_out     	=> audio_out,
		dbg_cpu_addr  	=> open
	);  
  
dac : entity work.dac
   port map (
      clk_i     		=> clk_sys,
		res_n_i   		=> '1',
      dac_i   			=> audio_out,
      dac_o  			=> audio
   );
		
  AUDIO_R <= audio;
  AUDIO_L <= audio; 		
		


 pace_inst : entity work.pace                                            
   port map
   (
		clkrst_i				=> clkrst_i,
		buttons_i         => buttons_i,
		switches_i        => switches_i,
		leds_o            => open,
		inputs_i          => inputs_i,
		video_i           => video_i,
		video_o           => video_o,
		sound_data_o 		=> sound_data
    );
end SYN;
