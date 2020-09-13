------------------------------------------------------------
   -- SRAM INTERFACE ------------------------------------------
   ------------------------------------------------------------
   
   -- https://www.alliancememory.com/wp-content/uploads/pdf/sram/fa/as7c34096a_v2.1.pdf
   -- https://www.idt.com/document/dst/71v424-data-sheet
   
   -- SRAM cycles are executed within every 28MHz cycle and are
   -- granted to one of three simultaneous requesters, with the
   -- cpu granted highest priority and layer 2 granted second
   -- priority.

   -- To ensure that a 28MHz cpu speed would be possible, the 
   -- initial design allocates the entire 28MHz period to the 
   -- sram memory cycle with the result of reads stored at the 
   -- end of the period on the next rising edge.  This has
   -- the consequence that cpu instruction fetches and DMA
   -- 2-cycle reads must have one wait state inserted at 28MHz 
   -- speed.

   -- For memory write timing, the 5 x 28MHz hdmi clock is used
   -- to time the write pulse to ensure the write address is
   -- stable before the write pulse is asserted and to ensure
   -- the write cycle is completed before the end of the 28MHz period.
   
   -- Hard and soft resets span many 28MHz cycles so the currently
   -- running sram cycle is allowed to complete before the sram
   -- is held in a neutral state during the reset.  This ensures
   -- spurious writes don't contaminate the sram during soft reset.
   
   -- In the notation below, port A is r/w and is the highest
   -- priority assigned to the cpu.  Port B is read-only and
   -- is second priority assigned to layer 2.  Layer 2 requests
   -- can be delayed by one cycle so they are fine soaking up
   -- spare sram bandwidth at second priority.

   -- PORT A (R/W) (cpu/dma):
   --
   -- zxn_ram_a_addr   : std_logic_vector(20 downto 0)
   -- zxn_ram_a_req    : '1' on rising edge indicates memory request
   -- zxn_ram_a_rd     : '1' for read, '0' for write
   -- zxn_ram_a_do     : std_logic_vector(7 downto 0) data to write to memory
   -- zxn_ram_a_di     : std_logic_vector(7 downto 0) data read from memory
   
   -- PORT B (R) (layer 2):
   --
   -- zxn_ram_b_addr   : std_logic_vector(20 downto 0)
   -- zxn_ram_b_req_t  : toggles to indicate new request
   -- zxn_ram_b_di     : std_logic_vector(7 downto 0) data read from memory
   
   -- PORT C (R/W) (dma, soaks up spare bandwidth)
   
   -- SRAM I/O PINS:
   --
   -- ram_addr_o       : std_logic_vector(18 downto 0)
   -- ram_data_io      : std_logic_vector(15 downto 0)
   -- ram_oe_n_o
   -- ram_we_n_o
   -- ram_ce_n_o       : std_logic_vector(3 downto 0)
   
   -- Determine active port and sram signals for next memory cycle
	
	
	library ieee;
use ieee.std_logic_1164.all;

entity dpSRAM_NEXT is
	port (
	   -- CLOKS
		CLK_28				: in    std_logic;
		CLK_HDMI				: in    std_logic;					-- 5 X clk_i
		reset					: in    std_logic;
		
		-- PORT A (R/W) (cpu/dma)
		zxn_ram_a_addr	   : in    std_logic_vector(20 downto 0);
		zxn_ram_a_req		: in    std_logic;							-- '1' on rising edge indicates memory request
		zxn_ram_a_rd		: in    std_logic;							-- '1' for read, '0' for write
		zxn_ram_a_do		: in    std_logic_vector(7 downto 0);	--	data to write to memory
		zxn_ram_a_di		: out   std_logic_vector(7 downto 0);	--	data read from memory
		
		-- PORT B (R) (layer 2)
		zxn_ram_b_addr	   : in    std_logic_vector(20 downto 0);
		zxn_ram_b_req_t	: in    std_logic;							--	toggles to indicate new request
		zxn_ram_b_di		: out   std_logic_vector(7 downto 0);	-- data read from memory
		
		-- SRAM 1 in board
		ram_addr_o			: out   std_logic_vector(18 downto 0);
		ram_data_io_zxdos  		: inout std_logic_vector(7 downto 0);
		ram1_we_n_o 		: out   std_logic;
		ram1_oe_n_o 		: out   std_logic	:= '0'; 
		ram1_ce_n_o			: out   std_logic	:= '0'; 
      
		-- SRAM 2 in board				
		ram2_addr_o			: out   std_logic_vector(18 downto 0);
		ram2_data_io_zxdos  		: inout std_logic_vector(7 downto 0);
		ram2_we_n_o 		: out   std_logic;
		ram2_oe_n_o 		: out   std_logic	:= '0'; 
		ram2_ce_n_o			: out   std_logic	:= '0' 
	);
end entity;

architecture Behavior of dpSRAM_NEXT is

	 -- sram interface
   
   signal sram_port_b_req        : std_logic;
   signal zxn_ram_b_req          : std_logic;
   signal sram_addr              : std_logic_vector(20 downto 0);
   signal sram_cs_n              : std_logic_vector(3 downto 0);
   signal sram_data_H            : std_logic;
   signal sram_rd                : std_logic;
   
   signal sram_cs_n_active       : std_logic_vector(3 downto 0)   := (others => '1');
   signal sram_oe_n_active       : std_logic                      := '0';
   signal sram_addr_active       : std_logic_vector(18 downto 0)  := (others => '0');
   signal sram_data_active       : std_logic_vector(15 downto 0)  := (others => '0');
   signal sram_port_a_active     : std_logic                      := '0';
   signal sram_port_b_active     : std_logic                      := '0';
   signal sram_data_H_active     : std_logic                      := '0';
   
   signal sram_data_in           : std_logic_vector(15 downto 0);
   signal sram_port_a_read       : std_logic;
   signal sram_port_b_read       : std_logic;
   signal sram_data_H_read       : std_logic;
   signal sram_data_in_byte      : std_logic_vector(7 downto 0);
   
   signal sram_port_a_dat        : std_logic_vector(7 downto 0);
   signal sram_port_b_dat        : std_logic_vector(7 downto 0);
   signal sram_port_a_do         : std_logic_vector(7 downto 0);
   signal sram_port_b_do         : std_logic_vector(7 downto 0);
   
   signal sram_we_line           : std_logic_vector(3 downto 0)   := (others => '0');
   	
	signal ram_data_io            : std_logic_vector(15 downto 0)  := (others => 'Z');
   signal ram_oe_n_o             : std_logic                      := '1';
   signal ram_ce_n_o             : std_logic_vector( 3 downto 0)  := (others => '1');
   signal ram_we_n_o             : std_logic                      := '1';
	
begin

   zxn_ram_b_req <= (zxn_ram_b_req_t xor sram_port_b_req) and not zxn_ram_a_req;   -- 0 = Port A (or nothing), 1 = Port B
   sram_addr <= zxn_ram_a_addr when zxn_ram_b_req = '0' else zxn_ram_b_addr;  
   
   -- Track port B request which operates on a toggled signal
   
   process (CLK_28)
   begin
      if rising_edge(CLK_28) then
         if zxn_ram_b_req = '1' then
            sram_port_b_req <= zxn_ram_b_req_t;				
         end if;
      end if;
   end process;

   -- Select active sram chip
   
   process (zxn_ram_a_req, zxn_ram_b_req, sram_addr)
   begin
      if zxn_ram_a_req = '1' or zxn_ram_b_req = '1' then
         case sram_addr(20 downto 19) is
            when "00"   =>  sram_cs_n <= "1110";
            when "01"   =>  sram_cs_n <= "1101";
            when "10"   =>  sram_cs_n <= "1011";
            when others =>  sram_cs_n <= "0111";
         end case;
      else
         sram_cs_n <= (others => '1');
      end if;
   end process;
   
   sram_data_H <= sram_addr(19);
   sram_rd <= (zxn_ram_a_rd or not zxn_ram_a_req) when zxn_ram_b_req = '0' else '1';
   
   -- Memory cycle
   
   process (CLK_28)
   begin
      if rising_edge(CLK_28) then
         if reset = '1' then
         
            sram_cs_n_active <= (others => '1');
            sram_oe_n_active <= '0';
            sram_addr_active <= (others => '0');
            sram_data_active <= (others => '0');
            
--				sram_addr_active_goma2 <= (others => '0'); --gomados
				
            sram_port_a_active <= '0';
            sram_port_b_active <= '0';
            
            sram_data_H_active <= '0';

         else

            sram_cs_n_active <= sram_cs_n;
            sram_oe_n_active <= not sram_rd;
            sram_addr_active <= sram_addr(18 downto 0);
            sram_data_active <= zxn_ram_a_do & zxn_ram_a_do;
				
--				sram_addr_active_goma2 <= sram_addr; --gomados
				
            sram_port_a_active <= zxn_ram_a_req;
            sram_port_b_active <= zxn_ram_b_req;
            
            sram_data_H_active <= sram_data_H;

         end if;
      end if;
   end process;
   
   -- Data in (R)
   
   process (CLK_28)
   begin
      if rising_edge(CLK_28) then
         sram_data_in <= ram_data_io;
      end if;
   end process;
   
   process (CLK_28)
   begin
      if rising_edge(CLK_28) then
         sram_port_a_read <= sram_port_a_active and not sram_oe_n_active;
         sram_port_b_read <= sram_port_b_active and not sram_oe_n_active;
         sram_data_H_read <= sram_data_H_active;
      end if;
   end process;
   
   sram_data_in_byte <= sram_data_in(7 downto 0) when sram_data_H_read = '0' else sram_data_in(15 downto 8);

   
   --
   
   process (CLK_28)
   begin
      if rising_edge(CLK_28) then
         if sram_port_a_read = '1' then
            sram_port_a_dat <= sram_data_in_byte;
         end if;
      end if;
   end process;
   
   process (CLK_28)
   begin
      if rising_edge(CLK_28) then
         if sram_port_b_read = '1' then
            sram_port_b_dat <= sram_data_in_byte;
         end if;
      end if;
   end process;
   
   sram_port_a_do <= sram_data_in_byte when sram_port_a_read = '1' else sram_port_a_dat;
   sram_port_b_do <= sram_data_in_byte when sram_port_b_read = '1' else sram_port_b_dat;
   
   -- Data out (W)
   -- 28MHz cycle is partitioned into five periods some of which will carry we signal
   
   process (CLK_HDMI)
   begin
      if rising_edge(CLK_HDMI) then
         if sram_oe_n_active = '1' and sram_we_line = "0000" then
            sram_we_line <= "1111";
            ram_we_n_o <= '0';
         else
            sram_we_line <= sram_we_line(2 downto 0) & '0';
            if sram_we_line(3 downto 1) = "111" then
               ram_we_n_o <= '0';
            else
               ram_we_n_o <= '1';
            end if;
         end if;
      end if;
   end process;
   
   -- zxdos write enable 2 x 512k SRAM
   --ram1_we_n_o <= '0' when ram_ce_n_o = "1110" else '1';
   --ram2_we_n_o <= '0' when ram_ce_n_o = "1101" else '1';
   ram1_we_n_o <= ram_ce_n_o(0) or ram_we_n_o;
   ram2_we_n_o <= ram_ce_n_o(1) or ram_we_n_o;
	

   -- Connect I/O signals
   
   -- make sure xst is pushing registers into io blocks
   
   ram_addr_o <= sram_addr_active;
--   ram_data_io <= sram_data_active when sram_oe_n_active = '1' else (others => 'Z');
   ram_oe_n_o <= sram_oe_n_active;
   ram_ce_n_o <= sram_cs_n_active;
   
	ram1_oe_n_o<= sram_oe_n_active;
	ram1_ce_n_o<= sram_cs_n_active(0);
	ram2_oe_n_o<= sram_oe_n_active;
	ram2_ce_n_o<= sram_cs_n_active(1);
	
--	ram_ce_zxdos <= '0' when  sram_cs_n_active = "1111"  else '1';

	-----------------------------------------------------------  eliminado al poner memoria SDRAM-------------------
    zxn_ram_a_di <= sram_port_a_do;
    zxn_ram_b_di <= sram_port_b_do;
	-----------------------------------------------------------------------

   -- zxdos memory

--	ram_addr_o <= sram_addr_active_goma2; --test memoria v4 -OK

		
   ram2_addr_o <= sram_addr_active;
   ram2_data_io_zxdos <= sram_data_active(15 downto 8) when sram_oe_n_active = '1' else (others => 'Z');
   ram_data_io_zxdos  <= sram_data_active(7 downto 0) when sram_oe_n_active = '1' else (others => 'Z');
   ram_data_io(7 downto 0)  <= ram_data_io_zxdos when ram_ce_n_o = "1110" else (others => 'Z');
   ram_data_io(15 downto 8) <= ram2_data_io_zxdos when ram_ce_n_o = "1101" else (others => 'Z');
	
--	ram_data_io(7 downto 0)  <= ram_data_output_zxdos when ram_ce_n_o = "1110" else (others => 'Z');
--   ram_data_io(15 downto 8) <= ram_data_output_zxdos when ram_ce_n_o = "1101" else (others => 'Z');
	
--	ram_data_io <= ram_data_output_zxdos & ram_data_output_zxdos;
--   ram_data_input_zxdos  <= sram_data_active(7 downto 0) when sram_oe_n_active = '1' else (others => 'Z');
-- ram_we_n_o_zxdos <= ram_we_n_o; 
 	
	
 	
 	
end;