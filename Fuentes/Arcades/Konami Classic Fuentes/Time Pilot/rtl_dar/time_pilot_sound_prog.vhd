library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity time_pilot_sound_prog is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(11 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of time_pilot_sound_prog is
	type rom is array(0 to  4095) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"21",X"00",X"30",X"06",X"00",X"C3",X"9B",X"00",X"32",X"00",X"50",X"3A",X"00",X"40",X"C9",X"FF",
		X"32",X"00",X"70",X"3A",X"00",X"60",X"C9",X"FF",X"32",X"00",X"50",X"79",X"32",X"00",X"40",X"C9",
		X"32",X"00",X"70",X"79",X"32",X"00",X"60",X"C9",X"87",X"85",X"6F",X"7C",X"CE",X"00",X"67",X"7E",
		X"23",X"66",X"6F",X"E9",X"FF",X"FF",X"FF",X"FF",X"D9",X"08",X"CD",X"40",X"00",X"08",X"D9",X"C9",
		X"3E",X"0E",X"CF",X"B7",X"28",X"2F",X"57",X"E6",X"7F",X"FE",X"21",X"D0",X"CB",X"7A",X"20",X"42",
		X"CD",X"80",X"00",X"20",X"1C",X"CD",X"80",X"00",X"20",X"16",X"21",X"00",X"30",X"1E",X"06",X"7E",
		X"1D",X"28",X"08",X"2C",X"2C",X"BE",X"38",X"F8",X"C3",X"5F",X"00",X"BA",X"D0",X"CD",X"80",X"00",
		X"72",X"2C",X"36",X"00",X"C9",X"21",X"00",X"30",X"06",X"0C",X"AF",X"77",X"2C",X"10",X"FC",X"C9",
		X"21",X"00",X"30",X"06",X"06",X"0E",X"07",X"BE",X"28",X"05",X"2C",X"2C",X"10",X"F9",X"41",X"79",
		X"90",X"C9",X"CD",X"80",X"00",X"C8",X"AF",X"77",X"2C",X"77",X"C9",X"70",X"23",X"7C",X"FE",X"34",
		X"20",X"F9",X"F9",X"ED",X"56",X"21",X"00",X"80",X"22",X"0C",X"30",X"77",X"0E",X"00",X"16",X"06",
		X"7A",X"CD",X"9C",X"01",X"15",X"20",X"F9",X"0E",X"38",X"3E",X"07",X"DF",X"3E",X"07",X"E7",X"FB",
		X"3E",X"0F",X"CF",X"E6",X"F0",X"20",X"F9",X"F3",X"3E",X"01",X"32",X"0E",X"30",X"3A",X"01",X"30",
		X"B7",X"3A",X"00",X"30",X"28",X"06",X"CD",X"7F",X"01",X"C3",X"DF",X"00",X"CD",X"69",X"01",X"FB",
		X"00",X"00",X"F3",X"3E",X"02",X"32",X"0E",X"30",X"3A",X"03",X"30",X"B7",X"3A",X"02",X"30",X"28",
		X"06",X"CD",X"7F",X"01",X"C3",X"FA",X"00",X"CD",X"69",X"01",X"FB",X"00",X"00",X"F3",X"3E",X"03",
		X"32",X"0E",X"30",X"3A",X"05",X"30",X"B7",X"3A",X"04",X"30",X"28",X"06",X"CD",X"7F",X"01",X"C3",
		X"15",X"01",X"CD",X"69",X"01",X"FB",X"00",X"00",X"F3",X"3E",X"04",X"32",X"0E",X"30",X"3A",X"07",
		X"30",X"B7",X"3A",X"06",X"30",X"28",X"06",X"CD",X"7F",X"01",X"C3",X"30",X"01",X"CD",X"69",X"01",
		X"FB",X"00",X"00",X"F3",X"3E",X"05",X"32",X"0E",X"30",X"3A",X"09",X"30",X"B7",X"3A",X"08",X"30",
		X"28",X"06",X"CD",X"7F",X"01",X"C3",X"4B",X"01",X"CD",X"69",X"01",X"FB",X"00",X"00",X"F3",X"3E",
		X"06",X"32",X"0E",X"30",X"3A",X"0B",X"30",X"B7",X"3A",X"0A",X"30",X"28",X"06",X"CD",X"7F",X"01",
		X"C3",X"BF",X"00",X"CD",X"69",X"01",X"C3",X"BF",X"00",X"21",X"92",X"0A",X"EF",X"B7",X"20",X"17",
		X"21",X"01",X"30",X"3A",X"0E",X"30",X"3D",X"87",X"5F",X"16",X"00",X"19",X"36",X"01",X"C9",X"B7",
		X"C8",X"21",X"D4",X"0A",X"EF",X"B7",X"C8",X"21",X"00",X"30",X"3A",X"0E",X"30",X"3D",X"87",X"4F",
		X"06",X"00",X"09",X"70",X"2C",X"70",X"C9",X"0E",X"00",X"3A",X"0E",X"30",X"FE",X"04",X"30",X"05",
		X"C6",X"07",X"C3",X"18",X"00",X"C6",X"04",X"C3",X"20",X"00",X"3A",X"0E",X"30",X"FE",X"04",X"30",
		X"0B",X"3D",X"87",X"47",X"4D",X"DF",X"78",X"3C",X"4C",X"C3",X"18",X"00",X"D6",X"04",X"87",X"47",
		X"4D",X"E7",X"78",X"3C",X"4C",X"C3",X"20",X"00",X"01",X"FC",X"FF",X"21",X"00",X"00",X"1F",X"CB",
		X"15",X"1F",X"CB",X"15",X"3A",X"0E",X"30",X"C6",X"02",X"FE",X"06",X"38",X"04",X"D6",X"06",X"28",
		X"0A",X"87",X"29",X"37",X"CB",X"11",X"CB",X"10",X"3D",X"20",X"F7",X"EB",X"2A",X"0C",X"30",X"7D",
		X"A1",X"B3",X"6F",X"7C",X"A0",X"B2",X"67",X"22",X"0C",X"30",X"77",X"C9",X"DD",X"35",X"01",X"C0",
		X"DD",X"7E",X"08",X"DD",X"77",X"01",X"DD",X"35",X"00",X"28",X"15",X"DD",X"CB",X"00",X"46",X"C8",
		X"DD",X"7E",X"09",X"B7",X"C8",X"DD",X"86",X"07",X"F8",X"DD",X"77",X"07",X"4F",X"C3",X"99",X"01",
		X"DD",X"6E",X"02",X"DD",X"66",X"03",X"7E",X"57",X"E6",X"1F",X"28",X"24",X"FE",X"1F",X"28",X"37",
		X"CD",X"50",X"02",X"7A",X"E6",X"1F",X"3D",X"07",X"4F",X"DD",X"6E",X"04",X"DD",X"66",X"05",X"09",
		X"5E",X"23",X"56",X"EB",X"CD",X"AA",X"01",X"DD",X"4E",X"06",X"DD",X"71",X"07",X"C3",X"99",X"01",
		X"23",X"DD",X"75",X"02",X"DD",X"74",X"03",X"7A",X"E6",X"E0",X"07",X"07",X"07",X"47",X"3E",X"80",
		X"07",X"10",X"FD",X"DD",X"77",X"00",X"C9",X"7A",X"E6",X"E0",X"07",X"07",X"07",X"11",X"20",X"02",
		X"D5",X"23",X"5D",X"54",X"23",X"DD",X"75",X"02",X"DD",X"74",X"03",X"21",X"81",X"02",X"C3",X"28",
		X"00",X"91",X"02",X"A5",X"02",X"B5",X"02",X"BA",X"02",X"C9",X"02",X"C9",X"02",X"BF",X"02",X"C9",
		X"02",X"EB",X"4E",X"CB",X"21",X"06",X"00",X"21",X"CE",X"02",X"09",X"5E",X"23",X"56",X"DD",X"73",
		X"04",X"DD",X"72",X"05",X"C9",X"EB",X"4E",X"06",X"00",X"21",X"66",X"03",X"09",X"7E",X"DD",X"77",
		X"08",X"DD",X"77",X"01",X"C9",X"1A",X"DD",X"77",X"06",X"C9",X"1A",X"DD",X"77",X"09",X"C9",X"1A",
		X"DD",X"77",X"02",X"13",X"1A",X"DD",X"77",X"03",X"C9",X"E1",X"E1",X"3E",X"FF",X"C9",X"EE",X"02",
		X"F2",X"02",X"F6",X"02",X"FA",X"02",X"FE",X"02",X"02",X"03",X"06",X"03",X"0A",X"03",X"0E",X"03",
		X"12",X"03",X"16",X"03",X"1A",X"03",X"1E",X"03",X"22",X"03",X"26",X"03",X"2A",X"03",X"FF",X"0F",
		X"F2",X"07",X"80",X"07",X"14",X"07",X"AE",X"06",X"4E",X"06",X"F3",X"05",X"9E",X"05",X"4E",X"05",
		X"01",X"05",X"B9",X"04",X"76",X"04",X"36",X"04",X"F9",X"03",X"C0",X"03",X"8A",X"03",X"57",X"03",
		X"27",X"03",X"FA",X"02",X"CF",X"02",X"A7",X"02",X"81",X"02",X"5D",X"02",X"3B",X"02",X"1B",X"02",
		X"FD",X"01",X"E0",X"01",X"C5",X"01",X"AC",X"01",X"94",X"01",X"7D",X"01",X"68",X"01",X"53",X"01",
		X"40",X"01",X"2E",X"01",X"1D",X"01",X"0D",X"01",X"FE",X"00",X"F0",X"00",X"E3",X"00",X"D6",X"00",
		X"CA",X"00",X"BE",X"00",X"B4",X"00",X"AA",X"00",X"A0",X"00",X"97",X"00",X"8F",X"00",X"87",X"00",
		X"7F",X"00",X"78",X"00",X"71",X"00",X"6B",X"00",X"65",X"00",X"5F",X"00",X"5A",X"00",X"55",X"00",
		X"50",X"00",X"4C",X"00",X"07",X"00",X"3C",X"38",X"34",X"30",X"2C",X"28",X"24",X"20",X"1E",X"1C",
		X"1A",X"18",X"16",X"14",X"12",X"10",X"0F",X"0E",X"0D",X"0C",X"0B",X"0A",X"09",X"08",X"21",X"B5",
		X"03",X"11",X"0F",X"30",X"01",X"32",X"00",X"ED",X"B0",X"87",X"4F",X"87",X"87",X"81",X"4F",X"06",
		X"00",X"21",X"6E",X"0B",X"09",X"11",X"11",X"30",X"ED",X"A0",X"ED",X"A0",X"1E",X"1B",X"ED",X"A0",
		X"ED",X"A0",X"1E",X"25",X"ED",X"A0",X"ED",X"A0",X"1E",X"2F",X"ED",X"A0",X"ED",X"A0",X"1E",X"39",
		X"ED",X"A0",X"ED",X"A0",X"C9",X"01",X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"01",
		X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"01",X"01",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"FF",X"01",X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"01",X"01",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"AF",X"CD",X"C8",X"01",X"21",X"6B",X"00",X"CD",X"AA",
		X"01",X"21",X"41",X"30",X"36",X"00",X"2C",X"36",X"47",X"2C",X"0E",X"09",X"71",X"CD",X"99",X"01",
		X"AF",X"C9",X"21",X"41",X"30",X"35",X"7E",X"E6",X"03",X"20",X"18",X"2C",X"35",X"7E",X"28",X"1D",
		X"E6",X"07",X"28",X"11",X"E6",X"03",X"3D",X"4F",X"06",X"00",X"21",X"2F",X"04",X"09",X"6E",X"60",
		X"CD",X"AA",X"01",X"AF",X"C9",X"2C",X"35",X"4E",X"CD",X"99",X"01",X"AF",X"C9",X"3D",X"C9",X"47",
		X"55",X"6B",X"AF",X"CD",X"C8",X"01",X"0E",X"0A",X"CD",X"99",X"01",X"3E",X"80",X"32",X"44",X"30",
		X"21",X"04",X"00",X"22",X"45",X"30",X"CD",X"AA",X"01",X"AF",X"C9",X"21",X"44",X"30",X"35",X"7E",
		X"28",X"0E",X"FE",X"6D",X"28",X"EA",X"2A",X"45",X"30",X"01",X"18",X"00",X"09",X"C3",X"43",X"04",
		X"3D",X"C9",X"AF",X"CD",X"C8",X"01",X"21",X"C0",X"00",X"22",X"47",X"30",X"CD",X"AA",X"01",X"0E",
		X"09",X"CD",X"99",X"01",X"AF",X"21",X"49",X"30",X"77",X"C9",X"21",X"49",X"30",X"35",X"7E",X"E6",
		X"07",X"20",X"12",X"2A",X"47",X"30",X"01",X"40",X"00",X"09",X"7C",X"FE",X"0C",X"28",X"08",X"22",
		X"47",X"30",X"CD",X"AA",X"01",X"AF",X"C9",X"3E",X"FF",X"C9",X"3E",X"01",X"CD",X"C8",X"01",X"21",
		X"4A",X"30",X"36",X"00",X"2C",X"0E",X"0F",X"71",X"CD",X"99",X"01",X"21",X"60",X"00",X"22",X"4C",
		X"30",X"AF",X"C9",X"21",X"4A",X"30",X"35",X"7E",X"E6",X"0F",X"28",X"16",X"2A",X"4C",X"30",X"FE",
		X"0C",X"01",X"10",X"00",X"30",X"03",X"01",X"D0",X"FF",X"09",X"22",X"4C",X"30",X"CD",X"AA",X"01",
		X"AF",X"C9",X"2C",X"35",X"4E",X"20",X"D1",X"3D",X"C9",X"AF",X"CD",X"C8",X"01",X"21",X"4E",X"30",
		X"36",X"B0",X"2C",X"36",X"0D",X"35",X"4E",X"CD",X"99",X"01",X"2C",X"36",X"20",X"6E",X"26",X"00",
		X"CD",X"AA",X"01",X"AF",X"C9",X"21",X"4E",X"30",X"35",X"7E",X"28",X"0C",X"2C",X"E6",X"0F",X"28",
		X"E4",X"2C",X"34",X"C3",X"ED",X"04",X"AF",X"C9",X"3D",X"C9",X"AF",X"CD",X"C8",X"01",X"21",X"50",
		X"00",X"CD",X"AA",X"01",X"21",X"51",X"30",X"36",X"40",X"2C",X"0E",X"05",X"71",X"CD",X"99",X"01",
		X"2C",X"36",X"17",X"2C",X"36",X"50",X"AF",X"C9",X"21",X"51",X"30",X"35",X"28",X"E9",X"7E",X"2C",
		X"E6",X"0F",X"20",X"05",X"34",X"4E",X"CD",X"99",X"01",X"2C",X"7E",X"C6",X"29",X"77",X"2C",X"AE",
		X"E6",X"3F",X"C6",X"50",X"77",X"6F",X"26",X"00",X"CD",X"AA",X"01",X"AF",X"C9",X"AF",X"CD",X"C8",
		X"01",X"21",X"56",X"30",X"36",X"08",X"2D",X"36",X"2C",X"2C",X"35",X"28",X"29",X"4E",X"CD",X"99",
		X"01",X"21",X"00",X"00",X"22",X"57",X"30",X"CD",X"AA",X"01",X"AF",X"C9",X"21",X"55",X"30",X"35",
		X"7E",X"28",X"E4",X"FE",X"16",X"28",X"EA",X"2A",X"57",X"30",X"01",X"10",X"00",X"09",X"22",X"57",
		X"30",X"CD",X"AA",X"01",X"AF",X"C9",X"3D",X"C9",X"3E",X"01",X"CD",X"C8",X"01",X"21",X"5C",X"30",
		X"36",X"0C",X"4E",X"CD",X"99",X"01",X"2D",X"36",X"00",X"21",X"80",X"00",X"22",X"59",X"30",X"CD",
		X"AA",X"01",X"AF",X"C9",X"21",X"5B",X"30",X"34",X"7E",X"FE",X"59",X"28",X"0F",X"4F",X"06",X"00",
		X"2A",X"59",X"30",X"09",X"22",X"59",X"30",X"CD",X"AA",X"01",X"AF",X"C9",X"2C",X"7E",X"D6",X"04",
		X"28",X"04",X"77",X"C3",X"92",X"05",X"3D",X"C9",X"3E",X"01",X"CD",X"C8",X"01",X"21",X"5D",X"30",
		X"36",X"00",X"2C",X"36",X"E0",X"2C",X"0E",X"0D",X"71",X"CD",X"99",X"01",X"2C",X"36",X"93",X"2C",
		X"36",X"D5",X"21",X"C0",X"00",X"CD",X"AA",X"01",X"AF",X"C9",X"21",X"5D",X"30",X"35",X"CB",X"46",
		X"20",X"25",X"2C",X"35",X"7E",X"28",X"22",X"FE",X"D0",X"28",X"DA",X"2C",X"E6",X"0F",X"20",X"05",
		X"35",X"4E",X"CD",X"99",X"01",X"2C",X"7E",X"C6",X"53",X"77",X"2C",X"AE",X"77",X"6F",X"FE",X"E0",
		X"38",X"01",X"AF",X"67",X"CD",X"AA",X"01",X"AF",X"C9",X"3D",X"C9",X"AF",X"CD",X"C8",X"01",X"21",
		X"62",X"30",X"36",X"00",X"2C",X"36",X"C0",X"2C",X"36",X"0D",X"35",X"4E",X"CD",X"99",X"01",X"21",
		X"20",X"00",X"22",X"65",X"30",X"CD",X"AA",X"01",X"AF",X"C9",X"21",X"62",X"30",X"35",X"7E",X"E6",
		X"01",X"20",X"17",X"2C",X"35",X"7E",X"28",X"14",X"2C",X"E6",X"0F",X"28",X"DD",X"2A",X"65",X"30",
		X"01",X"40",X"00",X"09",X"22",X"65",X"30",X"CD",X"AA",X"01",X"AF",X"C9",X"3D",X"C9",X"AF",X"CD",
		X"C8",X"01",X"0E",X"0C",X"CD",X"99",X"01",X"21",X"67",X"30",X"36",X"B8",X"2C",X"36",X"1F",X"21",
		X"1F",X"00",X"CD",X"AA",X"01",X"AF",X"C9",X"21",X"67",X"30",X"35",X"7E",X"28",X"15",X"FE",X"60",
		X"28",X"EA",X"E6",X"03",X"20",X"0B",X"2C",X"7E",X"C6",X"20",X"77",X"6F",X"26",X"00",X"CD",X"AA",
		X"01",X"AF",X"C9",X"3D",X"C9",X"3E",X"01",X"CD",X"C8",X"01",X"21",X"C0",X"00",X"CD",X"AA",X"01",
		X"0E",X"0F",X"CD",X"99",X"01",X"AF",X"21",X"69",X"30",X"77",X"2C",X"36",X"53",X"2C",X"36",X"09",
		X"2C",X"36",X"37",X"C9",X"21",X"69",X"30",X"35",X"56",X"2C",X"7E",X"C6",X"D5",X"77",X"2C",X"CB",
		X"42",X"20",X"09",X"AE",X"77",X"E6",X"EF",X"4F",X"CD",X"99",X"01",X"79",X"2C",X"AE",X"77",X"F6",
		X"80",X"6F",X"26",X"00",X"CD",X"AA",X"01",X"AF",X"C9",X"3E",X"01",X"CD",X"C8",X"01",X"21",X"6D",
		X"30",X"36",X"28",X"2C",X"36",X"05",X"2C",X"36",X"30",X"21",X"00",X"06",X"CD",X"AA",X"01",X"0E",
		X"08",X"CD",X"99",X"01",X"AF",X"C9",X"21",X"6D",X"30",X"35",X"28",X"E5",X"7E",X"E6",X"07",X"C6",
		X"08",X"4F",X"CD",X"99",X"01",X"2C",X"7E",X"C6",X"B9",X"77",X"2C",X"AE",X"77",X"6F",X"26",X"06",
		X"CD",X"AA",X"01",X"AF",X"C9",X"3E",X"01",X"CD",X"C8",X"01",X"21",X"00",X"01",X"CD",X"AA",X"01",
		X"21",X"70",X"30",X"36",X"00",X"2C",X"0E",X"0F",X"71",X"CD",X"99",X"01",X"AF",X"2C",X"77",X"2C",
		X"77",X"C9",X"21",X"70",X"30",X"35",X"7E",X"CB",X"47",X"23",X"20",X"0B",X"35",X"E6",X"10",X"20",
		X"02",X"34",X"34",X"4E",X"CD",X"99",X"01",X"2C",X"7E",X"C6",X"D3",X"77",X"2C",X"AE",X"77",X"E6",
		X"7F",X"C6",X"A8",X"6F",X"E6",X"07",X"67",X"CD",X"AA",X"01",X"AF",X"C9",X"3E",X"01",X"CD",X"C8",
		X"01",X"21",X"00",X"01",X"CD",X"AA",X"01",X"0E",X"0C",X"CD",X"99",X"01",X"AF",X"21",X"74",X"30",
		X"77",X"2C",X"77",X"C9",X"21",X"74",X"30",X"7E",X"C6",X"97",X"77",X"2C",X"AE",X"77",X"E6",X"7F",
		X"C6",X"C0",X"6F",X"26",X"01",X"CD",X"AA",X"01",X"AF",X"C9",X"3E",X"01",X"CD",X"C8",X"01",X"0E",
		X"0A",X"CD",X"99",X"01",X"21",X"76",X"30",X"36",X"30",X"2C",X"36",X"02",X"2C",X"3E",X"E0",X"77",
		X"2C",X"77",X"6F",X"26",X"00",X"CD",X"AA",X"01",X"AF",X"C9",X"21",X"76",X"30",X"35",X"7E",X"28",
		X"E6",X"2C",X"E6",X"0F",X"28",X"07",X"7E",X"2C",X"2C",X"86",X"C3",X"A1",X"07",X"34",X"34",X"2C",
		X"7E",X"D6",X"20",X"C3",X"9F",X"07",X"3E",X"01",X"CD",X"C8",X"01",X"21",X"00",X"00",X"CD",X"AA",
		X"01",X"21",X"7A",X"30",X"36",X"00",X"2C",X"0E",X"0F",X"71",X"CD",X"99",X"01",X"2C",X"36",X"45",
		X"2C",X"36",X"99",X"AF",X"C9",X"21",X"7A",X"30",X"35",X"7E",X"CB",X"47",X"20",X"19",X"2C",X"E6",
		X"3F",X"20",X"07",X"35",X"28",X"13",X"4E",X"CD",X"99",X"01",X"2C",X"7E",X"C6",X"D3",X"77",X"2C",
		X"AE",X"77",X"6F",X"67",X"CD",X"AA",X"01",X"AF",X"C9",X"3D",X"C9",X"3E",X"01",X"CD",X"C8",X"01",
		X"21",X"00",X"00",X"22",X"81",X"30",X"CD",X"AA",X"01",X"21",X"7E",X"30",X"36",X"00",X"2C",X"0E",
		X"0F",X"71",X"CD",X"99",X"01",X"2C",X"AF",X"77",X"C9",X"21",X"7E",X"30",X"35",X"7E",X"57",X"2C",
		X"E6",X"1F",X"20",X"07",X"35",X"28",X"1E",X"4E",X"CD",X"99",X"01",X"2C",X"7E",X"C6",X"C5",X"77",
		X"2A",X"81",X"30",X"AA",X"AD",X"6F",X"67",X"FE",X"80",X"30",X"02",X"26",X"01",X"22",X"81",X"30",
		X"CD",X"AA",X"01",X"AF",X"C9",X"3D",X"C9",X"3E",X"02",X"CD",X"C8",X"01",X"21",X"00",X"00",X"CD",
		X"AA",X"01",X"21",X"83",X"30",X"0E",X"0F",X"71",X"CD",X"99",X"01",X"2C",X"36",X"30",X"2C",X"36",
		X"95",X"2C",X"36",X"3D",X"21",X"70",X"00",X"22",X"87",X"30",X"22",X"89",X"30",X"AF",X"C9",X"21",
		X"84",X"30",X"35",X"7E",X"28",X"28",X"FE",X"10",X"38",X"10",X"2C",X"7E",X"C6",X"C9",X"77",X"2C",
		X"AE",X"77",X"6F",X"26",X"01",X"CD",X"AA",X"01",X"AF",X"C9",X"D6",X"10",X"ED",X"44",X"87",X"4F",
		X"06",X"00",X"2A",X"89",X"30",X"09",X"22",X"89",X"30",X"CD",X"AA",X"01",X"AF",X"C9",X"2D",X"35",
		X"28",X"1C",X"4E",X"CD",X"99",X"01",X"2C",X"3A",X"85",X"30",X"E6",X"3F",X"C6",X"30",X"77",X"2A",
		X"87",X"30",X"01",X"60",X"00",X"09",X"22",X"87",X"30",X"22",X"89",X"30",X"AF",X"C9",X"3D",X"C9",
		X"3E",X"02",X"CD",X"C8",X"01",X"21",X"00",X"00",X"CD",X"AA",X"01",X"21",X"8B",X"30",X"0E",X"0F",
		X"71",X"CD",X"99",X"01",X"2C",X"36",X"30",X"2C",X"36",X"95",X"2C",X"36",X"3D",X"21",X"38",X"00",
		X"22",X"8F",X"30",X"22",X"91",X"30",X"AF",X"C9",X"21",X"8C",X"30",X"35",X"7E",X"28",X"23",X"FE",
		X"10",X"38",X"10",X"2C",X"7E",X"C6",X"D3",X"77",X"2C",X"AE",X"77",X"6F",X"26",X"01",X"CD",X"AA",
		X"01",X"AF",X"C9",X"2A",X"91",X"30",X"01",X"30",X"00",X"09",X"22",X"91",X"30",X"CD",X"AA",X"01",
		X"AF",X"C9",X"2D",X"35",X"28",X"1C",X"4E",X"CD",X"99",X"01",X"2C",X"3A",X"8D",X"30",X"E6",X"3F",
		X"C6",X"30",X"77",X"2A",X"8F",X"30",X"01",X"06",X"00",X"09",X"22",X"8F",X"30",X"22",X"91",X"30",
		X"AF",X"C9",X"3D",X"C9",X"3E",X"01",X"CD",X"C8",X"01",X"21",X"93",X"30",X"36",X"00",X"2C",X"36",
		X"D0",X"2C",X"0E",X"0D",X"71",X"CD",X"99",X"01",X"2C",X"36",X"93",X"2C",X"36",X"D5",X"21",X"C0",
		X"00",X"CD",X"AA",X"01",X"AF",X"C9",X"21",X"93",X"30",X"35",X"7E",X"E6",X"03",X"20",X"29",X"2C",
		X"35",X"28",X"27",X"7E",X"FE",X"98",X"28",X"D9",X"FE",X"80",X"28",X"D5",X"2C",X"E6",X"0F",X"20",
		X"05",X"35",X"4E",X"CD",X"99",X"01",X"2C",X"7E",X"C6",X"53",X"77",X"2C",X"AE",X"77",X"6F",X"FE",
		X"E0",X"38",X"01",X"AF",X"67",X"CD",X"AA",X"01",X"AF",X"C9",X"3D",X"C9",X"AF",X"CD",X"C8",X"01",
		X"0E",X"09",X"CD",X"99",X"01",X"21",X"99",X"30",X"3E",X"F6",X"D6",X"06",X"77",X"D6",X"7E",X"28",
		X"1E",X"2D",X"36",X"30",X"21",X"30",X"00",X"CD",X"AA",X"01",X"AF",X"C9",X"21",X"98",X"30",X"7E",
		X"C6",X"06",X"77",X"2C",X"BE",X"28",X"E3",X"6F",X"26",X"00",X"CD",X"AA",X"01",X"AF",X"C9",X"3D",
		X"C9",X"3E",X"01",X"CD",X"C8",X"01",X"0E",X"0F",X"CD",X"99",X"01",X"21",X"9A",X"30",X"36",X"1D",
		X"2C",X"2D",X"35",X"7E",X"28",X"1A",X"2C",X"77",X"87",X"6F",X"26",X"00",X"CD",X"AA",X"01",X"AF",
		X"C9",X"21",X"9B",X"30",X"35",X"28",X"EA",X"6E",X"26",X"00",X"29",X"CD",X"AA",X"01",X"AF",X"C9",
		X"3D",X"C9",X"AF",X"CD",X"C8",X"01",X"0E",X"0A",X"CD",X"99",X"01",X"3E",X"80",X"32",X"9E",X"30",
		X"21",X"9C",X"30",X"36",X"00",X"2C",X"36",X"C0",X"21",X"C0",X"00",X"CD",X"AA",X"01",X"AF",X"C9",
		X"21",X"9C",X"30",X"35",X"CB",X"46",X"23",X"7E",X"20",X"15",X"35",X"7E",X"FE",X"20",X"28",X"18",
		X"2C",X"BE",X"3A",X"9D",X"30",X"20",X"09",X"7E",X"C6",X"05",X"77",X"2D",X"C3",X"16",X"0A",X"1F",
		X"6F",X"26",X"00",X"CD",X"AA",X"01",X"AF",X"C9",X"3E",X"FF",X"C9",X"AF",X"CD",X"C8",X"01",X"21",
		X"C0",X"00",X"CD",X"AA",X"01",X"0E",X"0F",X"CD",X"99",X"01",X"21",X"9F",X"30",X"36",X"00",X"2C",
		X"36",X"10",X"2C",X"36",X"03",X"2C",X"36",X"05",X"AF",X"C9",X"21",X"9F",X"30",X"35",X"7E",X"2C",
		X"E6",X"3F",X"20",X"03",X"35",X"28",X"19",X"E6",X"03",X"20",X"13",X"56",X"2C",X"7E",X"C6",X"05",
		X"77",X"2C",X"AE",X"E6",X"0F",X"77",X"BA",X"38",X"01",X"AF",X"4F",X"CD",X"99",X"01",X"AF",X"C9",
		X"3D",X"C9",X"97",X"01",X"E7",X"03",X"32",X"04",X"62",X"04",X"9A",X"04",X"D9",X"04",X"0A",X"05",
		X"4D",X"05",X"88",X"05",X"C8",X"05",X"1B",X"06",X"5E",X"06",X"95",X"06",X"D9",X"06",X"15",X"07",
		X"5C",X"07",X"8A",X"07",X"C6",X"07",X"0B",X"08",X"57",X"08",X"D0",X"08",X"44",X"09",X"9C",X"09",
		X"D1",X"09",X"02",X"0A",X"4B",X"0A",X"16",X"0B",X"1A",X"0B",X"3B",X"0B",X"3B",X"0B",X"3B",X"0B",
		X"3B",X"0B",X"3B",X"0B",X"00",X"00",X"02",X"04",X"4B",X"04",X"7A",X"04",X"B3",X"04",X"F5",X"04",
		X"28",X"05",X"6C",X"05",X"A4",X"05",X"EA",X"05",X"3A",X"06",X"77",X"06",X"B4",X"06",X"F6",X"06",
		X"32",X"07",X"74",X"07",X"AA",X"07",X"E5",X"07",X"29",X"08",X"7F",X"08",X"F8",X"08",X"66",X"09",
		X"BC",X"09",X"F1",X"09",X"20",X"0A",X"6A",X"0A",X"00",X"00",X"00",X"00",X"41",X"0B",X"4A",X"0B",
		X"53",X"0B",X"5C",X"0B",X"65",X"0B",X"AF",X"C3",X"1C",X"0B",X"3E",X"01",X"CD",X"7E",X"03",X"11",
		X"00",X"30",X"21",X"2F",X"0B",X"01",X"0C",X"00",X"ED",X"B0",X"E1",X"E1",X"C3",X"BF",X"00",X"1C",
		X"00",X"1D",X"00",X"1E",X"00",X"1F",X"00",X"20",X"00",X"00",X"00",X"AF",X"CD",X"C8",X"01",X"AF",
		X"C9",X"DD",X"21",X"0F",X"30",X"CD",X"FC",X"01",X"AF",X"C9",X"DD",X"21",X"19",X"30",X"CD",X"FC",
		X"01",X"AF",X"C9",X"DD",X"21",X"23",X"30",X"CD",X"FC",X"01",X"AF",X"C9",X"DD",X"21",X"2D",X"30",
		X"CD",X"FC",X"01",X"AF",X"C9",X"DD",X"21",X"37",X"30",X"CD",X"FC",X"01",X"AF",X"C9",X"82",X"0B",
		X"B2",X"0B",X"E2",X"0B",X"08",X"0C",X"2D",X"0C",X"2E",X"0C",X"70",X"0C",X"AD",X"0C",X"EB",X"0C",
		X"04",X"0D",X"1F",X"0E",X"3F",X"16",X"5F",X"00",X"81",X"60",X"5F",X"08",X"66",X"A8",X"AD",X"92",
		X"7F",X"00",X"B1",X"91",X"7F",X"FF",X"B1",X"B2",X"91",X"7F",X"00",X"D4",X"B4",X"7F",X"FF",X"B4",
		X"60",X"74",X"3F",X"13",X"77",X"76",X"74",X"74",X"73",X"71",X"71",X"70",X"6D",X"6D",X"70",X"71",
		X"AD",X"FF",X"1F",X"02",X"3F",X"16",X"5F",X"00",X"81",X"60",X"5F",X"08",X"66",X"A8",X"AD",X"92",
		X"7F",X"00",X"B1",X"91",X"7F",X"FF",X"B1",X"B2",X"91",X"7F",X"00",X"D4",X"B4",X"7F",X"FF",X"B4",
		X"60",X"74",X"3F",X"13",X"77",X"76",X"74",X"74",X"73",X"71",X"71",X"70",X"6D",X"6D",X"70",X"71",
		X"AD",X"FF",X"1F",X"0E",X"3F",X"13",X"5F",X"08",X"8D",X"6D",X"8D",X"6D",X"8D",X"6D",X"8D",X"6D",
		X"8D",X"6D",X"8D",X"6D",X"8D",X"6D",X"8D",X"6D",X"88",X"68",X"85",X"60",X"86",X"60",X"87",X"60",
		X"7F",X"00",X"CB",X"7F",X"FF",X"AB",X"AD",X"FF",X"1F",X"02",X"3F",X"13",X"5F",X"08",X"8D",X"6D",
		X"8D",X"6D",X"8D",X"6D",X"8D",X"6D",X"8D",X"6D",X"8D",X"6D",X"8D",X"6D",X"8D",X"6D",X"88",X"68",
		X"85",X"60",X"86",X"60",X"87",X"60",X"7F",X"00",X"CB",X"7F",X"FF",X"AB",X"AD",X"FF",X"1F",X"0E",
		X"3F",X"15",X"5F",X"00",X"81",X"5F",X"07",X"65",X"65",X"25",X"25",X"25",X"25",X"A5",X"85",X"65",
		X"85",X"65",X"65",X"80",X"65",X"65",X"25",X"25",X"25",X"25",X"A5",X"85",X"65",X"61",X"68",X"6C",
		X"6F",X"80",X"6A",X"6A",X"2A",X"2A",X"2A",X"2A",X"AA",X"8A",X"6A",X"8A",X"6A",X"6A",X"80",X"6A",
		X"6A",X"2A",X"2A",X"2A",X"2A",X"AA",X"8A",X"68",X"68",X"68",X"6A",X"6A",X"80",X"DF",X"37",X"0C",
		X"1F",X"0E",X"3F",X"15",X"5F",X"00",X"81",X"5F",X"07",X"68",X"68",X"28",X"28",X"28",X"28",X"A8",
		X"88",X"68",X"88",X"68",X"68",X"80",X"68",X"68",X"28",X"28",X"28",X"28",X"A8",X"88",X"A8",X"60",
		X"80",X"6D",X"6D",X"2D",X"2D",X"2D",X"2D",X"AD",X"8D",X"6D",X"8D",X"6D",X"6D",X"80",X"6D",X"6D",
		X"2D",X"2D",X"2D",X"2D",X"AD",X"8D",X"6D",X"6D",X"6D",X"AD",X"DF",X"79",X"0C",X"1F",X"0E",X"3F",
		X"15",X"5F",X"00",X"81",X"5F",X"07",X"6C",X"6C",X"2C",X"2C",X"2C",X"2C",X"AC",X"8C",X"6C",X"8C",
		X"6C",X"6C",X"80",X"6C",X"6C",X"2C",X"2C",X"2C",X"2C",X"AC",X"8C",X"AC",X"60",X"80",X"72",X"72",
		X"32",X"32",X"32",X"32",X"B2",X"92",X"72",X"92",X"72",X"72",X"80",X"72",X"72",X"32",X"32",X"32",
		X"32",X"B2",X"92",X"72",X"72",X"72",X"92",X"80",X"DF",X"B6",X"0C",X"1F",X"0E",X"3F",X"15",X"5F",
		X"00",X"E1",X"E0",X"E0",X"C0",X"A0",X"5F",X"07",X"78",X"74",X"79",X"76",X"E0",X"E0",X"E0",X"C0",
		X"A0",X"DF",X"F8",X"0C",X"1F",X"02",X"3F",X"15",X"5F",X"07",X"8D",X"60",X"6D",X"88",X"60",X"6D",
		X"60",X"6D",X"60",X"6D",X"28",X"28",X"28",X"28",X"88",X"60",X"8D",X"60",X"6D",X"88",X"60",X"6D",
		X"60",X"6D",X"60",X"6D",X"88",X"6D",X"68",X"8F",X"60",X"6F",X"8A",X"60",X"6F",X"60",X"6F",X"60",
		X"6F",X"2A",X"2A",X"2A",X"2A",X"8A",X"60",X"8F",X"60",X"6F",X"8A",X"60",X"8F",X"8F",X"6F",X"6A",
		X"6F",X"6A",X"6E",X"DF",X"0A",X"0D",X"1F",X"0E",X"3F",X"16",X"5F",X"09",X"BF",X"B3",X"B2",X"A9",
		X"B0",X"B9",X"BB",X"BA",X"AE",X"E2",X"B7",X"B3",X"B4",X"C1",X"B5",X"B9",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;