![image](http://sonoisa.github.com/ogrekit/About_%28English%29_files/OgreKitLogo.gif)

Some changes to Onigmo have been made to support all kind of linendings:
this file has been modified in the source zip of Onigmo
<----- Changes in regenc.c line 106 to 110
#define USE_CRNL_AS_LINE_TERMINATOR
#define USE_UNICODE_PROPERTIES
/* #define USE_UNICODE_CASE_FOLD_TURKISH_AZERI */
/* #define USE_UNICODE_ALL_LINE_TERMINATORS */  /* see Unicode.org UTS #18 */
------
#ifndef USE_CRNL_AS_LINE_TERMINATOR // this is set as build option in the configuration file.
#define USE_CRNL_AS_LINE_TERMINATOR = 1
#endif
#define USE_UNICODE_PROPERTIES
/* #define USE_UNICODE_CASE_FOLD_TURKISH_AZERI */
#define USE_UNICODE_ALL_LINE_TERMINATORS  /* see Unicode.org UTS #18 */
------>


Also updated OgreKits Makefile to add the --enable-crnl-as-line-terminator option
INTEL_64_CONFIGURE_FLAGS=--disable-dependency-tracking --host=x86_64-apple-darwin$(OS_VERSION) --build=x86_64-apple-darwin$(OS_VERSION) --enable-crnl-as-line-terminator
INTEL_CONFIGURE_FLAGS=--disable-dependency-tracking --host=i686-apple-darwin$(OS_VERSION) --build=i686-apple-darwin$(OS_VERSION) --enable-crnl-as-line-terminator



#OgreKit
-- OniGuruma Regular Expression Framework for Cocoa --

* **Japanese Site:** http://sonoisa.github.com/ogrekit/About.html
* **English Site:** http://sonoisa.github.com/ogrekit/About_%28English%29.html
