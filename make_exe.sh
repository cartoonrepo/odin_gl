#!/bin/bash

# how to use it: ./make_exe.sh debug run
# options: debug release run clean hold
cd "$(dirname "$0")"

#---------------------------------------------------------------
project_name="game"
build_dir="build"

source="5.0_coordinate_systems"

# collection="-collection:util=utils"

vet="-vet-shadowing -vet-using-stmt -strict-style"
debug_flags="-debug -o:none -keep-executable $vet"
release_flags="-o:speed -strict-style -vet"
#---------------------------------------------------------------

# colors
red='\033[0;31m'
blue='\033[0;34m'
no_color='\033[0m'

print() {
    local color=$2
    if [ -z $color ]; then color=$blue; fi
    echo -e "${color}$1${no_color}"
}

clean() {
    print "Deleted all files in build directory."
    rm -f $build_dir/*
}

build_check() {
    if [ $? -eq 0 ]; then
        print "$2 build successful."
    else
        print "$2 build failed." $red
        read -p "Press [Enter] to continue."
    fi
}

build() {
    if [ ! -d "$source" ]; then print "source directory '$source' does not exits." $red && read -p "Press [Enter] to close." && exit; fi
    if [ "$run" == true ]; then command="run"; else command="build"; fi

    odin $command $source -out:$output $flags $collection

    # we pass $? exit status of compiler to check if build is success or not.
    # $1 for string "Debug" / "Release"
    build_check $? $1
}

debug_build() {
    output=$build_dir/${project_name}_debug
    flags=$debug_flags
    build "Debug"
}

release_build() {
    output=$build_dir/$project_name
    flags=$release_flags
    build "Release"
}

# make buid directory if not exits.
if [ ! -d "$build_dir" ]; then mkdir $build_dir ;fi

for arg in "$@"; do
    if [ "$arg" == "debug" ];   then debug=true   ;fi
    if [ "$arg" == "release" ]; then release=true ;fi
    if [ "$arg" == "run" ];     then run=true     ;fi
    if [ "$arg" == "clean" ];   then clean=true   ;fi
    if [ "$arg" == "hold" ];    then hold=true    ;fi
done

if [ "$clean" == true ];   then clean         ;fi
if [ "$debug" == true ];   then debug_build   ;fi
if [ "$release" == true ]; then release_build ;fi

# don't pass hold argument if you don't need
if [ "$hold" == true ]; then read -p "Press [Enter] to close." ;fi
