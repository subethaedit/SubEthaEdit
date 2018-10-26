#!/bin/sh

plutil -remove UTImportedTypeDeclarations Info.plist 
plutil -remove UTExportedTypeDeclarations Info.plist 
plutil -remove CFBundleDocumentTypes Info.plist 

tomlutil Info.plist | cat - DocumentTypes-InfoPlist.toml | tomlutil - -f xml1 Info.plist
