library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity P4 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(7 downto 0);
	data : out std_logic_vector(3 downto 0)
);
end entity;

architecture prom of P4 is
	type rom is array(0 to  255) of std_logic_vector(3 downto 0);
	signal rom_data: rom := (
		"0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000",
		"0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000",
		"0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000",
		"0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000",
		"0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000",
		"0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000",
		"0000","0000","0000","0000","0000","0000","0000","0000","0010","0010","0010","0010","0010","0010","0010","0010",
		"0010","0010","0010","0010","0010","0010","0010","0010","0010","0010","0010","0010","0010","0010","0010","1010",
		"1010","1010","1010","1010","1010","1110","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000",
		"0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000",
		"0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000",
		"0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000",
		"0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000",
		"0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000","0000",
		"1010","1010","1010","1010","1010","1010","1010","1010","1010","1010","1010","1010","1010","1010","1010","1010",
		"1010","1010","1011","1011","1011","1010","1010","1010","1010","1010","1010","1010","1010","1010","1010","1010");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
