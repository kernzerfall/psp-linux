AVR_DFP_LIBS=/opt/avr/dfp/include

default: Versuch*/ SPOS/

*/:
	cd "$@"; \
		sed	-e 's:avr-gcc:/opt/avr/gcc/bin/avr-gcc:g' \
			-e 's:\(CFLAGS =\):\1 -I"/opt/avr/dfp/include":g' Makefile | \
			make -B -f -