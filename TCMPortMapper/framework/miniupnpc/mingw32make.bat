mingw32-make -f Makefile.mingw %1
if errorlevel 1 goto end
strip upnpc.exe
upx --best upnpc.exe
:end
