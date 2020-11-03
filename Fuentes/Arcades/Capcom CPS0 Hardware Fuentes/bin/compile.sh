#!/bin/bash

function show_usage() {
    cat << EOF
JT_GNG compilation tool. (c) Jose Tejada 2019, @topapate
    First argument is the project name, like jtgng, or jt1943

    -skip   skips compilation and goes directly to prepare the release file
            using the RBF file available.
    -git    adds the release file to git
    -prog   programs the FPGA
    -zip    all arguments from that point on will be used as inputs to the
            zip file. All files must be referred to $JTGNG_ROOT path
    -help   displays this message
EOF
   exit 0
}

# Is the root folder environment variable set

if [ "$JTGNG_ROOT" = "" ]; then
    echo "ERROR: Missing JTGNG_ROOT environment variable. Define it to"
    echo "point to the github jt_gng folder path."
    exit 1
fi

# Is the project defined?
PRJ=$1
shift

case "$PRJ" in
    "")
        echo "ERROR: Missing project name."
        echo "Usage: compile.sh project_name "
        exit 1;;
    "-help")
        show_usage;;
esac


ZIP=TRUE
GIT=FALSE
PROG=FALSE
SKIP_COMPILE=FALSE

while [ $# -gt 0 ]; do
    case "$1" in
        "-skip") SKIP_COMPILE=TRUE;;
        "-git") GIT=TRUE;;
        "-prog") PROG=TRUE;;
        "-prog-only") 
            PROG=TRUE
            ZIP=FALSE
            SKIP_COMPILE=TRUE;;
        "-zip") shift; break;;
        "-help")
            show_usage;;
        *)  echo "ERROR: Unknown option $1";
            exit 1;;
    esac
    shift
done

# qsf line to disable SOUND synthesis
# set_global_assignment -name VERILOG_MACRO "NOSOUND=<None>"

echo =======================================
echo jt$PRJ compilation starts at $(date +%T)

if [ $SKIP_COMPILE = FALSE ]; then
    # Update message file
    jt${PRJ}_msg.py
    # Recompile
    cd $JTGNG_ROOT/$PRJ/mist
    mkdir -p $JTGNG_ROOT/log
    quartus_sh --flow compile jt$PRJ > $JTGNG_ROOT/log/jt$PRJ.log
    if ! grep "Full Compilation was successful" $JTGNG_ROOT/log/jt$PRJ.log; then
        grep -i error $JTGNG_ROOT/log/jt$PRJ.log -A 2
        echo "ERROR while compiling the project. Aborting"
        exit 1
    fi
fi

if [ $ZIP = TRUE ]; then
    # Rename output file
    cd $JTGNG_ROOT
    RELEASE=jt${PRJ}_mist_$(date +"%Y%m%d")
    RBF=$PRJ/mist/jt$PRJ.rbf
    if [ ! -e $RBF ]; then
        echo "ERROR: file $RBF does not exist. You need to recompile."
        exit 1
    fi
    cp $RBF $RELEASE.rbf
    zip --update --junk-paths releases/${RELEASE}.zip ${RELEASE}.rbf README.txt $*
    rm $RELEASE.rbf

    if [ -e rom/$PRJ/build_rom.ini ]; then
        zip --junk-paths releases/$RELEASE.zip rom/build_rom.sh rom/$PRJ/build_rom.ini
    fi

    function add_ifexists {
        if [ -e $1 ]; then
            zip --junk-paths releases/$RELEASE.zip $1
        fi   
    }

    add_ifexists doc/jt$PRJ.txt
    add_ifexists rom/build_rom_$PRJ.bat
fi

# Add to git
if [ $GIT = TRUE ]; then
    git add -f $PRJ/mist/msg.hex
    git add releases/$RELEASE.zip
fi

if [ $PROG = TRUE ]; then
    quartus_pgm -c "USB-Blaster(Altera) [1-1.2]" $JTGNG_ROOT/$PRJ/mist/jt$PRJ.cdf
fi

echo completed at $(date)