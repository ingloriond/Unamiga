#!/bin/bash
# Define JTROOT before sourcing this file

if (echo $PATH | grep modules/jtframe/bin -q); then
    unalias jtcore
    PATH=$(echo $PATH | sed 's/:[^:]*jtframe\/bin//g')
    PATH=$(echo $PATH | sed 's/:\.//g')
    unset VER GAME VIDEO HDL OKI
    unset JT12 JT51 CC MRA ROM CORES
fi

export JTROOT=$(pwd)
export JTFRAME=$JTROOT/modules/jtframe
# . path comes before JTFRAME/bin as setprj.sh
# can be in the working directory and in JTFRAME/bin
PATH=$PATH:.:$JTFRAME/bin
#unalias jtcore
alias jtcore="$JTFRAME/bin/jtcore"

# derived variables
if [ -e $JTROOT/cores ]; then
    CORES=$JTROOT/cores
else
    CORES=$JTROOT
fi

export ROM=$JTROOT/rom
CC=$JTROOT/cc
MRA=$ROM/mra
export MODULES=$JTROOT/modules
JT12=$MODULES/jt12
JT51=$MODULES/jt51

function swcore {
    IFS=/ read -ra string <<< $(pwd)
    j="/"
    next=0
    good=
    for i in ${string[@]};do
        if [ $next = 0 ]; then
            j=${j}${i}/            
        else
            next=0
            j=${j}$1/
        fi
        if [ "$i" = cores ]; then
            next=1
            good=1
        fi
    done
    if [[ $good && -d $j ]]; then
        cd $j
    else       
        cd $JTROOT/cores/$1
    fi
    pwd
}

if [ "$1" != "--quiet" ]; then
    echo "Use swcore <corename> to switch to a different core once you are"
    echo "inside the cores folder"
fi

# Git prompt
source $JTFRAME/bin/git-prompt.sh
export GIT_PS1_SHOWUPSTREAM=
export GIT_PS1_SHOWDIRTYSTATE=
export GIT_PS1_SHOWCOLORHINTS=
function __git_subdir {
    PWD=$(pwd)
    echo ${PWD##${JTROOT}/}
}
PS1='[$(__git_subdir)$(__git_ps1 " (%s)")]\$ '

function pull_jtframe {
    cd $JTFRAME
    git pull
    cd -
}

# check that git hooks are present
# Only the pre-commit is added automatically, the post-commit must
# be copied manually as it implies automatic pushing to the server
cp --no-clobber $JTFRAME/bin/pre-commit $JTROOT/.git/hooks/pre-commit
