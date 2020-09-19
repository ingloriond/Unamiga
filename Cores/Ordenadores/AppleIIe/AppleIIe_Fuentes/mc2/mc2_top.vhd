--
-- mc2_top.vhd
--
-- Apple IIe toplevel 
-- Copyright (c) 2014 W. Soltys <wsoltys@gmail.com>
--
-- This source file is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published
-- by the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This source file is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Multicore 2 top by Victor Trucco
--
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity mc2_top is

  port (
     -- Clocks
        clock_50_i          : in    std_logic;

        -- Buttons
        btn_n_i             : in    std_logic_vector(4 downto 1);

        -- SRAMs (AS7C34096)
        sram_addr_o         : out   std_logic_vector(18 downto 0)   := (others => '0');
        sram_data_io        : inout std_logic_vector(7 downto 0)    := (others => 'Z');
        sram_we_n_o         : out   std_logic                               := '1';
        sram_oe_n_o         : out   std_logic                               := '1';
        
        -- SDRAM    (H57V256)
        SDRAM_A         : out std_logic_vector(12 downto 0);
        SDRAM_DQ            : inout std_logic_vector(15 downto 0);

        SDRAM_BA            : out std_logic_vector(1 downto 0);
        SDRAM_DQMH          : out std_logic;
        SDRAM_DQML          : out std_logic;    

        SDRAM_nRAS          : out std_logic;
        SDRAM_nCAS          : out std_logic;
        SDRAM_CKE           : out std_logic;
        SDRAM_CLK           : out std_logic;
        SDRAM_nCS           : out std_logic;
        SDRAM_nWE           : out std_logic;
    
        -- PS2
        ps2_clk_io          : inout std_logic                               := 'Z';
        ps2_data_io         : inout std_logic                               := 'Z';
        ps2_mouse_clk_io  : inout std_logic                             := 'Z';
        ps2_mouse_data_io : inout std_logic                             := 'Z';

        -- SD Card
        sd_cs_n_o           : out   std_logic                               := 'Z';
        sd_sclk_o           : out   std_logic                               := 'Z';
        sd_mosi_o           : out   std_logic                               := 'Z';
        sd_miso_i           : in    std_logic;

        -- Joysticks
        joy1_up_i           : in    std_logic;
        joy1_down_i         : in    std_logic;
        joy1_left_i         : in    std_logic;
        joy1_right_i        : in    std_logic;
        joy1_p6_i           : in    std_logic;
        joy1_p9_i           : in    std_logic;
        joyX_p7_o           : out   std_logic                               := '1';       
        
        -- joystick 2 as SDISKII 
        joy2_up_i           : out    std_logic;
        joy2_down_i         : out    std_logic;
        joy2_left_i         : out    std_logic;
        joy2_right_i        : out    std_logic;
        joy2_p6_i           : out    std_logic;
        joy2_p9_i           : out    std_logic;


        -- Audio
        AUDIO_L             : out   std_logic                               := '0';
        AUDIO_R             : out   std_logic                               := '0';
        ear_i                   : in    std_logic;
        mic_o                   : out   std_logic                               := '0';

        -- VGA
        VGA_R               : out   std_logic_vector(4 downto 0)    := (others => '0');
        VGA_G               : out   std_logic_vector(4 downto 0)    := (others => '0');
        VGA_B               : out   std_logic_vector(4 downto 0)    := (others => '0');
        VGA_HS      : out   std_logic                               := '1';
        VGA_VS      : out   std_logic                               := '1';

        -- HDMI
        tmds_o              : out   std_logic_vector(7 downto 0)    := (others => '0');

        --STM32
        stm_rx_o                : out std_logic     := 'Z'; -- stm RX pin, so, is OUT on the slave
        stm_tx_i                : in  std_logic     := 'Z'; -- stm TX pin, so, is IN on the slave
        stm_rst_o           : out std_logic     := 'Z'; -- '0' to hold the microcontroller reset line, to free the SD card
        
        stm_a15_io          : inout std_logic;
        stm_b8_io           : inout std_logic       := 'Z';
        stm_b9_io           : inout std_logic       := 'Z';
        
        SPI_SCK         : inout std_logic       := 'Z';
        SPI_DO          : inout std_logic       := 'Z';
        SPI_DI          : inout std_logic       := 'Z';
        SPI_SS2         : inout std_logic       := 'Z'
        

    );
  
end mc2_top;

architecture datapath of mc2_top is





  function to_slv(s: string) return std_logic_vector is 
    constant ss: string(1 to s'length) := s; 
    variable rval: std_logic_vector(1 to 8 * s'length); 
    variable p: integer; 
    variable c: integer; 
  
  begin 
    for i in ss'range loop
      p := 8 * i;
      c := character'pos(ss(i));
      rval(p - 7 to p) := std_logic_vector(to_unsigned(c,8)); 
    end loop; 
    return rval; 

  end function; 

      constant CONF_STR       : string := 

        "S,NIB,Load *.NIB;"& 
        "O3,Drive step sound,Off,On;"&
        "OAB,Scanlines,Off,25%,50%,75%;"&
        "T1,Soft Reset;"&
        "T0,Hard Reset;"& 
        ".";
  
    type config_array is array(natural range 15 downto 0) of std_logic_vector(7 downto 0);


  
    component osd is
        generic
        (
            STRLEN       : integer := 0;
            OSD_X_OFFSET : std_logic_vector(9 downto 0) := (others=>'0');
            OSD_Y_OFFSET : std_logic_vector(9 downto 0) := (others=>'0');
            OSD_COLOR    : std_logic_vector(2 downto 0) := (others=>'0')
        );
        port
        (
            -- OSDs pixel clock, should be synchronous to cores pixel clock to
            -- avoid jitter.
            pclk        : in std_logic;

            -- SPI interface
            sck     : in std_logic;
            ss          : in std_logic;
            sdi     : in std_logic;
            sdo     : out std_logic;

            -- VGA signals coming from core
            red_in  : in std_logic_vector(4 downto 0);
            green_in : in std_logic_vector(4 downto 0);
            blue_in     : in std_logic_vector(4 downto 0);
            hs_in       : in std_logic;
            vs_in       : in std_logic;
            
            -- VGA signals going to video connector
            red_out : out std_logic_vector(4 downto 0);
            green_out: out std_logic_vector(4 downto 0);
            blue_out    : out std_logic_vector(4 downto 0);
            hs_out  : out std_logic;
            vs_out  : out std_logic;
            
            -- external data in to the microcontroller
            data_in     : in std_logic_vector(7 downto 0);
            conf_str : in std_logic_vector( (CONF_STR'length * 8)-1 downto 0);
            menu_in : in std_logic;
            status  : out std_logic_vector(31 downto 0);
            mc_ack  : out std_logic;
            reset   : in std_logic;
            
            -- data pump to sram
            pump_active_o   : out std_logic := '0';
            sram_a_o        : out std_logic_vector(18 downto 0);
            sram_d_o        : out std_logic_vector(7 downto 0);
            sram_we_n_o     : out std_logic := '1';
            
            config_buffer_o: out config_array;

            osd_enable      : out std_logic;
            img_counter     : out unsigned(9 downto 0)
        );
        end component;
  

    component video
        generic (
        SD_HCNT_WIDTH: integer := 9;
        COLOR_DEPTH  : integer := 6
        );
        port (
        clk_sys     : in std_logic;

        scanlines   : in std_logic_vector(1 downto 0);
        ce_divider  : in std_logic := '0';
        scandoubler_disable : in std_logic;

        HSync       : in std_logic;
        VSync       : in std_logic;
        R           : in std_logic_vector(COLOR_DEPTH-1 downto 0);
        G           : in std_logic_vector(COLOR_DEPTH-1 downto 0);
        B           : in std_logic_vector(COLOR_DEPTH-1 downto 0);

        VGA_HS      : out std_logic;
        VGA_VS      : out std_logic;
        VGA_R       : out std_logic_vector(5 downto 0);
        VGA_G       : out std_logic_vector(5 downto 0);
        VGA_B       : out std_logic_vector(5 downto 0)
        );
    end component video;

  component sdram is
    port( sd_data : inout std_logic_vector(15 downto 0);
          sd_addr : out std_logic_vector(12 downto 0);
          sd_dqm : out std_logic_vector(1 downto 0);
          sd_ba : out std_logic_vector(1 downto 0);
          sd_cs : out std_logic;
          sd_we : out std_logic;
          sd_ras : out std_logic;
          sd_cas : out std_logic;
          init : in std_logic;
          clk : in std_logic;
          clkref : in std_logic;
          din : in std_logic_vector(7 downto 0);
          dout : out std_logic_vector(15 downto 0);
          aux : in std_logic;
          addr : in std_logic_vector(24 downto 0);
          we : in std_logic
    );
  end component;

  signal CLK_28M, CLK_14M, CLK_2M, CLK_2M_D, PHASE_ZERO : std_logic;
  signal clk_div : unsigned(1 downto 0);
  signal IO_SELECT, DEVICE_SELECT : std_logic_vector(7 downto 0);
  signal ADDR : unsigned(15 downto 0);
  signal D, PD: unsigned(7 downto 0);
  signal DISK_DO, PSG_DO : unsigned(7 downto 0);
  signal DO : std_logic_vector(15 downto 0);
  signal aux : std_logic;
  signal cpu_we : std_logic;
  signal psg_irq_n, psg_nmi_n : std_logic;

  signal we_ram : std_logic;
  signal VIDEO_S, HBL, VBL : std_logic;
  signal COLOR_LINE : std_logic;
  signal COLOR_LINE_CONTROL : std_logic;
  signal SCREEN_MODE : std_logic_vector(1 downto 0);
  signal GAMEPORT : std_logic_vector(7 downto 0);
  signal scandoubler_disable : std_logic;
  signal ypbpr : std_logic;

  signal K : unsigned(7 downto 0);
  signal K_s : unsigned(7 downto 0);
  signal read_key : std_logic;
  signal akd : std_logic;

  signal flash_clk : unsigned(22 downto 0) := (others => '0');
  signal power_on_reset : std_logic := '1';
  signal reset : std_logic;

  signal D1_ACTIVE, D2_ACTIVE : std_logic;
  signal track_addr : unsigned(13 downto 0);
  signal TRACK_RAM_ADDR : unsigned(12 downto 0);
  signal TRACK_RAM_DI : unsigned(7 downto 0);
  signal TRACK_RAM_WE : std_logic;
  signal track : unsigned(5 downto 0);
  signal disk_change : std_logic;

  signal downl : std_logic := '0';
  signal io_index : std_logic_vector(4 downto 0);
  signal size : std_logic_vector(24 downto 0) := (others=>'0');
  signal a_ram: unsigned(17 downto 0);
  signal r : unsigned(7 downto 0);
  signal g : unsigned(7 downto 0);
  signal b : unsigned(7 downto 0);
  signal hsync : std_logic;
  signal vsync : std_logic;
  signal sd_we : std_logic;
  signal sd_oe : std_logic;
  signal sd_addr : std_logic_vector(18 downto 0);
  signal sd_di : std_logic_vector(7 downto 0);
  signal sd_do : std_logic_vector(7 downto 0);
  signal io_we : std_logic;
  signal io_addr : std_logic_vector(24 downto 0);
  signal io_do : std_logic_vector(7 downto 0);
  signal io_ram_we : std_logic;
  signal io_ram_d : std_logic_vector(7 downto 0);
  signal io_ram_addr : std_logic_vector(18 downto 0);
  signal ram_we : std_logic;
  signal ram_di : std_logic_vector(7 downto 0);
  signal ram_addr : std_logic_vector(24 downto 0);
  
  signal switches   : std_logic_vector(1 downto 0);
  signal buttons    : std_logic_vector(1 downto 0);
  signal joy        : std_logic_vector(5 downto 0);
  signal joy0       : std_logic_vector(31 downto 0);
  signal joy1       : std_logic_vector(31 downto 0);
  signal joy_an0    : std_logic_vector(15 downto 0);
  signal joy_an1    : std_logic_vector(15 downto 0);
  signal joy_an     : std_logic_vector(15 downto 0);
  signal status     : std_logic_vector(31 downto 0);
  signal ps2Clk     : std_logic;
  signal ps2Data    : std_logic;
  
  signal psg_audio_l : unsigned(9 downto 0);
  signal psg_audio_r : unsigned(9 downto 0);
  signal audio       : std_logic;

  -- signals to connect sd card emulation with io controller
  signal sd_lba:  std_logic_vector(31 downto 0);
  signal sd_rd:   std_logic;
  signal sd_wr:   std_logic;
  signal sd_ack:  std_logic;
  
  -- data from io controller to sd card emulation
  signal sd_data_in: std_logic_vector(7 downto 0);
  signal sd_data_out: std_logic_vector(7 downto 0);
  signal sd_data_out_strobe:  std_logic;
  signal sd_buff_addr: std_logic_vector(8 downto 0);
  
  -- sd card emulation
  signal sd_cs: std_logic;
  signal sd_sck:    std_logic;
  signal sd_sdi:    std_logic;
  signal sd_sdo:    std_logic;
  
  signal pll_locked : std_logic;
  signal sdram_dqm: std_logic_vector(1 downto 0);
  signal joyx       : std_logic;
  signal joyy       : std_logic;
  signal pdl_strobe : std_logic;


  signal cold_reset_s : std_logic;
  
  --
  signal clock_dvi_s          : std_logic;
  signal vga_hsync_n_s        : std_logic;
  signal vga_vsync_n_s        : std_logic;
  signal vga_blank_s          : std_logic;

  signal vga_r_s              : std_logic_vector( 4 downto 0);
  signal vga_g_s              : std_logic_vector( 4 downto 0);
  signal vga_b_s              : std_logic_vector( 4 downto 0);

  signal osd_r_s       : std_logic_vector(4 downto 0); 
  signal osd_g_s       : std_logic_vector(4 downto 0); 
  signal osd_b_s       : std_logic_vector(4 downto 0); 
  signal osd_enable_s  : std_logic;

  signal color_15      : std_logic_vector (3 downto 0) := (others=>'0');
  signal color_index   : std_logic_vector (3 downto 0) := (others=>'0');
    
  signal scanlines_en_s : std_logic_vector(1 downto 0);

  signal osd_green_s : std_logic_vector(4 downto 0);
  signal osd_pixel_s : std_logic;
  signal osd_visible_s : std_logic;
  signal timer_osd_s      : unsigned(21 downto 0)             := (others => '1');

  constant STRLEN     : integer := 0;
  signal menu_status : std_logic_vector(31 downto 0); 
  signal mc_ack : std_logic := '0';
  signal odd_line_s : std_logic := '0';

  signal clock_div_q  : unsigned(7 downto 0)              := (others => '0');
  signal keys_s           : std_logic_vector( 7 downto 0) := (others => '1');     
  signal osd_s            : std_logic_vector( 7 downto 0) := (others => '1'); 
  signal loader_s     : std_logic_vector( 7 downto 0) := "00111111"; --send the signal to open the loader on init 

  signal pump_active_s    : std_logic                             := '0';
  signal sram_we_s    : std_logic                             := '1';
  signal sram_addr_s  : std_logic_vector (18 downto 0) := (others=>'1');
  signal sram_data_s  : std_logic_vector (7 downto 0) := (others=>'0');
  signal power_on_s       : std_logic_vector(15 downto 0) := (others => '1');
  signal addr_desloc  : std_logic_vector(15 downto 0) := (others => '0'); 

  -- 
  signal disk_addr_s  : std_logic_vector (18 downto 0) := (others=>'0');
  signal disk_data_s  : std_logic_vector (7 downto 0) := (others=>'0');

  signal motor_phase_s : std_logic_vector (3 downto 0) := (others=>'0');
  signal drive_en_s    : std_logic;
  signal rd_pulse_s    : std_logic;

  signal img_counter_s : unsigned (9 downto 0) := (others=>'0');

begin

    stm_rst_o <= 'Z';           

  -- In the Apple ][, this was a 555 timer
  power_on : process(CLK_14M)
  begin
         if rising_edge(CLK_14M) then
                reset <=  power_on_reset;
                cold_reset_s <= not btn_n_i(3);

                if btn_n_i(4) = '0' or cold_reset_s = '1' then
                      power_on_reset <= '1';
                      flash_clk <= (others=>'0');
                else
                      if flash_clk(22) = '1' then
                            power_on_reset <= '0';
                      end if;
                         
                      flash_clk <= flash_clk + 1;
                end if;
            
         end if;
  end process;
  

  
  pll : entity work.pll 
  port map (
    areset => '0',
    inclk0 => clock_50_i,
    c0     => CLK_28M,
    c1     => CLK_14M,
    c2     => clock_dvi_s,
    locked => pll_locked
    );

 
  -- Paddle buttons
  -- GAMEPORT input bits:
  --  7    6    5    4    3   2   1    0
  -- pdl3 pdl2 pdl1 pdl0 pb3 pb2 pb1 casette
  --GAMEPORT <=  "00" & joyy & joyx & "0" & joy(5) & joy(4) & '0';--UART_RX;
  --GAMEPORT <=  "00000000";
  
  GAMEPORT <=  "00" & joyy & joyx & '0' & not joy1_p9_i & not joy1_p6_i & '0';
  
  joy_an <= joy_an0 when status(5)='0' else joy_an1;
  joy <= joy1_p9_i & joy1_p6_i & joy1_right_i & joy1_left_i & joy1_down_i & joy1_up_i when status(5)='0' else 
         joy1_p9_i & joy1_p6_i & joy1_right_i & joy1_left_i & joy1_down_i & joy1_up_i;
--          joy2_p9_i & joy2_p6_i & joy2_right_i & joy2_left_i & joy2_down_i & joy2_up_i;
  
  process(CLK_14M, pdl_strobe)
    variable cx, cy : integer range -100 to 5800 := 0;
  begin
  
         if rising_edge(CLK_14M) then
         
                CLK_2M_D <= CLK_2M;
          
              if CLK_2M_D = '0' and CLK_2M = '1' then
              
                    if cx > 0 then
                      cx := cx -1;
                      joyx <= '1';
                    else
                      joyx <= '0';
                    end if;
                    
                    if cy > 0 then
                      cy := cy -1;
                      joyy <= '1';
                    else
                      joyy <= '0';
                    end if;
                    
                    if pdl_strobe = '1' then
                            cx := 2800;
                            
                            if joy1_right_i = '0' then 
                                cx := 5000; 
                            elsif joy1_left_i = '0' then 
                                cx := 0; 
                            end if;
                            
                            cy := 2800;
                            
                            if joy1_down_i = '0' then 
                                cy := 5000;
                            elsif joy1_up_i = '0' then 
                                cy :=  0;
                            end if;
                            
                          if cx < 0 then
                             cx := 0;
                          elsif cx >= 5590 then
                             cx := 5650;
                          end if;
                          
                          if cy < 0 then
                             cy := 0;
                          elsif cy >= 5590 then
                             cy := 5650;
                          end if;
                          
                    end if;
                
              end if;
              
         end if;
     
  end process;

  COLOR_LINE_CONTROL <= COLOR_LINE; -- and not (status(2) or status(3));  -- Color or B&W mode
  SCREEN_MODE <= "00"; --status(3 downto 2); -- 00: Color, 01: B&W, 10:Green, 11: Amber
  
  -- sdram interface
  SDRAM_CLK <= CLK_28M;
  SDRAM_CKE <= '1';

  sdram_inst : sdram
    port map( sd_data => SDRAM_DQ,
              sd_addr => SDRAM_A,
              sd_dqm(0) => SDRAM_DQML,
              sd_dqm(1) => SDRAM_DQMH,
              sd_cs => SDRAM_nCS,
              sd_ba => SDRAM_BA,
              sd_we => SDRAM_nWE,
              sd_ras => SDRAM_nRAS,
              sd_cas => SDRAM_nCAS,
              clk => CLK_28M,
              clkref => CLK_2M,
              init => not pll_locked,
              din => ram_di,
              addr => ram_addr,
              we => ram_we,
              dout => DO,
              aux => aux
    );
  
  -- Simulate power up on cold reset to go to the disk boot routine
  ram_we   <= we_ram when cold_reset_s = '0' else '1';
  ram_addr <= "0000000" & std_logic_vector(a_ram) when cold_reset_s = '0' else std_logic_vector(to_unsigned(1012,ram_addr'length)); -- $3F4
  ram_di   <= std_logic_vector(D) when cold_reset_s = '0' else "00000000";

  PD <= PSG_DO when IO_SELECT(4) = '1' else DISK_DO;

  core : entity work.apple2 port map (
    CLK_14M        => CLK_14M,
    CLK_2M         => CLK_2M,
    PHASE_ZERO     => PHASE_ZERO,
    FLASH_CLK      => flash_clk(22),
    reset          => reset, --input
    cpu            => '0', --status(1), -- 0 - 6502, 1 - 65C02
    ADDR           => ADDR, --output
    ram_addr       => a_ram,
    D              => D, -- output Data to RAM
    ram_do         => unsigned(DO),
    aux            => aux, -- (buffer)  Write to MAIN or AUX RAM
    PD             => PD,
    CPU_WE         => cpu_we,
    IRQ_N          => psg_irq_n, -- input
    NMI_N          => psg_nmi_n, -- input
    ram_we         => we_ram,
    VIDEO          => VIDEO_S,
    COLOR_LINE     => COLOR_LINE,
    HBL            => HBL,
    VBL            => VBL,
    K              => K_s,
    KEYSTROBE      => read_key,
    AKD            => akd,
    AN             => open,
    GAMEPORT       => GAMEPORT,
    PDL_strobe     => pdl_strobe,
    IO_SELECT      => IO_SELECT,
    DEVICE_SELECT  => DEVICE_SELECT,
    speaker        => audio
    );

  K_s <= (others=>'0') when osd_enable_s = '1' else K;

  tv : entity work.tv_controller port map (
    CLK_14M    => CLK_14M,
    VIDEO      => VIDEO_S,
    COLOR_LINE => COLOR_LINE_CONTROL,
    SCREEN_MODE => SCREEN_MODE,
    HBL        => HBL,
    VBL        => VBL,
    VGA_CLK    => open,
    VGA_HS     => hsync,
    VGA_VS     => vsync,
    VGA_BLANK  => open,
    VGA_R      => r,
    VGA_G      => g,
    VGA_B      => b,
    color_index => color_15,
    vga_odd_line_o => odd_line_s
    );

  keyboard : entity work.keyboard port map (
    PS2_Clk  => ps2_clk_io,
    PS2_Data => ps2_data_io,
    CLK_14M  => CLK_14M,
    reset    => reset,
    reads    => read_key,
    K        => K,
    akd      => akd,
     osd_o   => osd_s
    );

    disk : entity work.disk_ii port map 
    (
        CLK_14M        => CLK_14M,
        CLK_2M         => CLK_2M,
        PHASE_ZERO     => PHASE_ZERO,

        IO_SELECT      => IO_SELECT(6),
        DEVICE_SELECT  => DEVICE_SELECT(6),

        RESET          => reset,
        A              => ADDR,
        D_IN           => D,
        D_OUT          => DISK_DO,

        TRACK          => TRACK,          -- output
        TRACK_ADDR     => TRACK_ADDR,     -- output
        D1_ACTIVE      => D1_ACTIVE,      -- output
        D2_ACTIVE      => D2_ACTIVE,      -- output

        ram_write_addr => TRACK_RAM_ADDR, -- input
        ram_di         => TRACK_RAM_DI,   -- input
        ram_we         => TRACK_RAM_WE,   -- input

        --------------------------------------------------------------------------------
        motor_phase_o  => motor_phase_s,
        drive_en_o     => drive_en_s,
        rd_pulse_o     => rd_pulse_s 
    );


    joy2_right_i <= motor_phase_s(3);
    joy2_left_i  <= motor_phase_s(2);
    joy2_down_i  <= motor_phase_s(1);
    joy2_up_i    <= motor_phase_s(0);

    joy2_p6_i    <= drive_en_s;
 --    joy2_p9_i    <= rd_pulse_s;

  --LED <= not (D1_ACTIVE or D2_ACTIVE);
  
    image_ctrl : work.image_controller 
    port map
    (
      
        -- System Interface -------------------------------------------------------
        CLK_14M         => CLK_14M,
        reset           => reset,     
  
         -- SRAM Interface ---------------------------------------------------------
         buffer_addr_i  => disk_addr_s, 
         buffer_data_i  => disk_data_s,
         
         -- Track buffer Interface -------------------------------------------------
         unsigned(ram_write_addr)  => TRACK_RAM_ADDR,   -- out
         unsigned(ram_di)          => TRACK_RAM_DI,     -- out
         ram_we                    => TRACK_RAM_WE,     -- out
         track                     => TRACK,
         image                     => img_counter_s

    );

 

    mb : work.mockingboard
    port map
    (
        CLK_14M    => CLK_14M,
        PHASE_ZERO => PHASE_ZERO,
        I_RESET_L  => not reset,
        I_ENA_H    => '1', --enabled

        I_ADDR     => std_logic_vector(ADDR)(7 downto 0),
        I_DATA     => std_logic_vector(D),
        unsigned(O_DATA)    => PSG_DO,
        I_RW_L     => not cpu_we,
        I_IOSEL_L  => not IO_SELECT(4),
        O_IRQ_L    => psg_irq_n,
        O_NMI_L    => psg_nmi_n,
        unsigned(O_AUDIO_L) => psg_audio_l,
        unsigned(O_AUDIO_R) => psg_audio_r
    );

  dac_l : work.dac
  generic map(9)
  port map 
  (
      clk_i     => CLK_14M,
      res_n_i   => not reset,
      dac_i     => std_logic_vector(psg_audio_l + (audio & "0000000")),
      dac_o     => AUDIO_L
  );

  dac_r : work.dac
  generic map(9)
  port map 
  (
      clk_i     => CLK_14M,
      res_n_i   => not reset,
      dac_i     => std_logic_vector(psg_audio_r + (audio & "0000000")),
      dac_o     => AUDIO_R
  );


    video1: video
    generic map
    (
        SD_HCNT_WIDTH => 10
    )
    port map 
    (
        clk_sys    => CLK_28M,
        scanlines  => "00", --status(12 downto 11),
        ce_divider => '1',
        scandoubler_disable => '0', --scandoubler_disable,

        R(5 downto 2) => color_15,
        R(1 downto 0) => "00",
        G => (others=>'0'),
        B => std_logic_vector(B)(7 downto 2),
        HSync => hsync,
        VSync => vsync,

        VGA_HS => vga_hsync_n_s,
        VGA_VS => vga_vsync_n_s,
        VGA_R(5 downto 2)  => color_index,
        VGA_R(1 downto 0)  => open,
        VGA_G => open,
        VGA_B => open
        --VGA_B(5 downto 1) => vga_b_s
    );

    -- Track Number overlay for the green channel
    osd_inst: entity work.osd_track
    generic map 
    (                                   
        C_digits        => 2,                       -- number of hex digits to show
        C_resolution_x  => 565

    )
    port map 
    (
        clk_pixel  => CLK_28M,
        vsync      => not vga_vsync_n_s, -- positive sync
        fetch_next => vga_hsync_n_s,     -- '1' when video_active
        probe_in   => "00" & std_logic_vector(TRACK),
        osd_out    => osd_pixel_s
    );


    osd_green_s     <= (others => (osd_pixel_s and osd_visible_s));
        
    -- OSD timer
    process (CLK_2M)
    begin
        if rising_edge(CLK_2M) then
            if D1_ACTIVE = '1' or D2_ACTIVE = '1' then
                timer_osd_s     <= (others => '1');
                osd_visible_s   <= '1';
            elsif timer_osd_s > 0 then
                timer_osd_s     <= timer_osd_s - 1;
                osd_visible_s   <= '1';
            else
                osd_visible_s   <= '0';
            end if;
            
        end if;
    end process;

    scanlines_en_s <= menu_status(11 downto 10);

      -- Index => RGB 
    process (CLK_28M)
        variable vga_col_v  : integer range 0 to 15;
        variable vga_rgb_v  : std_logic_vector(15 downto 0);
        variable vga_r_v    : std_logic_vector( 3 downto 0);
        variable vga_g_v    : std_logic_vector( 3 downto 0);
        variable vga_b_v    : std_logic_vector( 3 downto 0);
        type ram_t is array (natural range 0 to 15) of std_logic_vector(15 downto 0);
        constant rgb_c : ram_t := 
        (
            -- Original Apple II palette
        
                --  0 - 0x00 00 00 - Black
                --  1 - 0x90 17 40 - Red
                --  2 - 0x40 2c a5 - Dark Blue
                --  3 - 0xd0 43 e5 - Purple
                --  4 - 0x00 69 40 - Dark Green
                --  5 - 0x80 80 80 - Gray 1
                --  6 - 0x2f 95 e5 - Medium Blue
                --  7 - 0xbf ab ff - Light Blue
                --  8 - 0x40 54 00 - Brown
                --  9 - 0xd0 6a 1a - Orange
                -- 10 - 0x80 80 80 - Gray 2 
                -- 11 - 0xff 96 bf - Pink
                -- 12 - 0x2f bc 1a - Light Green
                -- 13 - 0xbf d3 5a - Yellow
                -- 14 - 0x6f e8 bf - Aqua
                -- 15 - 0xff ff ff - White
                
                        --      RG0B
                0  => X"0000",
                1  => X"9104",
                2  => X"420A",
                3  => X"D405",
                4  => X"0604",
                5  => X"8808",
                6  => X"290E",
                7  => X"BA0F",
                8  => X"4500",
                9  => X"D601",
                10 => X"8808",
                11 => X"F90B",
                12 => X"2B01",
                13 => X"BD05",
                14 => X"6E0B",
                15 => X"FF0F"

                
        );
    begin
        if rising_edge(CLK_28M) then
            vga_col_v := to_integer(unsigned(color_index));
            vga_rgb_v := rgb_c(vga_col_v);
            
            if scanlines_en_s = "01" then --25% = 1/2 + 1/4
                    vga_r_s <= ('0' & (vga_rgb_v(15 downto 12))) + ("00" & (vga_rgb_v(15 downto 13)));
                    vga_g_s <= ('0' & (vga_rgb_v(11 downto  8))) + ("00" & (vga_rgb_v(11 downto  9))) or osd_green_s;
                    vga_b_s <= ('0' & (vga_rgb_v( 3 downto  0))) + ("00" & (vga_rgb_v( 3 downto  1)));

            elsif scanlines_en_s = "10" then -- 50%
                    vga_r_s <= '0' & vga_rgb_v(15 downto 12);
                    vga_g_s <= '0' & vga_rgb_v(11 downto  8) or osd_green_s;
                    vga_b_s <= '0' & vga_rgb_v( 3 downto  0);
                    
            elsif scanlines_en_s = "11" then -- 75%
                    vga_r_s <= "00" & vga_rgb_v(15 downto 13);
                    vga_g_s <= "00" & vga_rgb_v(11 downto  9) or osd_green_s;
                    vga_b_s <= "00" & vga_rgb_v( 3 downto  1);
            end if;
            
            if  scanlines_en_s = "00" or odd_line_s = '0' then 
                    vga_r_s <= vga_rgb_v(15 downto 12) & vga_rgb_v(12);
                    vga_g_s <= vga_rgb_v(11 downto  8) & vga_rgb_v(8) or osd_green_s;
                    vga_b_s <= vga_rgb_v( 3 downto  0) & vga_rgb_v(0);
            end if;
        
            
            
        end if;
    end process;




     osd1 : osd 
    generic map
    (
        STRLEN       => CONF_STR'length,
        OSD_COLOR    => "001", -- RGB
        OSD_X_OFFSET => "0000010010", -- 50
        OSD_Y_OFFSET => "0000001111"  -- 15
    )
    port map
    (
        pclk       => CLK_28M,

        -- spi for OSD
        sdi        => SPI_DI,
        sck        => SPI_SCK,
        ss         => SPI_SS2,
        sdo        => SPI_DO,
        
        red_in     => vga_r_s,
        green_in   => vga_g_s,
        blue_in    => vga_b_s,
        hs_in      => vga_hsync_n_s,
        vs_in      => vga_vsync_n_s,

        red_out    => osd_r_s,
        green_out  => osd_g_s,
        blue_out   => osd_b_s,
        hs_out     => VGA_HS,
        vs_out     => VGA_VS,

        data_in    => osd_s,
        conf_str   => to_slv(CONF_STR),
        menu_in    => '0',
        status     => menu_status,
        mc_ack     => mc_ack,
        reset      => reset,
        
        pump_active_o   => pump_active_s,
        sram_a_o        => sram_addr_s,
        sram_d_o        => sram_data_s,
        sram_we_n_o     => sram_we_s,
        config_buffer_o => open,
        osd_enable      => osd_enable_s
    );
    
    sram_addr_o   <= sram_addr_s when pump_active_s = '1' else disk_addr_s;
    sram_data_io  <= sram_data_s when pump_active_s = '1' else (others=>'Z');
    disk_data_s   <= sram_data_io;
   sram_oe_n_o   <= '0'; 
    sram_we_n_o   <= sram_we_s;
    
        VGA_R <= osd_r_s;
        VGA_G <= osd_g_s;
        VGA_B <= osd_b_s;


end datapath;