#!/bin/bash
# kernzerfall 2023
#
# This script compiles SPOS against all tests for the current VERSUCH
# - Optionally supports stopping between tests (via env STOP=1) to allow the
#     user to flash the test to the device
# - Can run under Windows (on VMs/Präsenz) under git-bash with env WIN=1
# - Under Windows, you also have the option to read tests from the public folder
#     using env PUB=1.
# - VERSUCH is read from defines.h
# - Tests are expected to be found under ../SPOS/Tests/Vx, where x=2,3,4,5,6

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SPOS_ROOT="${SCRIPT_DIR}/../SPOS"

# Some Windows Paths for AVR-GCC and the ATMega DFP includes
# These will get inserted to the Makefile on the fly by sed
WIN_AVR_INCLUDE="/c/Program\ Files\ \(x86\)/Atmel/Studio/7.0/packs/atmel/ATmega_DFP/1.7.374/include/"
WIN_AVR_GCC_BIN="/c/Program\ Files\ \(x86\)/Atmel/Studio/7.0/toolchain/avr8/avr8-gnu-toolchain/bin"

# Find versuch number
VERSUCH=$(grep -e VERSUCH "${SPOS_ROOT}/SPOS/defines.h" | cut -d " " -f 3)

# Public test folder under windows
WIN_PUB_TESTS="/p/public/Versuch\ $VERSUCH/Testtasks"

# make's return code will get saved here
MAKE_RET=0

make_spos(){
    if [[ "$WIN" != "1" ]]; then
        sed                                                     \
            -e 's:avr-gcc:/opt/avr/gcc/bin/avr-gcc:g'           \
            -e 's:\(CFLAGS =\):\1 -I"/opt/avr/dfp/include":g'   \
            Makefile | make -B -f -
        MAKE_RET=$?
    else
        rm -f bin/{release,debug}/progs.{o,h}
        # Make some substitutions
        # 1. GCC bins are not in PATH by default
        # 2. Add GCC Include Path to CFLAGS
        # 3. powershell only causes errors (and is unequivocally stupid and braindead)
        #       (and git-bash can also resolve UNC paths just fine)
        sed                                                     \
            -e "s:avr-gcc:\"${WIN_AVR_GCC_BIN}/avr-gcc\":g"     \
            -e "s:avr-size:\"${WIN_AVR_GCC_BIN}/avr-size\":g"   \
            -e "s:\(CFLAGS = \):\1 -I \"${WIN_AVR_INCLUDE}\":"  \
            -e "s:\(SHELL=powershell.exe\):#\1:"                \
            Makefile | make -f -
        MAKE_RET=$?
    fi
}

pfred() {
    printf "\x1b[31m$@\x1b[0m";
}

pfgreen(){
    printf "\x1b[32m$@\x1b[0m";
}

pfcyan(){
    printf "\x1b[36m$@\x1b[0m";
}

error(){
    pfred "Error: "
    printf "$@\n"
}

if [[ "$VERSUCH" == "" ]]; then
    error "VERSUCH number could not be found under $SPOS_ROOT\n"
    exit 1
fi

if [[ "$PUB" == "1" ]]; then
    readarray -t TESTS < <(compgen -G "${WIN_PUB_TESTS}/*" | sort)
else
    readarray -t TESTS < <(compgen -G "${SPOS_ROOT}/Tests/V$VERSUCH/*" | sort)
fi

if [[ "${#TESTS[@]}" -eq 0 ]]; then
    error "No tests found for VERSUCH=$VERSUCH\n"
    exit 1
fi


pushd "${SCRIPT_DIR}/.."

if [[ -f "${SPOS_ROOT}/SPOS/progs.c" ]]; then
    cp "${SPOS_ROOT}/SPOS/progs.c" "${SPOS_ROOT}/SPOS/progs.c.bak"
fi

pushd "${SPOS_ROOT}"

printf "\n\n"

for test in "${TESTS[@]}"; do
    cp "${test}/progs.c" "${SPOS_ROOT}/SPOS/progs.c"

    if [[ $? -ne 0 ]]; then
        error "Could not copy $test/progs.c"
        exit 1
    fi

    pfgreen "\nCompiling Test > "
    pfcyan "$test\n"

    make_spos
    if [[ $MAKE_RET -ne 0 ]]; then
        error "Test Failed: $test"

        if [[ -f "${SPOS_ROOT}/SPOS/progs.c.bak" ]]; then
            mv "${SPOS_ROOT}/SPOS/progs.c.bak" "${SPOS_ROOT}/SPOS/progs.c"
        fi

        exit 1
    fi

    if [[ "$STOP" == "1" ]]; then
        pfgreen "\n\nTest compiled. "
        printf "Press anything to continue"
        read -n1
    fi
done

if [[ -f "${SPOS_ROOT}/SPOS/progs.c.bak" ]]; then
    mv "${SPOS_ROOT}/SPOS/progs.c.bak" "${SPOS_ROOT}/SPOS/progs.c"
fi

popd

pfgreen "All tests for V$VERSUCH compiled successfully\n"
