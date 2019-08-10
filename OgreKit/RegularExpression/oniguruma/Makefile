ONIGURUMA_VERSION=onigmo-6.2.0
OS_VERSION=$(shell uname -r)


INTEL_64_DIR=x86_64

INTEL_64_CONFIGURE_FLAGS=--disable-dependency-tracking --host=x86_64-apple-darwin$(OS_VERSION) --build=x86_64-apple-darwin$(OS_VERSION) --enable-crnl-as-line-terminator

INTEL_64_SDK=`xcrun --show-sdk-path`
INTEL_64_CC=/usr/bin/gcc -arch x86_64

ONIG_TARGET=libonigmo.la
LIBS_DIR=.libs
ONIGURUMA=libonigmo.a

install: all

all: $(ONIGURUMA)


$(ONIGURUMA): $(INTEL_64_DIR)/$(ONIG_TARGET)
	rm -f "$(@F)"
	lipo -create $(INTEL_64_DIR)/$(LIBS_DIR)/$(@F) -output $(@F)

$(INTEL_64_DIR)/$(ONIG_TARGET): $(INTEL_64_DIR)
	cd $(@D);\
	rm -f "$(ONIG_TARGET)";\
	CC="$(INTEL_64_CC)" ./configure $(INTEL_64_CONFIGURE_FLAGS);\
	perl -pi -e 's@CFLAGS = -isysroot /Developer/SDKs/MacOSX10.7.sdk -arch x86_64@CFLAGS = -isysroot $(INTEL_SDK) -arch x86_64 --mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)@' Makefile;\
	perl -pi -e 's@-dynamiclib@-dynamiclib -arch x86_64@g' libtool;\
	echo "#define USE_UNICODE_ALL_LINE_TERMINATORS 1" >> config.h;\
	/usr/bin/make $(ONIG_TARGET)

$(INTEL_64_DIR): $(ONIGURUMA_VERSION).tar.gz 
	rm -rf "$(INTEL_64_DIR)"
	tar -xf $(ONIGURUMA_VERSION).tar.gz 
	mv $(ONIGURUMA_VERSION) $@
	touch "$(INTEL_64_DIR)"

clean:
	@rm -rf $(INTEL_64_DIR) $(ONIGURUMA)
