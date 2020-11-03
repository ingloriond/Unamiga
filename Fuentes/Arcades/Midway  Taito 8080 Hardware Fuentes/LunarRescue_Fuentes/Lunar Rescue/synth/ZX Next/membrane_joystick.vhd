------------------------------------------------------------------------------
-- Membrane Joystick by Victor Trucco - 2020
------------------------------------------------------------------------------


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;


library UNISIM;
use UNISIM.Vcomponents.all;


entity membrane_joystick is
	port(
	
      clock       		: in    std_logic;
      reset       		: in    std_logic;

      membrane_joy_o  	: out   std_logic_vector(9 downto 0)  := (others => '0'); -- C, P2, P1, COIN, F2, F1, U, D, L, R
		
      keyb_row_o   		: out std_logic_vector(7 downto 0);   -- physical membrane rows  0 = active, 1 = Z
      i_membrane_cols   : in  std_logic_vector(6 downto 0)    -- physical membrane cols returned, 6:5 are extra columns
  
	);
end;

architecture RTL of membrane_joystick is
	
	signal membrane_en		: std_logic;
	signal row_en				: std_logic;
   signal key_row_s        : std_logic_vector(7 downto 0);
	signal membrane_col_s   : std_logic_vector(4 downto 0);
	signal membrane_rows    : std_logic_vector(7 downto 0);
	signal state 				: std_logic_vector(2 downto 0) := "000";
   signal clk_div          : std_logic_vector(17 downto 0) := (others => '0');

	signal membrane_joy_s   : std_logic_vector(9 downto 0);
	signal membrane_key_s   : std_logic_vector(5 downto 0);

	
begin

	
   process (clock)
   begin
      if rising_edge(clock) then
         clk_div <= clk_div + 1;
      end if;
   end process;
	
	membrane_en <= '1' when clk_div(8 downto 0) = ('1' & X"FF") else '0';       
   row_en 		<= '1' when clk_div(17 downto 0) = ("11" & X"FFFF") else '0';   


   process (row_en)
   begin
      if rising_edge(row_en) then
          state <= state + 1;

			 case state is
                  when "000" =>  key_row_s <= "11111110";		
                  when "001" =>  key_row_s <= "11111101";		
                  when "010" =>  key_row_s <= "11111011";		
                  when "011" =>  key_row_s <= "11110111";		
                  when "100" =>  key_row_s <= "11101111";		
                  when "101" =>  key_row_s <= "11011111";	
                  when "110" =>  key_row_s <= "10111111";	
                  when "111" =>  key_row_s <= "01111111";	
						when others => key_row_s <= "11111111";	
				end case;		
		end if;
   end process;
   	
   membrane_mod : entity work.membrane
   port map
   (
      i_CLK             => clock,
      i_CLK_EN          => membrane_en,
      
      i_reset           => reset,
      
      i_rows            => key_row_s, 			-- which row we are testing ('0' to test)
      o_cols            => membrane_col_s, 	-- resulting col 

		-- phisical pins
      o_membrane_rows   => membrane_rows,   
      i_membrane_cols   => i_membrane_cols
   );
   
   keyb_row_o(0) <= '0' when membrane_rows(0) = '0' else 'Z';
   keyb_row_o(1) <= '0' when membrane_rows(1) = '0' else 'Z';
   keyb_row_o(2) <= '0' when membrane_rows(2) = '0' else 'Z';
   keyb_row_o(3) <= '0' when membrane_rows(3) = '0' else 'Z';
   keyb_row_o(4) <= '0' when membrane_rows(4) = '0' else 'Z';
   keyb_row_o(5) <= '0' when membrane_rows(5) = '0' else 'Z';
   keyb_row_o(6) <= '0' when membrane_rows(6) = '0' else 'Z';
   keyb_row_o(7) <= '0' when membrane_rows(7) = '0' else 'Z';
	
	-----------------------------------------------------
	-- Output	
	-----------------------------------------------------
	
	process (clock)
   begin
      if rising_edge(clock) then
	
			if key_row_s = "11111110" then -- (A8)
				if membrane_col_s(3) = '0' then membrane_joy_s(9) <= '1'; else membrane_joy_s(9) <= '0'; end if; -- C - patron list
			end if;
			
				
			if key_row_s = "11111101" then -- (A9)
				if membrane_col_s(0) = '0' then membrane_key_s(2) <= '1'; else membrane_key_s(2) <= '0'; end if; -- A - down
			end if;
			
			
			if key_row_s = "11111011" then -- (A10)
				if membrane_col_s(0) = '0' then membrane_key_s(3) <= '1'; else membrane_key_s(3) <= '0'; end if; -- Q - up
			end if;
			
			if key_row_s = "11110111" then -- (A11)
				if membrane_col_s(0) = '0' then membrane_joy_s(7) <= '1'; else membrane_joy_s(7) <= '0'; end if; -- 1 - P1
				if membrane_col_s(1) = '0' then membrane_joy_s(8) <= '1'; else membrane_joy_s(8) <= '0'; end if; -- 2 - P2
				if membrane_col_s(2) = '0' then membrane_joy_s(6) <= '1'; else membrane_joy_s(6) <= '0'; end if; -- 3 - coin
				if membrane_col_s(4) = '0' then membrane_joy_s(1) <= '1'; else membrane_joy_s(1) <= '0'; end if; -- 5 - left
			end if;
			
			if key_row_s = "11101111" then -- (A12)
				if membrane_col_s(2) = '0' then	membrane_joy_s(0) <= '1'; else membrane_joy_s(0) <= '0'; end if; -- 8 - right
				if membrane_col_s(3) = '0' then	membrane_joy_s(3) <= '1'; else membrane_joy_s(3) <= '0'; end if; -- 7 - up
				if membrane_col_s(4) = '0' then	membrane_joy_s(2) <= '1'; else membrane_joy_s(2) <= '0'; end if; -- 6 - down
			end if;	
			
			if key_row_s = "11011111" then -- (A13)
				if membrane_col_s(0) = '0' then	membrane_key_s(0) <= '1'; else membrane_key_s(0) <= '0'; end if; -- P - right
				if membrane_col_s(1) = '0' then	membrane_key_s(1) <= '1'; else membrane_key_s(1) <= '0'; end if; -- O - left	
			end if;	
			
			if key_row_s = "01111111" then -- (A15)
				if membrane_col_s(0) = '0' then	membrane_key_s(4) <= '1'; else membrane_key_s(4) <= '0'; end if; -- Space - fire 1
				if membrane_col_s(2) = '0' then	membrane_key_s(5) <= '1'; else membrane_key_s(5) <= '0'; end if; -- M     - fire 2
			end if;	
			
		end if;
	end process;

	membrane_joy_o <= membrane_joy_s or membrane_key_s;

	
end RTL;
