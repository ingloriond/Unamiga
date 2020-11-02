----------------------------------------------------------
--
-- Framebuffer for VGA output
-- Hold an entire screen (before scandoubler)
-- Can be used for screen rotation by hardware or
-- to provide standard times for HDMI
--
-- Attention: requires a huge amount of BRAM!
--
-- Victor Trucco - 2020
--
----------------------------------------------------------

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
    
entity framebuffer is
    generic
    (
        WIDHT  : integer := 320;
        HEIGHT : integer := 240;
        DW     : integer := 8
    );
    port 
    (
        clk_sys     : in  std_logic;
        clk_i       : in  std_logic;
        RGB_i       : in  std_logic_vector (DW-1 downto 0);
        hblank_i    : in  std_logic;
        vblank_i    : in  std_logic;
        rotate_i    : in  std_logic_vector (1 downto 0);
        
        clk_vga_i   : in  std_logic;
        RGB_o       : out std_logic_vector (DW-1 downto 0);
        hsync_o     : out std_logic;
        vsync_o     : out std_logic;
        blank_o     : out std_logic;

        odd_line_o  : out std_logic
    );
end framebuffer;

architecture rtl of framebuffer is
    
    constant AW : positive := positive(ceil(log2(real(WIDHT*HEIGHT))));

    signal pixel_out        : std_logic_vector(DW-1 downto 0);
    signal addr_rd          : std_logic_vector(15 downto 0);
    signal addr_wr          : std_logic_vector(15 downto 0);
    signal wren             : std_logic;
    signal picture          : std_logic;
    signal window_hcnt  : std_logic_vector( 9 downto 0) := (others => '0');
    signal window_vcnt  : std_logic_vector( 9 downto 0) := (others => '0');
    signal hcnt             : std_logic_vector( 9 downto 0) := (others => '0');
    --signal h                  : std_logic_vector( 9 downto 0) := (others => '0');
    signal vcnt             : std_logic_vector( 9 downto 0) := (others => '0');
    signal hsync            : std_logic;
    signal vsync            : std_logic;
    signal blank            : std_logic;
    
    -- Horizontal Timing constants  
    signal h_pixels_across   : integer;
    signal h_sync_on         : integer;
    signal h_sync_off        : integer;
    signal h_end_count       : integer;
    -- Vertical Timing constants
    signal v_pixels_down     : integer;
    signal v_sync_on         : integer;
    signal v_sync_off        : integer;
    signal v_end_count       : integer;
    
    -- In   
    constant hc_max         : integer := WIDHT; -- Number of horizontal visible pixels (before scandoubler)
    constant vc_max         : integer := HEIGHT; -- Number of vertical visible pixels  (before scandoubler)

        -- VGA positioning
    signal h_start              : integer; -- initial X position on VGA Screen
    signal h_end                : integer;
    signal v_start              : integer; -- initial Y position on VGA screen
    signal v_end                : integer;

    signal I_HCNT  : std_logic_vector( 8 downto 0) := (others => '0');
    signal I_VCNT  : std_logic_vector( 7 downto 0) := (others => '0');

    signal clk_buffer : std_logic;
    signal clk_buffer2 : std_logic;
    signal clk_buffer3 : std_logic;
    signal clk_buffer4 : std_logic;
    signal clk_buffer5 : std_logic;
    signal clk_buffer6 : std_logic;
begin

    process (clk_i)
    variable edge_hs : std_logic_vector(1 downto 0);
    variable edge_vs : std_logic_vector(1 downto 0);
    begin
        if rising_edge(clk_i) then

            edge_hs := edge_hs(0) & hblank_i;
            edge_vs := edge_vs(0) & vblank_i;
            
            I_HCNT <= I_HCNT + 1;

            if hblank_i = '1' then
                I_HCNT <= (others => '0');
            end if;

            if vblank_i = '1' then
                I_VCNT <= (others => '0');
            end if;

            if edge_hs = "01" then
                I_VCNT <= I_VCNT + 1;
            end if;

            if (hblank_i = '0' and vblank_i = '0') then
                wren <= '1';
            else
                wren <= '0';
            end if;

        end if;
    end process;

-- ModeLine " 640x 480@60Hz"  25.20  640  656  752  800  480  490  492  525 -HSync -VSync
-- ModeLine " 720x 480@60Hz"  27.00  720  736  798  858  480  489  495  525 -HSync -VSync
-- Modeline " 800x 600@60Hz"  40.00  800  840  968 1056  600  601  605  628 +HSync +VSync
-- ModeLine "1024x 768@60Hz"  65.00 1024 1048 1184 1344  768  771  777  806 -HSync -VSync

    process (clk_vga_i)
    begin
        if rising_edge(clk_vga_i) then 
            if rotate_i(0) = '0' then
            
            --  640x480
                h_pixels_across <= 640 - 1;
                h_sync_on       <= 656 - 1;
                h_sync_off      <= 752 - 1;
                h_end_count     <= 800 - 1;
            
                v_pixels_down   <= 480 - 1;
                v_sync_on       <= 490 - 1;
                v_sync_off      <= 492 - 1;
                v_end_count     <= 525 - 1;
                
                h_start         <= (640/2) - WIDHT; -- initial X position on VGA Screen
                h_end           <= h_start + (hc_max * 2);
                v_start         <= (480/2) - HEIGHT; -- initial Y position on VGA screen
                v_end           <= v_start + (vc_max * 2);

            else

                
            --  800x600
                 h_pixels_across     <= 800 - 1;
                 h_sync_on           <= 840 - 1;
                 h_sync_off          <= 968 - 1;
                 h_end_count         <= 1056 - 1;
             
                 v_pixels_down       <= 600 - 1;
                 v_sync_on           <= 601 - 1;
                 v_sync_off          <= 605 - 1;
                 v_end_count         <= 628 - 1;
                      
                h_start             <= (800/2) - HEIGHT; -- initial X position on VGA Screen
                h_end               <= h_start + (vc_max * 2);
                v_start             <= (600/2) - WIDHT;  -- initial Y position on VGA screen
                v_end               <= v_start + (hc_max * 2);

            end if;
        end if;
    end process;

    process (clk_sys)
    begin
        if rising_edge(clk_sys) then 
            clk_buffer <= clk_i; --delay the pixel clock for the BRAM
            clk_buffer2 <= clk_buffer;
        end if;
    end process;
    
    framebuffer: entity work.buffer_ram
    generic map 
    (
        addr_width_g    => AW,
        data_width_g    => DW
    )
    port map
    (
        clk_a_i     => clk_buffer2,
        data_a_i    => RGB_i,
        addr_a_i    => addr_wr,
        we_i        => wren,
        data_a_o    => open,
        --
        clk_b_i     => clk_vga_i,
        addr_b_i    => addr_rd,
        data_b_o    => pixel_out
    );

    process (clk_vga_i)
    begin
        if rising_edge(clk_vga_i) then 
            if hcnt = h_end_count then
                hcnt <= (others => '0');
            else
                hcnt <= hcnt + 1;
                if hcnt = h_start then
                    window_hcnt <= (others => '0');
                else
                    window_hcnt <= window_hcnt + 1;
                end if;
            end if;
            
            if hcnt = h_sync_on then
                if vcnt = v_end_count then
                    vcnt <= (others => '0');
                else
                    vcnt <= vcnt + 1;
                    if vcnt = v_start then
                        window_vcnt <= (others => '0');
                    else
                        window_vcnt <= window_vcnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (clk_i, I_HCNT, I_VCNT)
    variable wr_result_v : std_logic_vector(16 downto 0);
    begin
        if rising_edge(clk_i) then
          wr_result_v := std_logic_vector((unsigned(I_VCNT)                  * to_unsigned(hc_max, 9)) + unsigned(I_HCNT));
          addr_wr <= wr_result_v(15 downto 0);
        end if;
    end process;

    process (rotate_i, window_hcnt, window_vcnt)
        
        variable rd_result_v : std_logic_vector(17 downto 0);
    begin
      
        
        if (rotate_i = "00") then -- no rotation
            rd_result_v := '0' & std_logic_vector((unsigned(window_vcnt(8 downto 1)) * to_unsigned(hc_max, 9)) + unsigned(window_hcnt(9 downto 1)));


        elsif (rotate_i = "01") then  -- 90o CW           
            rd_result_v := std_logic_vector
            (                                
                                        (((to_unsigned(vc_max, 9) -1) - (unsigned(window_hcnt(9 downto 1)))) * to_unsigned(hc_max, 9)) + 
                                        (unsigned(window_vcnt(9 downto 1)))                            
            ); 
        elsif (rotate_i = "10") then -- 180o  
            rd_result_v := std_logic_vector
            (                                
                                       (((to_unsigned(vc_max, 9) - (unsigned(window_vcnt(9 downto 1)))) * to_unsigned(hc_max, 9)) - 
                                        (unsigned(window_hcnt(9 downto 1)))-2)                        
            ); 

        else -- 90o CCW  (( h *16 + (16-v)-1) ));
            rd_result_v := std_logic_vector
            (                                
                                        (to_unsigned(hc_max, 9) * (unsigned(window_hcnt(9 downto 1)))) + 

                                        (to_unsigned(hc_max, 9) - (unsigned(window_vcnt(9 downto 1)))) - 1                         
            ); 

        end if;
        

        addr_rd <= rd_result_v(15 downto 0);
    end process;

  --  wren        <= '1' when  (I_HCNT < hc_max) and (I_VCNT < vc_max) else '0';
--  addr_wr <= I_VCNT(7 downto 0) & I_HCNT(7 downto 0);
--  addr_rd <= window_vcnt(8 downto 1) & window_hcnt(8 downto 1);
    blank       <= '1' when (hcnt > h_pixels_across) or (vcnt > v_pixels_down) else '0';
    
    picture <= '1' when (hcnt > h_start+1 and hcnt <= h_end) and (vcnt > v_start and vcnt <= v_end) else '0';

    hsync_o <= '1' when (hcnt <= h_sync_on) or (hcnt > h_sync_off) else '0';
    vsync_o <= '1' when (vcnt <= v_sync_on) or (vcnt > v_sync_off) else '0';
--  RGB_o <= pixel_out when picture = '1' and (blank = '0') else (others => '0');
    
--    RGB_o <=   --(others=>'1')   when hcnt = 0 or hcnt = h_pixels_across or vcnt=0 or vcnt=v_pixels_down else 
--               --(others=>'1')   when hcnt = h_start or hcnt = h_end else 
--               pixel_out when picture = '1' and (blank = '0') else 
--               (others => '0');
    
    blank_o <= blank;

    odd_line_o <= '1' when vcnt(0) = '1' else '0';




 process (clk_vga_i)
    begin
        if rising_edge(clk_vga_i) then 

            if picture = '1' and (blank = '0') then
                RGB_o <=  pixel_out;
            else
                RGB_o <=  (others => '0');
            end if;

        end if;

end process;

end rtl;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity buffer_ram is
  generic (
    addr_width_g : integer := 8;
    data_width_g : integer := 8
  );
  port (
    clk_a_i  : in  std_logic;
    we_i     : in  std_logic;
    addr_a_i : in  std_logic_vector(addr_width_g-1 downto 0);
    data_a_i : in  std_logic_vector(data_width_g-1 downto 0);
    data_a_o : out std_logic_vector(data_width_g-1 downto 0);
    clk_b_i  : in  std_logic;
    addr_b_i : in  std_logic_vector(addr_width_g-1 downto 0);
    data_b_o : out std_logic_vector(data_width_g-1 downto 0)
  );
end entity;


library ieee;
use ieee.numeric_std.all;

architecture rtl_ram of buffer_ram is

  type   ram_t      is array (natural range 2**addr_width_g-1 downto 0) of
    std_logic_vector(data_width_g-1 downto 0);
  signal ram_q      : ram_t;
 
begin

    mem_a: process (clk_a_i)
        variable read_addr_v    : unsigned(addr_width_g-1 downto 0);
    begin
        if rising_edge(clk_a_i) then
            read_addr_v := unsigned(addr_a_i);
            if we_i = '1' then
                ram_q(to_integer(read_addr_v)) <= data_a_i;
            end if;
            data_a_o <= ram_q(to_integer(read_addr_v));
        end if;
    end process mem_a;

    mem_b: process (clk_b_i)
        variable read_addr_v    : unsigned(addr_width_g-1 downto 0);
    begin
        if rising_edge(clk_b_i) then
            read_addr_v := unsigned(addr_b_i);
            data_b_o <= ram_q(to_integer(read_addr_v));
        end if;
    end process mem_b;

end rtl_ram;