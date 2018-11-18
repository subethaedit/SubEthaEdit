ONIGURUMA_VERSION=Onigmo-Onigmo-5.13.5
OS_VERSION=$(shell uname -r)


INTEL_64_DIR=x86_64

INTEL_64_CONFIGURE_FLAGS=--disable-dependency-tracking --host=x86_64-apple-darwin$(OS_VERSION) --build=x86_64-apple-darwin$(OS_VERSION) --enable-crnl-as-line-terminator

INTEL_64_SDK=`xcrun --show-sdk-path`
INTEL_64_CC=/usr/bin/gcc -arch x86_64

ONIG_TARGET=libonig.la
LIBS_DIR=.libs
ONIGURUMA=libonig.a

install: all

all: $(ONIGURUMA)


$(ONIGURUMA): $(INTEL_64_DIR)/$(ONIG_TARGET)
	lipo -create $(INTEL_64_DIR)/$(LIBS_DIR)/$(@F) -output $(@F)

$(INTEL_64_DIR)/$(ONIG_TARGET): $(INTEL_64_DIR)
	cd $(@D);\
	CC="$(INTEL_64_CC)" ./configure $(INTEL_64_CONFIGURE_FLAGS);\
	perl -pi -e 's@CFLAGS = -isysroot /Developer/SDKs/MacOSX10.7.sdk -arch x86_64@CFLAGS = -isysroot $(INTEL_SDK) -arch x86_64 --mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)@' Makefile;\
	perl -pi -e 's@-dynamiclib@-dynamiclib -arch x86_64@g' libtool;\
	/usr/bin/make $(@F)

$(INTEL_64_DIR):
	unzip $(ONIGURUMA_VERSION).zip
	mv $(ONIGURUMA_VERSION) $@

clean:
	@rm -rf $(INTEL_64_DIR) $(ONIGURUMA)
