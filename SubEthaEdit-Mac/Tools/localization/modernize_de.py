#!/usr/bin/env python3
"""Phase 1: convert the 9 duplicated, hand-translated `de.lproj/*.xib` files to the
modern Base-Internationalization model (Base xib + `de.lproj/<Name>.strings`).

For every localizable key in the current Base xib the German value is sourced, in
priority order:
  1. direct ObjectID match against the old de xib's ibtool extraction;
  2. a curated supplement (below) recovering German whose ObjectID drifted;
  3. the English->German translation memory mined from the existing de.lproj;
  4. otherwise the English source is kept and the key is reported as untranslated.

The supplement was built by pairing the old de xib's German (still present under
drifted ObjectIDs) against the current Base English. The handful of genuinely new
menu items with no prior German are drafted here and tagged DRAFT.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from strings_util import (  # noqa: E402
    APP_DIR,
    build_glossary,
    ibtool_export,
    write_strings,
)

FILES = [
    "Export",
    "FindReplace",
    "MainMenu",
    "OpenPanelAccessory",
    "OpenURLViewController",
    "PlainTextLoadProgress",
    "PrintOptions",
    "SavePanelAccessory",
    "SelectEncodingsPanel",
]

# base-xib key -> recovered German. Keyed by ObjectID to avoid escaping ambiguity.
# (R) recovered from the old de xib; (D) drafted (no prior German existed).
SUPPLEMENT = {
    "FindReplace": {
        "436.title": "Gehe",                 # R  Go
        "438.title": "Zeile:\\n",            # R  Line:
        "451.title": "Setzen",               # R  Set
        "452.title": "Tabulatorbreite:\\n",  # R  Tab Width:
    },
    "PrintOptions": {
        "188.title": "2,00", "189.title": "2,00", "190.title": "2,00", "191.title": "2,00",
        "192.title": "Oben:", "193.title": "Links:", "194.title": "Rechts:", "195.title": "Unten:",
        "196.title": "Gegenüberliegende Seiten",
        "197.title": "cm", "198.title": "cm", "199.title": "cm", "200.title": "cm",
        "201.title": "Annotieren", "202.title": "Einfärben", "203.title": "Bilder",
        "205.title": "AIM und E-Mail",
        "207.title": "Änderungsmark.", "208.title": "Geschrieben von",
        "209.title": "Annotieren", "210.title": "Einfärben",
        "211.title": "Kopfzeile", "212.title": "Dateiname", "213.title": "Datum",
        "214.title": "Pfad", "215.title": "Auswählen...", "217.title": "Größe:",
        "218.title": "2,0", "219.title": "pt", "220.title": "Zeilennum.",
        "221.title": "Small System Font Text", "222.title": "Weißer Hintergrund",
        "223.title": "Radio",
    },
    "MainMenu": {
        "640.title": "Mit URL verbinden …",                 # R  Connect to Host…
        "648.title": "Alle sperren",                        # D  Set All To Locked
        "657.title": "Änderungshervorhebung wiederherstellen",  # D  Restore Change Highlighting
        "710.title": "Code Folding", "711.title": "Code Folding",
        "712.title": "Block einblenden",                    # R  Unfold Current Block
        "713.title": "Auswahl ausblenden",                  # R  Fold Selection
        "714.title": "Block ausblenden",                    # R  Fold Current Block
        "715.title": "Alle Blöcke der obersten Ebene ausblenden",  # D  Fold All Top Level Blocks
        "716.title": "Alle Kommentare ausblenden",          # R  Fold All Comment Blocks
        "717.title": "Alle Blöcke einblenden",              # D  Unfold all Blocks
        "736.title": "Alle Blöcke einer Ebene ausblenden",  # R  Fold All Blocks at Level
        "737.title": "Alle Blöcke einer Ebene ausblenden",  # R  Fold All Blocks at Level
        "738.title": "1", "739.title": "2", "740.title": "3", "741.title": "4",
        "743.title": "6", "744.title": "7", "745.title": "8", "746.title": "9",
        "759.title": "Ebenenstreifen anzeigen",             # R  Show Folding Bar
        "796.title": "8",
        "808.title": "Alle Blöcke der aktuellen Ebene ausblenden",  # R  Fold All Blocks at Current Level
        "1065.title": "Rechtschreibung und Grammatik",      # D  Spelling and Grammar
        "1066.title": "Ersetzungen",                        # R  Substitutions
        "1067.title": "Transformationen",                   # R  Transformations
        "1072.title": "Transformationen",                   # R  Transformations
        "1073.title": "Großbuchstaben",                     # R  Make Upper Case
        "1074.title": "Kleinbuchstaben",                    # R  Make Lower Case
        "1075.title": "Anfangsbuchstaben groß",             # R  Capitalize
        "1076.title": "Ersetzungen",                        # R  Substitutions
        "1077.title": "Ersetzungsfenster einblenden",       # R  Show Substitutions
        "1080.title": "Intelligente Anführungszeichen",     # R  Smart Quotes
        "1081.title": "Intelligente Bindestriche",          # R  Smart Dashes
        "1082.title": "Intelligente Links",                 # R  Smart Links
        "1084.title": "Textersetzung",                      # D  Text Replacement
        "1085.title": "Rechtschreibung und Grammatik",      # D  Spelling and Grammar
        "1086.title": "Rechtschreibung und Grammatik einblenden",  # R  Show Spelling and Grammar
        "1087.title": "Dokument jetzt prüfen",              # R  Check Document Now
        "1089.title": "Während der Texteingabe prüfen",     # R  Check Spelling While Typing
        "1090.title": "Grammatik mit Rechtschreibung prüfen",  # D  Check Grammar With Spelling
        "1091.title": "Rechtschreibung automatisch korrigieren",  # R  Correct Spelling Automatically
        "1206.title": "Neu einrücken",                      # D  Re-Indent
        "1208.title": "Tag/Block abschließen",              # R  Close Current Tag/Block
        "CHr-Rs-4yc.title": "Link zu Mir kopieren",         # R  Copy My URL
        "F2N-aM-KUy.title": "Inkonsistente Einrückung anzeigen",  # R  Show Inconsistent Indentation
        "FzC-1a-ECe.title": "Vollbild ein",                 # R  Enter Full Screen
        "MK8-vl-kOn.title": "Eine Zeile nach unten schieben",  # R  Move Line Down
        "NpC-Zk-TuU.title": "Alle Tabs einblenden",         # R  Show All Tabs
        "QXq-qd-asB.title": "Change Log",                   # R  Change Log
        "aDB-wc-jEX.title": "Im Finder zeigen",             # R  Show in Finder
        "bN4-A0-a88.title": "Syntax hervorheben",           # D  Highlight Syntax
        "eQ2-sl-0HA.title": "Eine Zeile nach oben schieben",  # R  Move Line Up
        "gxS-Yt-d3d.title": "Problem berichten …",          # R  Report an Issue…
        "zf1-wO-8Tq.title": "Modi selbst erstellen",        # R  Creating Modes
    },
}


def main():
    glossary = build_glossary()
    total_untranslated = 0
    for name in FILES:
        base = ibtool_export(os.path.join(APP_DIR, "Base.lproj", f"{name}.xib"))
        de_map = {
            e["key"]: e["value"]
            for e in ibtool_export(os.path.join(APP_DIR, "de.lproj", f"{name}.xib"))
        }
        supp = SUPPLEMENT.get(name, {})
        out = []
        direct = curated = tm = miss = 0
        untranslated = []
        for e in base:
            key, en = e["key"], e["value"]
            if key in de_map:
                value, direct = de_map[key], direct + 1
            elif key in supp:
                value, curated = supp[key], curated + 1
            elif en in glossary:
                value, tm = glossary[en], tm + 1
            else:
                value, miss = en, miss + 1
                untranslated.append(key)
            out.append(dict(comment=e["comment"], key=key, value=value))
        dest = os.path.join(APP_DIR, "de.lproj", f"{name}.strings")
        write_strings(dest, out, encoding="utf-8")
        total_untranslated += miss
        print(f"{name:<24} keys={len(out):>4} direct={direct:>4} "
              f"curated={curated:>3} tm={tm:>3} untranslated={miss}")
        if untranslated:
            print(f"    untranslated keys: {', '.join(untranslated)}")
        # remove the now-redundant duplicated xib
        old_xib = os.path.join(APP_DIR, "de.lproj", f"{name}.xib")
        if os.path.exists(old_xib):
            os.unlink(old_xib)
    print(f"\nTotal untranslated keys remaining: {total_untranslated}")


if __name__ == "__main__":
    main()
