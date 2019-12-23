library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity ROM_8H is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(11 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of ROM_8H is
	type rom is array(0 to  4095) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"00",X"00",X"00",X"70",X"38",X"3F",X"63",X"E3",X"00",X"00",X"0E",X"0E",X"1E",X"12",X"90",X"90",
		X"FF",X"E3",X"63",X"3F",X"38",X"70",X"00",X"00",X"92",X"90",X"90",X"12",X"1E",X"0E",X"0C",X"00",
		X"F0",X"F0",X"F0",X"F0",X"F0",X"F0",X"F0",X"F0",X"F3",X"F3",X"F0",X"F0",X"FF",X"FF",X"FF",X"FF",
		X"F0",X"F0",X"F0",X"F0",X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"00",X"00",X"FF",X"FF",X"FF",X"FF",
		X"CF",X"CF",X"0F",X"0F",X"FF",X"FF",X"FF",X"FF",X"0F",X"0F",X"0F",X"0F",X"0F",X"0F",X"0F",X"0F",
		X"00",X"00",X"00",X"00",X"FF",X"FF",X"FF",X"FF",X"0F",X"0F",X"0F",X"0F",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"00",X"00",X"FF",X"FF",X"FF",X"FF",X"0F",X"0F",X"0F",X"0F",
		X"FF",X"FF",X"FF",X"FF",X"0F",X"0F",X"CF",X"CF",X"0F",X"0F",X"0F",X"0F",X"0F",X"0F",X"0F",X"0F",
		X"FF",X"FF",X"FF",X"FF",X"F0",X"F0",X"F0",X"F0",X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"00",X"00",
		X"F0",X"F0",X"F0",X"F0",X"F0",X"F0",X"F0",X"F0",X"FF",X"FF",X"FF",X"FF",X"F0",X"F0",X"F3",X"F3",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"82",X"C6",X"7C",X"38",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"38",X"7C",X"C6",X"82",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"10",X"10",X"10",X"10",X"10",X"10",X"00",
		X"00",X"00",X"00",X"00",X"00",X"06",X"06",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"38",X"7C",X"C2",X"82",X"86",X"7C",X"38",X"00",X"00",X"02",X"02",X"FE",X"FE",X"42",X"02",X"00",
		X"62",X"F2",X"BA",X"9A",X"9E",X"CE",X"46",X"00",X"8C",X"DE",X"F2",X"B2",X"92",X"86",X"04",X"00",
		X"08",X"FE",X"FE",X"C8",X"68",X"38",X"18",X"00",X"9C",X"BE",X"A2",X"A2",X"A2",X"E6",X"E4",X"00",
		X"0C",X"9E",X"92",X"92",X"D2",X"7E",X"3C",X"00",X"C0",X"E0",X"B0",X"9E",X"8E",X"C0",X"C0",X"00",
		X"6C",X"FE",X"92",X"92",X"92",X"FE",X"6C",X"00",X"78",X"FC",X"96",X"92",X"92",X"F2",X"60",X"00",
		X"7C",X"82",X"AA",X"AA",X"BA",X"82",X"7C",X"00",X"7C",X"82",X"BA",X"AA",X"BE",X"82",X"7C",X"00",
		X"2E",X"2E",X"3A",X"3A",X"00",X"20",X"7E",X"7E",X"00",X"00",X"00",X"E0",X"C0",X"00",X"00",X"00",
		X"20",X"00",X"70",X"50",X"50",X"7E",X"7E",X"00",X"00",X"00",X"00",X"F0",X"FA",X"FA",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"3E",X"7E",X"C8",X"88",X"C8",X"7E",X"3E",X"00",
		X"6C",X"FE",X"92",X"92",X"92",X"FE",X"FE",X"00",X"44",X"C6",X"82",X"82",X"C6",X"7C",X"38",X"00",
		X"38",X"7C",X"C6",X"82",X"82",X"FE",X"FE",X"00",X"00",X"82",X"92",X"92",X"92",X"FE",X"FE",X"00",
		X"80",X"90",X"90",X"90",X"90",X"FE",X"FE",X"00",X"9E",X"9E",X"92",X"82",X"C6",X"7C",X"38",X"00",
		X"FE",X"FE",X"10",X"10",X"10",X"FE",X"FE",X"00",X"00",X"82",X"82",X"FE",X"FE",X"82",X"82",X"00",
		X"FC",X"FE",X"02",X"02",X"02",X"06",X"04",X"00",X"82",X"C6",X"6E",X"3C",X"18",X"FE",X"FE",X"00",
		X"00",X"02",X"02",X"02",X"02",X"FE",X"FE",X"00",X"FE",X"FE",X"70",X"38",X"70",X"FE",X"FE",X"00",
		X"FE",X"FE",X"1C",X"38",X"70",X"FE",X"FE",X"00",X"7C",X"FE",X"82",X"82",X"82",X"FE",X"7C",X"00",
		X"70",X"88",X"88",X"88",X"88",X"FE",X"FE",X"00",X"7A",X"FC",X"8E",X"8A",X"82",X"FE",X"7C",X"00",
		X"72",X"F6",X"9E",X"8C",X"88",X"FE",X"FE",X"00",X"4C",X"DE",X"92",X"92",X"92",X"F6",X"64",X"00",
		X"00",X"80",X"80",X"FE",X"FE",X"80",X"80",X"00",X"FC",X"FE",X"02",X"02",X"02",X"FE",X"FC",X"00",
		X"F0",X"F8",X"1C",X"0E",X"1C",X"F8",X"F0",X"00",X"FC",X"FE",X"1C",X"38",X"1C",X"FE",X"FC",X"00",
		X"C6",X"EE",X"7C",X"38",X"7C",X"EE",X"C6",X"00",X"00",X"C0",X"F0",X"1E",X"1E",X"F0",X"C0",X"00",
		X"C2",X"E2",X"F2",X"BA",X"9E",X"8E",X"86",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"FF",X"80",X"80",X"80",X"80",X"80",X"80",X"80",X"FF",X"01",X"01",X"01",X"01",X"01",X"01",X"01",
		X"80",X"80",X"80",X"80",X"80",X"80",X"80",X"FF",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"FF",
		X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"66",X"66",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",
		X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",
		X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"7F",X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FE",
		X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",
		X"E6",X"E7",X"E7",X"E0",X"E0",X"FF",X"FF",X"FF",X"80",X"FF",X"FF",X"E0",X"E0",X"E7",X"E7",X"E6",
		X"66",X"E6",X"E6",X"06",X"06",X"FE",X"FE",X"FF",X"00",X"FE",X"FE",X"06",X"06",X"E6",X"E6",X"E6",
		X"E6",X"E7",X"E7",X"00",X"00",X"FF",X"FF",X"FF",X"00",X"FF",X"FF",X"00",X"00",X"E7",X"E7",X"E6",
		X"E6",X"E7",X"E7",X"E0",X"E0",X"E7",X"E7",X"E7",X"66",X"E6",X"E6",X"06",X"06",X"E6",X"E6",X"E6",
		X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"66",X"66",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",
		X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",
		X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"7F",X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FE",
		X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",
		X"E6",X"E7",X"E7",X"E0",X"E0",X"FF",X"FF",X"FF",X"80",X"FF",X"FF",X"E0",X"E0",X"E7",X"E7",X"E6",
		X"66",X"E6",X"E6",X"06",X"06",X"FE",X"FE",X"FF",X"00",X"FE",X"FE",X"06",X"06",X"E6",X"E6",X"E6",
		X"E6",X"E7",X"E7",X"00",X"00",X"FF",X"FF",X"FF",X"00",X"FF",X"FF",X"00",X"00",X"E7",X"E7",X"E6",
		X"E6",X"E7",X"E7",X"E0",X"E0",X"E7",X"E7",X"E7",X"66",X"E6",X"E6",X"06",X"06",X"E6",X"E6",X"E6",
		X"00",X"00",X"00",X"00",X"00",X"02",X"07",X"07",X"00",X"00",X"00",X"00",X"00",X"00",X"C0",X"E0",
		X"0B",X"04",X"03",X"00",X"00",X"00",X"00",X"00",X"E0",X"20",X"C0",X"20",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"06",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"07",X"07",X"03",X"00",X"00",X"00",X"00",X"00",X"00",X"80",X"80",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"03",X"07",X"0C",X"18",X"30",X"30",X"00",X"00",X"C0",X"E0",X"30",X"18",X"0C",X"0C",
		X"30",X"30",X"18",X"0C",X"07",X"03",X"00",X"00",X"0C",X"0C",X"18",X"30",X"E0",X"C0",X"00",X"00",
		X"07",X"0F",X"18",X"30",X"60",X"C0",X"C0",X"C0",X"E0",X"F0",X"18",X"0C",X"06",X"03",X"03",X"03",
		X"C0",X"C0",X"C0",X"60",X"30",X"18",X"0F",X"07",X"03",X"03",X"03",X"06",X"0C",X"18",X"F0",X"E0",
		X"20",X"00",X"24",X"00",X"00",X"A7",X"30",X"40",X"00",X"00",X"00",X"00",X"00",X"FE",X"00",X"00",
		X"78",X"70",X"07",X"28",X"80",X"20",X"00",X"00",X"00",X"00",X"FE",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"21",X"01",X"00",X"AC",X"54",X"00",X"00",X"70",X"FC",X"FE",X"3E",X"0F",X"07",
		X"A8",X"01",X"01",X"20",X"00",X"00",X"00",X"00",X"03",X"03",X"80",X"E0",X"00",X"00",X"00",X"00",
		X"20",X"00",X"14",X"21",X"83",X"24",X"10",X"38",X"00",X"00",X"70",X"FC",X"FE",X"3E",X"0F",X"07",
		X"58",X"A9",X"51",X"00",X"08",X"40",X"00",X"00",X"03",X"03",X"80",X"E0",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"66",X"66",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",
		X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",
		X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"7F",X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FE",
		X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",
		X"E6",X"E7",X"E7",X"E0",X"E0",X"FF",X"FF",X"FF",X"80",X"FF",X"FF",X"E0",X"E0",X"E7",X"E7",X"E6",
		X"66",X"E6",X"E6",X"06",X"06",X"FE",X"FE",X"FF",X"00",X"FE",X"FE",X"06",X"06",X"E6",X"E6",X"E6",
		X"E6",X"E7",X"E7",X"00",X"00",X"FF",X"FF",X"FF",X"00",X"FF",X"FF",X"00",X"00",X"E7",X"E7",X"E6",
		X"E6",X"E7",X"E7",X"E0",X"E0",X"E7",X"E7",X"E7",X"66",X"E6",X"E6",X"06",X"06",X"E6",X"E6",X"E6",
		X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"66",X"66",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",
		X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",
		X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"7F",X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FE",
		X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",
		X"E6",X"E7",X"E7",X"E0",X"E0",X"FF",X"FF",X"FF",X"80",X"FF",X"FF",X"E0",X"E0",X"E7",X"E7",X"E6",
		X"66",X"E6",X"E6",X"06",X"06",X"FE",X"FE",X"FF",X"00",X"FE",X"FE",X"06",X"06",X"E6",X"E6",X"E6",
		X"E6",X"E7",X"E7",X"00",X"00",X"FF",X"FF",X"FF",X"00",X"FF",X"FF",X"00",X"00",X"E7",X"E7",X"E6",
		X"E6",X"E7",X"E7",X"E0",X"E0",X"E7",X"E7",X"E7",X"66",X"E6",X"E6",X"06",X"06",X"E6",X"E6",X"E6",
		X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",
		X"C0",X"C0",X"C0",X"C0",X"FF",X"FF",X"FF",X"FF",X"03",X"03",X"03",X"03",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"C0",X"C0",X"C0",X"C0",X"FF",X"FF",X"FF",X"FF",X"03",X"03",X"03",X"03",
		X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",
		X"FF",X"FF",X"FF",X"FF",X"C0",X"C0",X"C0",X"C0",X"FF",X"FF",X"FF",X"FF",X"03",X"03",X"03",X"03",
		X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",
		X"FF",X"FF",X"FF",X"FF",X"C0",X"C0",X"C0",X"C0",X"FF",X"FF",X"FF",X"FF",X"03",X"03",X"03",X"03",
		X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",
		X"FF",X"FF",X"FF",X"FF",X"C0",X"C0",X"C0",X"C0",X"FF",X"FF",X"FF",X"FF",X"03",X"03",X"03",X"03",
		X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",
		X"FF",X"FF",X"FF",X"FF",X"C0",X"C0",X"C0",X"C0",X"FF",X"FF",X"FF",X"FF",X"03",X"03",X"03",X"03",
		X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",
		X"00",X"00",X"00",X"00",X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"FF",X"00",X"00",X"00",X"00",X"FF",X"FF",X"FF",X"FF",
		X"00",X"00",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"00",X"00",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"00",X"00",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"FF",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"00",X"00",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"27",X"13",X"08",X"04",X"03",X"00",X"00",X"00",X"26",X"26",X"26",X"26",X"26",X"26",X"26",X"26",
		X"00",X"00",X"03",X"04",X"08",X"13",X"27",X"26",X"FF",X"FF",X"00",X"00",X"FF",X"00",X"00",X"00",
		X"00",X"00",X"FF",X"00",X"00",X"FF",X"FF",X"00",X"C8",X"90",X"20",X"40",X"80",X"00",X"00",X"00",
		X"C8",X"C8",X"C8",X"C8",X"C8",X"C8",X"C8",X"C8",X"00",X"00",X"80",X"40",X"20",X"90",X"C8",X"C8",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"1C",X"0E",X"02",X"00",X"00",X"00",X"00",X"C0",
		X"00",X"00",X"00",X"00",X"00",X"30",X"38",X"1C",X"20",X"20",X"30",X"30",X"33",X"3F",X"F8",X"00",
		X"00",X"0F",X"3C",X"78",X"38",X"10",X"40",X"40",X"E0",X"F0",X"F0",X"78",X"38",X"1B",X"09",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"F0",X"F0",X"F0",X"F0",X"F0",X"F0",X"F0",X"F0",X"F3",X"F3",X"F3",X"F3",X"F3",X"F3",X"F3",X"F3",
		X"F0",X"F0",X"F0",X"F0",X"F0",X"F0",X"F0",X"F0",X"F3",X"F3",X"F3",X"F3",X"F3",X"F3",X"F3",X"F3",
		X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",X"FF",
		X"00",X"00",X"00",X"00",X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"00",X"00",X"FF",X"FF",X"FF",X"FF",
		X"CF",X"CF",X"CF",X"CF",X"CF",X"CF",X"CF",X"CF",X"0F",X"0F",X"0F",X"0F",X"0F",X"0F",X"0F",X"0F",
		X"CF",X"CF",X"CF",X"CF",X"CF",X"CF",X"CF",X"CF",X"0F",X"0F",X"0F",X"0F",X"0F",X"0F",X"0F",X"0F",
		X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"00",X"00",X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"00",X"00",
		X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"F9",X"F9",X"F9",X"F9",X"F9",X"F9",X"F9",X"F9",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"00",X"00",X"FF",X"F9",X"F9",X"F1",X"E3",X"C2",X"06",X"1C",X"F0",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"01",X"81",X"81",X"81",X"C1",X"C1",X"E1",X"E1",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"E1",X"F1",X"F1",X"F9",X"F9",X"F9",X"F9",X"F9",
		X"C0",X"C0",X"E0",X"E0",X"E0",X"F0",X"F0",X"F8",X"09",X"09",X"01",X"01",X"01",X"01",X"01",X"01",
		X"F8",X"F8",X"FC",X"FC",X"FE",X"FE",X"FE",X"FF",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"01",
		X"1F",X"1F",X"0F",X"0F",X"07",X"07",X"03",X"03",X"F9",X"F9",X"F9",X"F9",X"F9",X"F9",X"F9",X"F9",
		X"01",X"01",X"00",X"00",X"00",X"80",X"80",X"80",X"F9",X"F9",X"F9",X"79",X"79",X"39",X"19",X"19",
		X"3E",X"1C",X"08",X"00",X"04",X"0E",X"7F",X"FF",X"79",X"79",X"39",X"19",X"01",X"01",X"01",X"81",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"7F",X"7F",X"3F",X"C1",X"E1",X"F1",X"F9",X"F9",X"F9",X"F9",X"F9",
		X"1F",X"03",X"00",X"00",X"20",X"78",X"7E",X"3F",X"E1",X"E1",X"61",X"01",X"01",X"01",X"01",X"81",
		X"0F",X"07",X"01",X"80",X"E0",X"F0",X"F8",X"7C",X"E1",X"E1",X"C1",X"C1",X"09",X"09",X"19",X"39",
		X"00",X"00",X"01",X"00",X"00",X"E0",X"80",X"00",X"09",X"89",X"89",X"B9",X"39",X"79",X"39",X"19",
		X"00",X"FE",X"FF",X"FF",X"00",X"00",X"00",X"7F",X"01",X"01",X"01",X"81",X"01",X"01",X"01",X"E1",
		X"7F",X"F8",X"F8",X"F8",X"38",X"F0",X"E0",X"C0",X"B9",X"39",X"F9",X"F9",X"F9",X"39",X"09",X"09",
		X"80",X"07",X"1F",X"3F",X"FF",X"FE",X"F8",X"60",X"09",X"89",X"81",X"81",X"81",X"01",X"01",X"09",
		X"0C",X"38",X"F8",X"F0",X"F0",X"E0",X"E0",X"C0",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"01",
		X"C0",X"81",X"03",X"07",X"0F",X"0F",X"1F",X"3F",X"81",X"81",X"81",X"81",X"81",X"89",X"89",X"89",
		X"00",X"0F",X"0F",X"1F",X"1F",X"1F",X"30",X"00",X"01",X"01",X"C1",X"C1",X"C1",X"C1",X"C1",X"41",
		X"0C",X"3E",X"7F",X"FF",X"FF",X"7F",X"3E",X"1C",X"19",X"09",X"09",X"01",X"01",X"01",X"01",X"01",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"01",X"01",X"01",X"01",X"41",X"41",X"41",X"D9",
		X"00",X"00",X"01",X"01",X"03",X"01",X"00",X"00",X"19",X"79",X"F9",X"F9",X"F9",X"F9",X"19",X"01",
		X"FF",X"00",X"00",X"E0",X"C0",X"C0",X"C0",X"C0",X"F0",X"1C",X"06",X"02",X"03",X"01",X"01",X"01",
		X"80",X"80",X"80",X"80",X"00",X"00",X"00",X"00",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"01",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"66",X"66",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",
		X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",
		X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"7F",X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FE",
		X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",
		X"E6",X"E7",X"E7",X"E0",X"E0",X"FF",X"FF",X"FF",X"80",X"FF",X"FF",X"E0",X"E0",X"E7",X"E7",X"E6",
		X"66",X"E6",X"E6",X"06",X"06",X"FE",X"FE",X"FF",X"00",X"FE",X"FE",X"06",X"06",X"E6",X"E6",X"E6",
		X"E6",X"E7",X"E7",X"00",X"00",X"FF",X"FF",X"FF",X"00",X"FF",X"FF",X"00",X"00",X"E7",X"E7",X"E6",
		X"E6",X"E7",X"E7",X"E0",X"E0",X"E7",X"E7",X"E7",X"66",X"E6",X"E6",X"06",X"06",X"E6",X"E6",X"E6",
		X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"66",X"66",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",
		X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",X"E6",
		X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"7F",X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FE",
		X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",X"00",X"FF",X"FF",X"00",X"00",X"FF",X"FF",X"FF",
		X"E6",X"E7",X"E7",X"E0",X"E0",X"FF",X"FF",X"FF",X"80",X"FF",X"FF",X"E0",X"E0",X"E7",X"E7",X"E6",
		X"66",X"E6",X"E6",X"06",X"06",X"FE",X"FE",X"FF",X"00",X"FE",X"FE",X"06",X"06",X"E6",X"E6",X"E6",
		X"E6",X"E7",X"E7",X"00",X"00",X"FF",X"FF",X"FF",X"00",X"FF",X"FF",X"00",X"00",X"E7",X"E7",X"E6",
		X"E6",X"E7",X"E7",X"E0",X"E0",X"E7",X"E7",X"E7",X"66",X"E6",X"E6",X"06",X"06",X"E6",X"E6",X"E6",
		X"00",X"00",X"03",X"07",X"07",X"07",X"03",X"07",X"00",X"00",X"E0",X"E0",X"E0",X"C0",X"E0",X"E0",
		X"07",X"07",X"03",X"07",X"07",X"05",X"00",X"00",X"E0",X"C0",X"A0",X"E0",X"E0",X"C0",X"00",X"00",
		X"00",X"00",X"00",X"00",X"03",X"07",X"0F",X"0E",X"00",X"00",X"00",X"00",X"C0",X"E0",X"F0",X"70",
		X"0E",X"0F",X"07",X"03",X"00",X"00",X"00",X"00",X"70",X"F0",X"E0",X"C0",X"00",X"00",X"00",X"00",
		X"00",X"00",X"03",X"07",X"0C",X"18",X"30",X"30",X"00",X"00",X"C0",X"E0",X"30",X"18",X"0C",X"0C",
		X"30",X"30",X"18",X"0C",X"07",X"03",X"00",X"00",X"0C",X"0C",X"18",X"30",X"E0",X"C0",X"00",X"00",
		X"07",X"0F",X"18",X"30",X"60",X"C0",X"C0",X"C0",X"E0",X"F0",X"18",X"0C",X"06",X"03",X"03",X"03",
		X"C0",X"C0",X"C0",X"60",X"30",X"18",X"0F",X"07",X"03",X"03",X"03",X"06",X"0C",X"18",X"F0",X"E0",
		X"00",X"00",X"1F",X"3F",X"3F",X"3E",X"1F",X"3F",X"00",X"00",X"00",X"3A",X"7E",X"7E",X"5C",X"00",
		X"3F",X"3E",X"1D",X"3F",X"3F",X"2E",X"00",X"00",X"0A",X"14",X"0A",X"14",X"00",X"00",X"00",X"00",
		X"00",X"00",X"1F",X"3F",X"3F",X"3E",X"1F",X"3F",X"00",X"00",X"00",X"3E",X"7E",X"7E",X"54",X"00",
		X"3F",X"3E",X"1D",X"3F",X"3F",X"2E",X"00",X"00",X"0A",X"14",X"0A",X"14",X"00",X"00",X"00",X"00",
		X"00",X"00",X"1F",X"3F",X"3F",X"3E",X"1F",X"3F",X"00",X"00",X"00",X"3E",X"7C",X"38",X"70",X"00",
		X"3F",X"3E",X"1D",X"3F",X"3F",X"2E",X"00",X"00",X"0A",X"14",X"0A",X"14",X"00",X"00",X"00",X"00",
		X"00",X"00",X"1F",X"3F",X"3F",X"3E",X"1F",X"3F",X"00",X"00",X"00",X"2E",X"7E",X"7E",X"74",X"00",
		X"3F",X"3E",X"1D",X"3F",X"3F",X"2E",X"00",X"00",X"0A",X"14",X"0A",X"14",X"00",X"00",X"00",X"00",
		X"03",X"03",X"03",X"03",X"03",X"03",X"01",X"00",X"7F",X"3F",X"03",X"03",X"03",X"03",X"03",X"03",
		X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",X"03",
		X"FF",X"81",X"85",X"9F",X"85",X"FD",X"81",X"FF",X"FF",X"81",X"DF",X"D3",X"D3",X"F3",X"81",X"FF",
		X"FF",X"81",X"DF",X"D3",X"D3",X"FF",X"81",X"FF",X"FF",X"81",X"FF",X"C1",X"C1",X"C1",X"81",X"FF",
		X"FF",X"81",X"FF",X"D3",X"D3",X"FF",X"81",X"FF",X"FF",X"81",X"FF",X"D3",X"D3",X"F3",X"81",X"FF",
		X"FF",X"81",X"FF",X"D1",X"D1",X"FF",X"81",X"FF",X"FF",X"81",X"9F",X"93",X"93",X"FF",X"81",X"FF",
		X"FF",X"81",X"E7",X"C3",X"C3",X"FF",X"81",X"FF",X"FF",X"81",X"FF",X"93",X"93",X"9F",X"81",X"FF",
		X"FF",X"81",X"C3",X"D3",X"D3",X"FF",X"81",X"FF",X"FF",X"81",X"C1",X"D1",X"D1",X"FF",X"81",X"FF",
		X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",
		X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",
		X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",
		X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",
		X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",
		X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",
		X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",
		X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",X"00",X"7E",X"7E",X"7E",X"7E",X"7E",X"7E",X"00",
		X"00",X"00",X"00",X"00",X"00",X"07",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FE",X"00",X"00",
		X"78",X"00",X"07",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FE",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"01",X"00",X"00",X"50",X"00",X"00",X"00",X"60",X"F8",X"7C",X"3C",X"0E",
		X"29",X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"06",X"80",X"C0",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"01",X"03",X"00",X"00",X"28",X"00",X"00",X"70",X"FC",X"FE",X"3E",X"0F",X"07",
		X"10",X"01",X"01",X"00",X"00",X"00",X"00",X"00",X"03",X"03",X"80",X"E0",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"01",X"03",X"00",X"64",X"94",X"00",X"00",X"70",X"FC",X"FE",X"3E",X"0F",X"07",
		X"08",X"01",X"01",X"00",X"00",X"00",X"00",X"00",X"03",X"03",X"80",X"E0",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"07",X"00",X"07",X"00",X"07",X"00",X"00",X"00",X"FC",X"50",X"FE",X"50",X"FE",
		X"00",X"07",X"00",X"00",X"00",X"00",X"00",X"00",X"50",X"FC",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"20",X"10",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"0C",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"80",X"40",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"20",X"10",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"0C",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"80",X"40",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"20",X"10",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"0C",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"80",X"40",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
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
