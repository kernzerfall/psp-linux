# <div align=center> psp-linux </div>
<div align=center>
<img src="https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black" />
<img src="https://img.shields.io/badge/shell_script-%23121011.svg?logo=gnu-bash&logoColor=white" />
</div>

This is a collection of scripts and auxiliary files that I wrote since I wanted
to do the <i>Praktikum Systemprogrammierung</i> on Linux (like a normal person).
5-10 hours of extra work and configuration are way better than having to touch W\*ndows.
I'm uploading everything in case it helps someone else down the line.

## Table of Contents

1. [Dependencies](#1-dependencies)
2. [Manually building SPOS](#2-manually-building-spos)
3. [Build/Test script](#3-buildtest-script)  
    3.1 [Examples](#31-examples)  
    3.2 [QoL Tip](#32-qol-tip)
4. [Using clangd](#4-using-clangd)  
    4.1 [Configuration](#41-configuration)  
    4.2 [Updating project files](#42-updating-project-files)  
5. [VSCode](#5-using-vscode)
6. [Docker/CI](#6-dockerci)
7. [License](#7-license)

## 1. Dependencies

To build SPOS for the ATMega644, you need the following dependencies:

- avr8-gnu-toolchain ([3.6.2.1778](https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ProductDocuments/SoftwareLibraries/Firmware/avr8-gnu-toolchain-3.6.2.1778-linux.any.x86_64.tar.gz))
- ATMega644 Device Family Pack ([2.0.401](http://packs.download.atmel.com/Atmel.ATmega_DFP.2.0.401.atpack))

Since the toolchain used in the course is ancient, you probably won't find it in your distro's package manager. To
install everything needed under `/opt/avr`, you can use `scripts/setupAvrLibs.sh`. Make sure you have `curl`,
`tar` and `unzip` installed.

```bash
$ sudo ./scripts/setupAvrLibs.sh
```

Note that other scripts rely on everything being under `/opt/avr`, so you should not change the installation path.

## 2. Manually building SPOS

```bash
$ cd /path/to/SPOS
$ sed -e 's:avr-gcc:/opt/avr/gcc/bin/avr-gcc:g'         \
      -e 's:\(CFLAGS =\):\1 -I"/opt/avr/dfp/include":g' \
      Makefile | make -B -f -
```
## 3. Build/Test script

The `scripts/build_test.sh` script can be used to build and test the project. It runs under Linux and Windows
(via `git-bash`, which is preinstalled on the VMs and on the lab computers). It uses the following environment
variables:

- `WIN`: Set to `1` if you are running on Windows. This is used to determine the path to the `avr-gcc` binaries.
- `STOP`: Set to `1` if you want to stop the script after compiling each test (useful to flash the test to the device
    without waiting).
- `PUB`: Set to `1` if you want to pull the tests from a public network location (useful if you are on the lab computers).
    You can change the location inside the script (`WIN_PUB_TESTS`). The default is
```bash
WIN_PUB_TESTS="/p/public/Versuch\ $VERSUCH/Testtasks"

# Note that this is a UNIX path, since we're using git-bash.
# It corresponds to the following Windows path:

\\p\public\Versuch $VERSUCH\Testtasks
# or
P:\public\Versuch $VERSUCH\Testtasks
```

The script automatically reads the `VERSUCH` number from `${SCRIPT_DIRECTORY}/../SPOS/SPOS/defines.h`
and uses the Makefile from `${SCRIPT_DIRECTORY}/../SPOS/Makefile`. This means that it expects the
following directory structure:

```js
PROJECT_ROOT
    ????????? scripts
    ???   ????????? build_test.sh
    ???   ????????? ...
    ????????? SPOS
    ???   ????????? Makefile
    ???   ????????? ...
    ???   ????????? SPOS
    ???   ???   ????????? defines.h
    ???   ???   ????????? ...
```
When `PUB!=1`, the script expects the tests to be in `${SCRIPT_DIRECTORY}/../SPOS/Tests/V$VERSUCH/`, e. g.
`${SCRIPT_DIRECTORY}/../SPOS/Tests/V4/3 Heap Cleanup`. The directory structure **with tests** would look
as follows:

```js
PROJECT_ROOT
    ????????? scripts
    ???   ????????? build_test.sh
    ???   ????????? ...
    ????????? SPOS
    ???   ????????? Makefile
    ???   ????????? SPOS
    ???   ???   ????????? defines.h
    ???   ???   ????????? ...
    ???   ????????? Tests
    ???   ???   ????????? V1
    ???   ???   ???   ????????? 1 Hello World
    ???   ???   ???   ???   ????????? progs.c
    ???   ???   ???   ????????? 2 Hello World
    ???   ???   ???   ???   ????????? progs.c
    ???   ???   ???   ????????? ...
    ???   ???   ????????? V2
    ???   ???   ???   ????????? 1 Hello World
    ???   ???   ???   ???   ????????? progs.c
    ???   ???   ???   ????????? 2 Hello World
    ???   ???   ???   ???   ????????? progs.c
    ???   ???   ???   ????????? ...
    ???   ???   ????????? ...
```

### 3.1 Examples
1. Make sure all tests compile successfully
```bash
$ cd PROJECT_ROOT
$ ./scripts/build_test.sh
```
2. On the lab computers, pull the tests from the public network location and stop after compiling each test
to flash it to the device (*no need* to clean-build/rebuild the project, this is handled by the script).
```bash
$ cd PROJECT_ROOT
$ WIN=1 PUB=1 STOP=1 ./scripts/build_test.sh
```

### 3.2 QoL tip
The script doesn't care about the *current working directory*. You can run `git-bash` (from anywhere), write
e.g. `WIN=1 PUB=1 STOP=1` and drag-and-drop the `build_test.sh` file into the terminal, then hit Return to
run it. All that matters is that the directory structure explained above is present.

## 4. Using clangd

To use clangd, you need to install the following dependencies and configure your editor (e.g. neovim) accordingly.
This means installing a Language Server Protocol (LSP) client and configuring it to use clangd.
For neovim, you can use [mason.nvim](https://github.com/williamboman/mason.nvim).

### 4.1 Configuration
The easiest way to configure clangd after setting up your editor is by using
[rizsotto/Bear](https://github.com/rizsotto/Bear) to generate a `compile_commands.json` file.
You'll need to redo this every time you add new `*.{c,h}` files to the project.

```bash
$ cd PROJECT_ROOT
$ bear -- make -f scripts/Makefile -B
```

### 4.2 Updating project files
clangd is not happy with some of the things we do. Specifically, it does not like `__attribute__((naked))` and `PROGMEM`.

To fix this, change the following files:

```c
// Add the following to defines.h
#ifdef __clang__
#   undef  __ATTR_PROGMEM__
#   define __ATTR_PROGMEM__ __attribute__((section(".progmem1.data")))
#endif
```

```c
// In os_scheduler.c, change
ISR(TIMER2_COMPA_vect) __attribute__((naked));

// to
#ifndef __clang__
ISR(TIMER2_COMPA_vect) __attribute__((naked));
#endif
```

Note that you still need `avr-gcc` to compile SPOS. This is just to use LSP features, e.g. in neovim.

## 5. Using VSCode

To use VSCode you'll need a few more things.

- [AVR Helper extension](https://marketplace.visualstudio.com/items?itemName=Alex079.vscode-avr-helper)
- [C/C++ Extension Pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools-extension-pack)
- avrdude (consult your package manager)

After installing everything, type `^P` in VSCode and select "AVR Helper: Perform initial setup". Enter
the following things during setup (assuming you used `setupAvrLibs.sh` before).

- 1/4: `/opt/avr/gcc/bin/avr-gcc`
- 2/4: `/usr/bin/avrdude` (may vary across distributions)
- 3/4: Leave empty
- 4/4: `/opt/avr/dfp/include`

You should now be able to use IntelliSense.

## 6. Docker/CI

`scripts/build_test.sh` was written with GitLab CI in mind. It can be used to make sure the project compiles in a 
Docker container. An example Dockerfile is provided with the project. You'll need to bring your own 
runner for the RWTH GitLab instance.

1. Build and tag the image, e.g.
```bash
$ cd PROJECT_ROOT/scripts
$ docker build -t avr_builder:latest .
```

2. Update `.gitlab-ci.yml` to use your image.

## 7. License

These files are (un)licensed under [The Unlicense](https://unlicense.org/). See [license](license) for more information.
