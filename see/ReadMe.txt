After build & archive go into the archive bundle in terminal and paste

pkgbuild --root Products --identifier net.subethaedit.see-tool.pkg --version 2.1.2 --sign "3rd Party Mac Developer Installer" "see-tool.pkg"

this will generate a signed installer of the seetool.

see is not sandboxed, but if we would be able too, the app store version could be shipped with it as well.
