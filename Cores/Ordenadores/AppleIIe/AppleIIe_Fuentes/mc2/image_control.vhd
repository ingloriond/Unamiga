-------------------------------------------------------------------------------
--
-- Image reader for the Apple ][ FPGA
--
-- 2019 - Victor Trucco
-- 
-- From previous work by:
-- Stephen A. Edwards (sedwards@cs.columbia.edu)
-- Michel Stempin (michel.stempin@wanadoo.fr)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity image_controller is
  generic (
    BLOCK_SIZE     : natural := 512;
    BLOCK_BITS     : natural := 9;
    TRACK_SIZE     : natural := 16#1A00#
  );

  port (
    -- System Interface -------------------------------------------------------
    CLK_14M        : in  std_logic;     -- System clock
    reset          : in  std_logic;

    -- SRAM Interface ---------------------------------------------------------
    buffer_addr_i  : out  std_logic_vector(18 downto 0);  
     buffer_data_i  : in  std_logic_vector(7 downto 0); 
    
    -- Track buffer Interface -------------------------------------------------
    ram_write_addr : out unsigned(12 downto 0);
    ram_di         : out unsigned(7 downto 0);
    ram_we         : out std_logic;
    track          : in  unsigned(5 downto 0);  -- Track number (0-34)
    image          : in  unsigned(9 downto 0)  -- Which disk image to read

  );

end image_controller;

architecture rtl of image_controller is


  type states is (
                  IDLE,
                  READ_TRACK,
                  READ_BLOCK_DATA,
                  WRITE_BYTE,
                  RECEIVE_BYTE);

  signal state, return_state : states;

  signal current_track : unsigned(5 downto 0);
  signal current_image : unsigned(9 downto 0);
  signal write_addr : unsigned(12 downto 0);
    
begin

  ram_write_addr <= write_addr;

  process(CLK_14M)
  variable lba : unsigned(31 downto 0);
  begin
    if rising_edge(CLK_14M) then
     
      ram_we <= '0';
        
      if reset = '1' then
        
              state <= IDLE;
              write_addr <= (others => '0');
              lba := (others => '0');
              
              -- Deliberately out of range
              current_track <= (others => '1');
              current_image <= (others => '1');

      else
        
              case state is
                     ---------------------------------------------------------------------
                     -- Idle state where we sit waiting for user image/track requests ----
                     when IDLE =>
                  
                            if track /= current_track or image /= current_image then
                                  -- Compute the LBA (Logical Block Address) from the given
                                  -- image/track numbers.
                                  -- Each Apple ][ floppy image contains 35 tracks, each consisting of
                                  -- 16 x 256-byte sectors.
                                  -- However, because of inter-sector gaps and address fields in
                                  -- raw mode, the actual length is set to 0x1A00, so each image is
                                  -- actually $1A00 bytes * 0x23 tracks = 0x38E00 bytes.
                                  -- So: lba = image * 0x38E00 + track * 0x1A00
                                  -- In order to avoid multiplications by constants, we replace
                                  -- them by direct add/sub of shifted image/track values:
                                  -- 0x38E00 = 0011 1000 1110 0000 0000
                                  --         = 0x40000 - 0x8000 + 0x1000 - 0x200
                                  -- 0x01A00 = 0000 0001 1010 0000 0000
                                  --         = 0x1000 + 0x800 + 0x200
                                  lba := ("0000" & image & "000000000000000000") -
                                         (           image &  "000000000000000") +
                                         (               image & "000000000000") -
                                         (                 image  & "000000000") +
                                         (                 track  & "000000000") +
                                         (               track &  "00000000000") +
                                         (              track  & "000000000000");

                                         
                                  write_addr <= (others => '0');
                                  state <= READ_TRACK;
                                  current_track <= track;
                                  current_image <= image;
                            end if;


                     when READ_TRACK =>
                            if write_addr = TRACK_SIZE then
                              state <= IDLE;
                            else
                              state <= READ_BLOCK_DATA;
                              buffer_addr_i <= std_logic_vector(lba)(18 downto 0);
                            end if;
                        
                     when READ_BLOCK_DATA =>
                            buffer_addr_i <= std_logic_vector(lba)(18 downto 0);
                            state <= RECEIVE_BYTE;
                        
                     when RECEIVE_BYTE =>
                            ram_di <= unsigned(buffer_data_i);      
                            state <= WRITE_BYTE;
                        
                     when WRITE_BYTE =>
                            ram_we <= '1';
                            write_addr <= write_addr + 1;
                            lba := lba + 1;
                            state <= READ_TRACK;
                  
                     when others => null;
                      
              end case;
              
      end if;
    end if;
  end process sd_fsm;


end rtl;
