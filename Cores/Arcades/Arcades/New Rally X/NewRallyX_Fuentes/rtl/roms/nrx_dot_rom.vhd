library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity nrx_dot_rom is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(7 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

-- ROM rx1-6.8m

architecture prom of nrx_dot_rom is
	type rom is array(0 to  255) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"02",X"02",X"03",X"03",X"02",X"02",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",
		X"01",X"01",X"03",X"03",X"01",X"01",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",
		X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",
		X"00",X"00",X"03",X"03",X"00",X"00",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",
		X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",
		X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"01",
		X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",
		X"02",X"02",X"02",X"02",X"02",X"01",X"01",X"02",X"02",X"01",X"01",X"02",X"02",X"02",X"02",X"02",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
