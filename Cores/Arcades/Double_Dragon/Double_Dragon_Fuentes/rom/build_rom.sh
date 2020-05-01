#!/bin/bash

OUTFILE=JTDD.rom

function rom_len {
    echo $(printf "%05X" $(du --bytes $OUTFILE | cut -f 1))
}

function dump {
    printf "%-22s = 22'h%s;\n" "$1" "$(rom_len)"
    shift
    for i in $*; do
        if [ ! -e $i ]; then
            echo cannot find file $i
            exit 1
        fi
        cat $i >> $OUTFILE
    done
}

rm -f JTDD.rom
touch JTDD.rom

echo "Double Dragon 1"

dump "localparam BANK_ADDR"  21j-2-3.25 21j-3.24  21j-4-1.23 21j-4-1.23 # last one is repeated
dump "localparam MAIN_ADDR"  21j-1-5.26
dump "localparam SND_ADDR"   21j-0-1
dump "localparam ADPCM_0"    21j-6
dump "localparam ADPCM_1"    21j-7
dump "localparam CHAR_ADDR"  21j-5 21j-5 # repeated once

# Scroll
echo // Scroll
    # lower bytes
    dump "localparam SCRZW_ADDR"  21j-8 21j-9
    # upper bytes
    dump "localparam SCRXY_ADDR"  21j-i 21j-j
## Objects
echo // objects
    # lower bytes
    dump "localparam OBJWZ_ADDR" 21j-a 21j-b 21j-c 21j-d 
    # upper bytes
    dump "localparam OBJXY_ADDR" 21j-e 21j-f 21j-g 21j-h

# Not in SDRAM:
echo // FPGA BRAM:
dump "localparam MCU_ADDR"  21jm-0.ic55
dump "localparam PROM_ADDR" 21j-k-0 21j-l-0
echo // ROM length $(rom_len)

#############################################################################
echo -e "\n\nDouble Dragon 2"
OUTFILE=JTDD2.rom
rm -f JTDD2.rom
touch JTDD2.rom

dump "localparam BANK_ADDR"  26aa-03.bin 26ab-0.bin 26ac-0e.63 26ac-0e.63 # last one is repeated
dump "localparam MAIN_ADDR"  26a9-04.bin
dump "localparam SND_ADDR"   26ad-0.bin
dump "localparam SUB_ADDR"   26ae-0.bin
dump "localparam ADPCM_0"    26j6-0.bin
dump "localparam ADPCM_1"    26j7-0.bin
dump "localparam CHAR_ADDR"  26a8-0e.19

# Scroll
echo // Scroll
    # lower bytes
    dump "localparam SCRZW_ADDR"  26j4-0.bin
    # upper bytes
    dump "localparam SCRXY_ADDR"  26j5-0.bin
## Objects
echo // objects
    # lower bytes
    dump "localparam OBJWZ_ADDR" 26j0-0.bin 26j1-0.bin 26af-0.bin
    # upper bytes
    dump "localparam OBJXY_ADDR" 26j2-0.bin 26j3-0.bin 26a10-0.bin

# Not in SDRAM:
echo // FPGA BRAM:
# Priority PROM is taken from Double Dragon 1, MAME set is missing this prom in ddragon2.zip
dump "localparam PROM_ADDR" 21j-k-0 prom.16
echo // ROM length $(rom_len)
