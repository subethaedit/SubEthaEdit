@echo off
rem =======================================================================
rem Copyright (C) Microsoft Corporation.  All rights reserved.
rem  
rem THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
rem KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
rem IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
rem PARTICULAR PURPOSE.
rem ======================================================================

echo ------------------------------------------------------------------------
echo Generating strong name key ...
sn -q -k temp.snk
if errorlevel 1 goto problems

echo ------------------------------------------------------------------------
echo Compiling RssToolkit.dll ...
csc /nologo /debug+ /t:library /keyfile:temp.snk /out:RssToolkit.dll toolkit\*.cs
if errorlevel 1 goto problems

echo ------------------------------------------------------------------------
echo Removing strong name key ...
del temp.snk

echo ------------------------------------------------------------------------
echo Compiling Rssdl.exe ...
csc /nologo /debug+ /t:exe /r:RssToolkit.dll /out:Rssdl.exe rssdl\*.cs
if errorlevel 1 goto problems

echo ------------------------------------------------------------------------
echo Build completed. 

goto done

:problems
echo ---------------
echo Errors in build
echo ---------------

:done