After build & archive go into the archive bundle in terminal and paste

pkgbuild --root Products --identifier net.subethaedit.see-tool.pkg --version 2.1.5 --sign "3rd Party Mac Developer Installer" "see-tool.pkg"

this will generate a signed installer of the seetool.

see is not sandboxed, but if we would be able too, the app store version could be shipped with it as well.


check the signatures:

pkgutil --check-signature see-tool.pkg
Package "see-tool.pkg":
   Status: signed by a developer certificate issued by Apple (Development)
   Certificate Chain:
    1. 3rd Party Mac Developer Installer: Dominik Wagner (S76GCAG929)
       Expires: 2021-11-02 11:20:42 +0000
       SHA256 Fingerprint:
           25 75 37 CA 80 7C 69 5F AC 4F E7 DA 0D 0D A7 2C 7F 92 AD 31 BA 3C
           FF 70 B5 5E FB 05 45 CC 08 A5
       ------------------------------------------------------------------------
    2. Apple Worldwide Developer Relations Certification Authority
       Expires: 2023-02-07 21:48:47 +0000
       SHA256 Fingerprint:
           CE 05 76 91 D7 30 F8 9C A2 5E 91 6F 73 35 F4 C8 A1 57 13 DC D2 73
           A6 58 C0 24 02 3F 8E B8 09 C2
       ------------------------------------------------------------------------
    3. Apple Root CA
       Expires: 2035-02-09 21:40:36 +0000
       SHA256 Fingerprint:
           B0 B1 73 0E CB C7 FF 45 05 14 2C 49 F1 29 5E 6E DA 6B CA ED 7E 2C
           68 C5 BE 91 B5 A1 10 01 F0 24
