All credits and greetings to the Multicore team
https://gitlab.com/victor.trucco/Multicore/-/blob/master/System/STM32/docs/USAGE.md

# How to use

## Preparing SD Card

The SD Card must be formatted as FAT type (FAT16/FAT32/exFAT) as single partition.

## Cores

The loaded binary files are called "Cores".

Each Core has an extension which corresponds to it's own device:

- `MC2` : Multicore 2
- `MCP` : Multicore 2 Plus
- `NP1` : NeptUno
- `RBF` : UNAMIGA 
- `UA2` : UNAMIGA 2
- `ARC` : Unified launcher

The Core' selection screen shows only the Cores and `ARC`'s, it filters all
other files.

Obs.: A Core binary doesn't work on other devices, only on it's own device.

## INI File

INI file is generated when Core's menu is open (F12) and closed.

### INI Options

- `OPTIONS`: Saves all previous selected menu's options. It's generated after
opening and closing the menu F12;
- `ROOT`: Defines the Core's ROOT directory. When you select an "Load" option on
menu, the configured directory on this option will be the ROOT;
- `LAST`: Last open directory. The system updates this option when detects a
directory change. Good to find the last opened directory when loading your files;
- `LOAD_IMAGE`: Loads an image file after Core's loading. Use when loading HDD images;
- `DIS_SD`: Disables SD to let some Cores to take control of SD card (Ex: SMX). Do not require a parameter;

## Unified launcher (ARC)

The launcher is a text file with some extra configurations to load Cores.

Also, the launcher loads only binaries for the specified device:

- `CR2` : Multicore 2
- `CRP` : Multicore 2 Plus
- `CNU` : NeptUno
- `CA2` : UNAMIGA 
- `CA1` : UNAMIGA 2

Inside the launcher, the options:

- `RBF`: The binary to load, without extension. It'll find the specific extension for the machine (CR2, CRP, CNU, CA2);
- `CONF`: It's used to add extra configurations on some Cores. Look at examples on Millipede/Centipede's Cores;
- `MOD`: MOD option, to assign a hardware number (core variant);
- `LOAD_DATA`: Pump extra data after Core's loading;
- `NAME`: Define alternative Core's name. It also loads the data file (.dat) with the same NAME;
- `DEFAULT`: Sets the default options in Hexadecimal format;
- `DEFAULT_OPT`: Sets the default options;

Examples:

```
[ARC]
RBF=JTHIGE
MOD=2
NAME=Pirate Ship Higemaru
CONF="OGI,Coin A,Free Play,5/1,4/1,3/1,2/1,1/3,1/2,1/1"
CONF="OJL,Coin B,Free Play,5/1,4/1,3/1,2/1,1/3,1/2,1/1"
CONF="OMN,Lives,5,2,1,3"
CONF="OO,Cabinet,Upright,Cocktail"
CONF="OPR,Bonus Life,None,40k 100k 100k+,30k 80k 80k+,30k 70k 70k+,20k 70k 70k+,20k 60k 60k+,10k 60k 60k+,10k 50k 50k+"
CONF="OS,Demo Sounds,Off,On"
CONF="OT,Demo Music,Off,On"
CONF="OU,Flip Screen,On,Off"
```

```
[ARC]
RBF=cps1
MOD=120
NAME=Street Fighter Alpha
LOAD_DATA=sfa.dat
DEFAULT_OPT=0,16,40,0,0,96,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
```

```
[ARC]
RBF=cps1
NAME=1941 Counter Attack
LOAD_DATA=1941.dat
DEFAULT=0xBC2C3F00
MOD=1
CONF="O8A,Coin A,4c/1cr,3c/1cr,2c/1cr,1c/6cr,1c/4cr,1c/3cr,1c/2cr,1c/1cr"
CONF="OBD,Coin B,4c/1cr,3c/1cr,2c/1cr,1c/6cr,1c/4cr,1c/3cr,1c/2cr,1c/1cr"
CONF="OE,2 to Start, 1 to Cont.,On,Off"
CONF="OGI,Difficulty,7 (Hardest),6,5,4,3 (Normal),2,1,0 (Easiest)"
CONF="OJK,Level Up Timer,Quickly,Quick,Slow,Slowly"
CONF="OLM,Bullet's Speed,Very Fast,Fast,Slow,Very Slow"
CONF="ON,Health,4 Bars,3 Bars"
CONF="OO,Throttle,Off,On"
CONF="OQ,Free Play,On,Off"
CONF="OR,Freeze,On,Off"
CONF="OS,Flip Screen,On,Off"
CONF="OT,Demo Sounds,On,Off"
CONF="OU,Continue,Yes,No"
CONF="OV,Game Mode,Test,Game"
```

```
[ARC]
RBF=cps1
NAME=Captain Commando
DEFAULT=0xBDD40700
MOD=0
CONF="O8A,Coinage,4c/1cr,3c/1cr,2c/1cr,1c/6cr,1c/4cr,1c/3cr,1c/2cr,1c/1cr"
CONF="OEF,2 to Start, 1 to Cont.,On,Off"
CONF="OGI,Difficulty 1,8 (Hardest),7,6,5,4 (Normal),3,2,1 (Easiest)"
CONF="OJK,Difficulty 2,Hardest,Hard,Normal,Easy"
CONF="OMN,Play Mode,4 Players,1 Players,3 Players,2 Players"
CONF="OOP,Lives,1,4,3,2"
CONF="OQ,Free Play,On,Off"
CONF="OR,Freeze,On,Off"
CONF="OS,Flip Screen,On,Off"
CONF="OT,Demo Sounds,On,Off"
CONF="OU,Continue,Yes,No"
CONF="OV,Game Mode,Test,Game"
```

```
[ARC]
RBF=CENTI
NAME=Centipede
CONF="P1CD,Bonus Life,10000,12000,15000,20000"
CONF="P1OE,Difficulty,Hard,Easy"
CONF="P1OF,Credit minimum,1,2"
CONF="P1OGH,Coinage,Free Play,1C_2C,1C_1C,2C_1C"
CONF="P1OIK,Game Time,Untimed,1 min,2 min,3 min,4 min,5 min,6 min,7 min"
CONF="P1OLN,Bonus Coins,None,3cr/2c,5cr/4c,6cr/4c,6cr/5c,4cr/3c"
```

```
[ARC]
RBF=CENTI
NAME=Millipede
CONF="P1OE,Credit minimum,1,2"
CONF="P1OF,Coin Counters,1,2"
CONF="P1OG,Millipede Head,Easy,Hard"
CONF="P1OH,Beetle,Easy,Hard"
CONF="P1OIJ,Lives,2,3,4,5"
CONF="P1OKL,Bonus Life,12000,15000,20000"
CONF="P1OM,Spider,Easy,Hard"
CONF="P1ON,Starting Score Select,On,Off"
CONF="P1OOP,Coinage,Free Play,1C_2C,1C_1C,2C_1C"
CONF="P1OQR,Right Coin,*1,*4,*5,*6"
CONF="P1OS,Left Coin,*1,*2"
CONF="P1OTV,Bonus Coins,None,3cr/2c,5cr/4c,6cr/4c,6cr/5c,4cr/3c,Demo Mode"
```
