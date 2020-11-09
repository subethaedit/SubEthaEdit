ONIGURUMA_VERSION=onigmo-6.2.0
HOST_MACHINE1=$(shell /usr/bin/gcc -dumpmachine)
OS_VERSION=$(shell uname -r)
HOST_MACHINE2=$(HOST_MACHINE1:arm64%=aarch64%)
HOST_MACHINE=$(HOST_MACHINE2:20.1.0=)

INTEL_64_DIR=$(CONFIGURATION_BUILD_DIR)/x86_64
ARM_64_DIR=$(CONFIGURATION_BUILD_DIR)/arm64

INTEL_64_CONFIGURE_FLAGS=--disable-dependency-tracking --host=$(HOST_MACHINE) --build=x86_64-apple-darwin$(OS_VERSION) --enable-crnl-as-line-terminator
ARM_64_CONFIGURE_FLAGS=--disable-dependency-tracking --host=$(HOST_MACHINE) --build=aarch64-apple-darwin --enable-crnl-as-line-terminator

INTEL_64_SDK=$(shell xcrun --show-sdk-path)
INTEL_64_CC=/usr/bin/gcc -arch x86_64

ARM_64_SDK=$(shell xcrun --show-sdk-path)
ARM_64_CC=/usr/bin/gcc -arch arm64


ONIG_TARGET=libonigmo.la
LIBS_DIR=.libs
ONIGURUMA=$(CONFIGURATION_BUILD_DIR)/libonigmo.a

install: all

all: $(ONIGURUMA)


$(ONIGURUMA): $(INTEL_64_DIR)/$(ONIG_TARGET) $(ARM_64_DIR)/$(ONIG_TARGET)
	rm -f "$(@F)"
	lipo -create $(INTEL_64_DIR)/$(LIBS_DIR)/$(@F) $(ARM_64_DIR)/$(LIBS_DIR)/$(@F) -output "$(ONIGURUMA)"

$(INTEL_64_DIR)/$(ONIG_TARGET): $(INTEL_64_DIR)
	cd $(@D);\
	rm -f "$(ONIG_TARGET)";\
	CC="$(INTEL_64_CC)" ./configure $(INTEL_64_CONFIGURE_FLAGS);\
	perl -pi -e 's@CFLAGS = -isysroot /Developer/SDKs/MacOSX10.7.sdk -arch x86_64@CFLAGS = -isysroot $(INTEL_64_SDK) -arch x86_64 --mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)@' Makefile;\
	perl -pi -e 's@-dynamiclib@-dynamiclib -arch x86_64@g' libtool;\
	echo "#define USE_UNICODE_ALL_LINE_TERMINATORS 1" >> config.h;\
	/usr/bin/make "$(ONIG_TARGET)"

$(INTEL_64_DIR): $(ONIGURUMA_VERSION).tar.gz 
	rm -rf "$(INTEL_64_DIR)"
	tar -xf "$(ONIGURUMA_VERSION).tar.gz"
	mv "$(ONIGURUMA_VERSION)" "$@"
	touch "$(INTEL_64_DIR)"


$(ARM_64_DIR)/$(ONIG_TARGET): $(ARM_64_DIR)
	cd $(@D);\
	rm -f "$(ONIG_TARGET)";\
	CC="$(ARM_64_CC)" ./configure $(ARM_64_CONFIGURE_FLAGS);\
	perl -pi -e 's@CFLAGS = -isysroot /Developer/SDKs/MacOSX10.7.sdk -arch x86_64@CFLAGS = -isysroot $(ARM_64_SDK) -arch arm64 --mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)@' Makefile;\
	perl -pi -e 's@-dynamiclib@-dynamiclib -arch arm64@g' libtool;\
	echo "#define USE_UNICODE_ALL_LINE_TERMINATORS 1" >> config.h;\
	/usr/bin/make "$(ONIG_TARGET)"

$(ARM_64_DIR): $(ONIGURUMA_VERSION).tar.gz 
	rm -rf "$(ARM_64_DIR)"
	tar -xf "$(ONIGURUMA_VERSION).tar.gz"
	mv "$(ONIGURUMA_VERSION)" "$@"
	touch "$(ARM_64_DIR)"
