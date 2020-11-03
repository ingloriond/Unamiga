#!/bin/bash

if [ ! -e zeros1k.bin ]; then
    dd if=/dev/zero of=zeros1k.bin count=2
fi

if [ ! -e zeros512.bin ]; then
    dd if=/dev/zero of=zeros512.bin count=1
fi

DUMP=
CHR_DUMP=NOCHR_DUMP
RAM_INFO=NORAM_INFO
FIRMWARE=gng_test.s
VGACONV=NOVGACONV
LOADROM=
FIRMONLY=NOFIRMONLY
MAXFRAME=
SIM_MS=1
SIMULATOR=iverilog
TOP=game_test
MIST=
MIST_PLL=
PLL_FILE=fast_pll.f
SIMFILE=sim.f
MACROPREFIX=-D
EXTRA=
SHOWCMD=
ARGNUMBER=1

rm -f test2.bin

function add_dir {
    if [ ! -d "$1" ]; then
        echo "ERROR: add_dir (sim.sh) failed because $1 is not a directory"
        exit 1
    fi
    for i in $(cat $1/$2); do
        if [ "$i" = "-sv" ]; then 
            # ignore statements that iVerilog cannot understand
            continue; 
        fi
        fn="$1/$i"
        if [ ! -e "$fn" ]; then
            (>&2 echo "Cannot find file $fn")
            exit 1
        fi
        echo $fn
    done
}

function get_named_arg {
    ARGNAME="$1"
    shift
    while [ $# -gt 0 ]; do
        if [ "$1" = "$ARGNAME" ]; then
            echo $2
            return
        fi
        shift
    done
}

# Which core is this for?
SYSNAME=$(get_named_arg -sysname $*)
MODULES=$(get_named_arg -modules $*)
PERCORE=

if [ "$MODULES" = "" ]; then
    echo "ERROR: Missing required argument -modules"
    exit 1
fi

# switch to NCVerilog if available
if which ncverilog; then
    SIMULATOR=ncverilog
    MACROPREFIX="+define+"
fi

if [ "$YM2203" = 1 ]; then
    PERCORE="$PERCORE $(add_dir $MODULES/jt12/hdl jt03.f)"
fi

if [ "$YM2149" = 1 ]; then
    PERCORE="$PERCORE $(add_dir $MODULES/jt12/jt49/hdl jt49.f)"
fi

case "$SYSNAME" in
    "")
        echo "ERROR: Needs system name. Use -sysname"
        exit 1;;
    popeye) PERCORE=$(add_dir $MODULES/jt49/hdl jt49.f)
            EXTRA="$EXTRA ${MACROPREFIX}POPEYECEN"
            ;;
esac
EXTRA="$EXTRA ${MACROPREFIX}GAME_ROM_PATH=\"${GAME_ROM_PATH}\""


while [ $# -gt 0 ]; do
case "$1" in
    "-showcmd") SHOWCMD="echo";;
    "-sysname") shift;; # ignore here
    "-modules") shift;; # ignore here
    "-w" | "-deep")
        DUMP=${MACROPREFIX}DUMP
        echo Signal dump enabled
        if [ $1 = "-deep" ]; then DUMP="$DUMP ${MACROPREFIX}DEEPDUMP"; fi
        ;;
    "-d")
        shift
        EXTRA="$EXTRA ${MACROPREFIX}$1"
        ;;
    "-frame")
        shift
        if [ "$1" = "" ]; then
            echo "Must specify number of frames to simulate"
            exit 1
        fi
        MAXFRAME="${MACROPREFIX}MAXFRAME=$1"
        echo Simulate up to $1 frames
        ;;
    #################### MiST setup
    "-mist")
        TOP=mist_test
        if [ $SIMULATOR = iverilog ]; then
            MIST=$(add_dir $MODULES/jtframe/hdl/mist mist.f)
        else
            MIST="-F $MODULES/jtframe/hdl/mist/mist.f"
        fi
        if [ -e $MODULES/jtgng_mist.sv ]; then
            # jtgng cores share a common MiST top file
            MISTTOP=$MODULES/jtgng_mist.sv
        else
            MISTTOP=../../hdl/jt${SYSNAME}_mist.sv
        fi
        MIST="$MODULES/jtframe/hdl/mist/mist_test.v $MISTTOP $MIST mist_dump.v"
        MIST="$MIST ${MACROPREFIX}MIST"
        # Add a local copy of mist_dump if it doesn't exist
        if [ ! -e mist_dump.v ]; then
            cp $MODULES/jtframe/hdl/ver/mist_dump.v .
            git add -v mist_dump.v
        fi
        ;;
    #################### MiSTer setup
    "-mister")
        TOP=mister_test
        if [ $SIMULATOR = iverilog ]; then
            MIST=$(add_dir $MODULES/jtframe/hdl/mister mister.f)
        else
            MIST="-F $MODULES/jtframe/hdl/mister/mister.f"
        fi
        if [ -e $MODULES/jtgng_mister.sv ]; then
            # jtgng cores share a common MiST top file
            MISTTOP=$MODULES/jtgng_mister.sv
            # Check if the conf_str.v file is present
            # and try to link to it if it is not here
            if [ ! -e conf_str.v ]; then
                if [ -e ../../mist/conf_str.v ]; then
                    ln -s ../../mist/conf_str.v
                fi
            fi
        else
            MISTTOP=../../hdl/jt${SYSNAME}_mister.sv
        fi
        MIST="$MODULES/jtframe/hdl/mister/mister_test.v $MISTTOP $MIST mister_dump.v"
        MIST="$MIST ${MACROPREFIX}MISTER"
        # Add a local copy of mist_dump if it doesn't exist
        if [ ! -e mister_dump.v ]; then
            cp $MODULES/jtframe/hdl/ver/mister_dump.v .
            git add -v mister_dump.v
        fi
        SIMFILE=sim_mister.f
        PLL_FILE=fast_pll_mister.f
        # Generate a fake build_id.v file
        echo "\`define BUILD_DATE \"190311\"" > build_id.v
        echo "\`define BUILD_TIME \"190311\"" >> build_id.v
        ;;
    ##########################
    "-slowpll")
        echo "INFO: Simulation will use the slow PLL model"
        MIST_PLL=altera_pll.f
        PLL_FILE="slow_pll.f"
        EXTRA="$EXTRA ${MACROPREFIX}SLOWPLL"
        ;;
    "-nosnd")
        EXTRA="$EXTRA ${MACROPREFIX}NOSOUND";;
    "-nocolmix")
        EXTRA="$EXTRA ${MACROPREFIX}NOCOLMIX";;
    "-noscr")
        EXTRA="$EXTRA ${MACROPREFIX}NOSCR";;
    "-nochar")
        EXTRA="$EXTRA ${MACROPREFIX}NOCHAR";;
    "-time")
        shift
        if [ "$1" = "" ]; then
            echo "Must specify number of milliseconds to simulate"
            exit 1
        fi
        SIM_MS="$1"
        echo Simulate $1 ms
        ;;
    "-firmonly")
        FIRMONLY=FIRMONLY
        echo Firmware dump only
        ;;
    "-t")
        # is there a file name?
        if [[ "${2:0:1}" != "-" && $# -gt 1  ]]; then
            shift
            FIRMWARE=$1
        else
            FIRMWARE=bank_check.s
        fi
        echo "Using test firmware $FIRMWARE"
        LOADROM="${MACROPREFIX}TESTROM ${MACROPREFIX}FIRMWARE_SIM"
        if ! z80asm $FIRMWARE -o test.bin -l &> $FIRMWARE.lst; then
            cat $FIRMWARE.lst
            exit 1
        fi
        ;;
    "-t2")
        # is there a file name?
        if [[ "${2:0:1}" != "-" && $# -gt 1  ]]; then
            shift
            FIRMWARE2=$1
        else
            FIRMWARE2=bank_check.s
        fi
        echo "Using test firmware $FIRMWARE2 for second CPU"
        LOADROM=${MACROPREFIX}TESTROM
        if ! z80asm $FIRMWARE2 -o test2.bin -l; then
            exit 1
        fi
        ;;
    "-info")
        RAM_INFO=RAM_INFO
        echo RAM information enabled
        ;;
    "-video")
        EXTRA="$EXTRA ${MACROPREFIX}DUMP_VIDEO"
        echo Video dump enabled
        rm -f video.bin
        rm -f *png
        VIDEO_DUMP=TRUE
        ;;
    "-load")
        LOADROM=${MACROPREFIX}LOADROM
        echo ROM load through SPI enabled
        if [ ! -e $GAME_ROM_PATH ]; then
            echo "Missing file $GAME_ROM_PATH"
            exit 1
        fi
        ;;
    "-lint")
        SIMULATOR=verilator;;
    "-nc")
        SIMULATOR=ncverilog
        MACROPREFIX="+define+"
        if [ $ARGNUMBER != 1 ]; then
            echo "ERROR: -nc must be the first argument so macros get defined correctly"
            exit 1
        fi
        ;;
    "-help")
        cat << EOF
JT_GNG simulation tool. (c) Jose Tejada 2019, @topapate
    -sysname  Specify the name of the core
    -modules  Location of the modules folder with respect to the simulation folder
    -mist     Use MiST setup for simulation, instead of using directly the
              game module. This is slower but more informative.
    -video    Enable video output
    -lint     Run verilator as lint tool
    -nc       Select NCVerilog as the simulator
    -load     Load the ROM file using the SPI communication. Slower.
    -t        Compile and load test file for main CPU. It can be used with the
              name of an assembly language file.
    -t2       Same as -t but for the sound CPU
    -nochar   Disable CHAR hardware. Faster simulation.
    -noscr    Disable SCROLL hardware. Faster simulation.
    -nosnd    Disable SOUND hardware. Speeds up simulation a lot!
    -w        Save a small set of signals for scope verification
    -deep     Save all signals for scope verification
    -frame    Number of frames to simulate
    -time     Number of milliseconds to simulate
    -slowpll  Simulate using Altera's model for PLLs
    -showcmd  Display the simulation command only. Do not run any simulation.
    -d        Add specific Verilog macros for the simulation. Common options
        VIDEO_START=X   video output will start on frame X
        DUMP_START=X    waveform dump will start on frame X
        TESTSCR1        disable scroll control by the CPU and scroll the
                        background automatically. It can be used together with
                        NOMAIN macro
        SDRAM_DELAY=X   ns delay for SDRAM_CLK (cannot use with -slowpll)
        BASE_CLK=X      Base period for game clock (cannot use with -slowpll)
        SIM_SCANDOUBLER Simulate scan doubler
        SIMULATE_OSD    Simulate OSD display
        SIMINFO         Show simulation options available thorugh define commands
        SCANDOUBLER_DISABLE=1   Disables the scan doubler module
EOF
        exit 0
        ;;
    *) echo "Unknown option $1. Use -help to see the list of options"; exit 1;;
esac
    shift
    ARGNUMBER=$((ARGNUMBER+1))
done

if [ $FIRMONLY = FIRMONLY ]; then exit 0; fi

# Use this function to create
# HEX files with initial contents for some of the RAMs
function clear_hex_file {
    cnt=0
    rm -f $1.hex
    while [ $cnt -lt $2 ]; do
        echo 0 >> $1.hex
        cnt=$((cnt+1))
    done
}

if [ "$EXTRA" != "" ]; then
    echo Verilog macros: "$EXTRA"
fi

EXTRA="$EXTRA ${MACROPREFIX}MEM_CHECK_TIME=$MEM_CHECK_TIME ${MACROPREFIX}SYSTOP=jt${SYSNAME}_mist"
# macros for MiST
EXTRA="$EXTRA ${MACROPREFIX}GAMETOP=jt${SYSNAME}_game ${MACROPREFIX}MISTTOP=jt${SYSNAME}_mist"

# Add the PLL (MiST only)
if [[ $TOP = mist_test || $TOP = mister_test ]]; then
    if [ "$MIST_PLL" != "" ]; then
        # Adds the Altera file with the PLL models
        if [ $SIMULATOR = iverilog ]; then
            MIST="$MIST $(add_dir $MODULES/jtframe/hdl/mist $MIST_PLL)"
        else
            MIST="$MIST -F $MODULES/jtframe/hdl/mist/$MIST_PLL"
        fi
    fi
    # Adds the .f file with the PLL modules
    if [ $SIMULATOR = iverilog ]; then
        MIST="$MIST $(add_dir . $PLL_FILE)"
    else
        MIST="$MIST -F $PLL_FILE"
    fi
fi

case $SIMULATOR in
iverilog)
    $SHOWCMD iverilog -g2005-sv $MIST \
        -f game.f $PERCORE \
        $(add_dir $MODULES/jtframe/hdl/ver $SIMFILE ) \
        $MODULES/jtframe/hdl/cpu/tv80/*.v  \
        -s $TOP -o sim -DSIM_MS=$SIM_MS -DSIMULATION \
        $DUMP -D$CHR_DUMP -D$RAM_INFO -D$VGACONV $LOADROM \
        $MAXFRAME -DIVERILOG $EXTRA \
    && $SHOWCMD sim -lxt;;
ncverilog)
    $SHOWCMD ncverilog +access+r +nc64bit +define+NCVERILOG \
        -f game.f $PERCORE \
        -F $MODULES/jtframe/hdl/ver/$SIMFILE -disable_sem2009 $MIST \
        +define+SIM_MS=$SIM_MS +define+SIMULATION \
        $DUMP $LOADROM \
        $MAXFRAME \
        -ncvhdl_args,-V93 $MODULES/t80/T80{pa,_ALU,_Reg,_MCode,"",s}.vhd \
        $MODULES/jtframe/hdl/cpu/tv80/*.v \
        $EXTRA;;
verilator)
    $SHOWCMD verilator -I../../hdl \
        -f game.f $PERCORE \
        $MODULES/tv80/*.v \
        $MODULES/ver/quick_sdram.v \
        --top-module jt${SYSNAME}_game -o sim \
        $DUMP -D$CHR_DUMP -D$RAM_INFO -D$VGACONV $LOADROM -DFASTSDRAM \
        -DVERILATOR_LINT \
        $MAXFRAME -DSIM_MS=$SIM_MS --lint-only $EXTRA;;
esac

if [ "$VIDEO_DUMP" = TRUE ]; then
    #$MODULES/jtframe/bin/bin2png.py $BIN2PNG_OPTIONS
    rm -f video*.raw
    $MODULES/jtframe/bin/bin2raw
    for i in video*.raw; do
        convert $CONVERT_OPTIONS -size 256x224 \
            -depth 8 RGBA:$i $(basename $i .raw).png && rm $i
    done
fi
