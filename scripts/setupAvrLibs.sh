#!/bin/bash
# kernzerfall 2022


##### Installation paths #####
LIBS_INSTALL_PATH=/opt/avr

# Local downloads
DFP_PACK=dfp.zip
AVR8_GCC=avr8_gcc.tar.gz

curl                                                                                                            \
    -o "$DFP_PACK"   -L http://packs.download.atmel.com/Atmel.ATmega_DFP.2.0.401.atpack                         \
    -o "$AVR8_GCC"   -L https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ProductDocuments/SoftwareLibraries/Firmware/avr8-gnu-toolchain-3.6.2.1778-linux.any.x86_64.tar.gz

rm -r dfp
mkdir -p dfp /opt/avr

unzip "$DFP_PACK" -d dfp
tar xvzf "${AVR8_GCC}" -C "${LIBS_INSTALL_PATH}"

mv      "${LIBS_INSTALL_PATH}/$(tar tf avr8_gcc.tar.gz | head -n 1)" \
	"${LIBS_INSTALL_PATH}/gcc"

find ./dfp -print -type f -exec install -Dm 755 "{}" "${LIBS_INSTALL_PATH}/{}" \;

rm -rf dfp 
