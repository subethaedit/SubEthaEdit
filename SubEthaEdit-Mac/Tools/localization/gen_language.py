#!/usr/bin/env python3
"""Phase 2: generate `<lang>.lproj/` for sv/nb/nn/da/fi from the master table.

For every Base resource (interface xibs via ibtool, plus Localizable / InfoPlist /
ServicesMenu / SystemVersionCheck / Localizable.stringsdict) each source string is
resolved against `translations.py`:

  * non-translatable (exclusion set) or trivial (number/format) -> key omitted,
    so the running language falls back to the Base (English) value;
  * translated         -> emit the translation;
  * missing from table -> emit the English source tagged `/* TODO <lang> */` so
    gaps are greppable and never silently dropped.

xib `.strings` and Localizable carry the English source in their comments
(self-documenting for reviewers). UTF-16 is preserved for the three plist-key files.
"""
import glob
import os
import plistlib
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from strings_util import (  # noqa: E402
    APP_DIR,
    escape_value,
    ibtool_export,
    needs_translation,
    read_text,
    write_strings,
)
from translations import PLURALS, T  # noqa: E402

LANGS = ["sv", "nb", "nn", "da", "fi"]
UTF16_FILES = {"InfoPlist.strings", "ServicesMenu.strings", "SystemVersionCheck.strings"}
PLAIN_STRINGS = ["Localizable.strings", *UTF16_FILES]

# optional comment, then  "key" = "value";  OR  BareKey = "value";  (InfoPlist style)
LOC_RE = re.compile(
    r'(?:/\*(?P<comment>.*?)\*/\s*)?'
    r'(?:"(?P<qkey>(?:[^"\\]|\\.)*)"|(?P<bkey>[A-Za-z_][\w.]*))'
    r'\s*=\s*"(?P<value>(?:[^"\\]|\\.)*)"\s*;',
    re.DOTALL,
)


def resolve(value, lang, gaps):
    """(escaped_value, comment_suffix) or None to omit the key."""
    if not needs_translation(value):
        return None
    entry = T.get(value)
    if entry and entry.get(lang):
        return escape_value(entry[lang]), None
    gaps.append(value)
    return value, f"TODO {lang}"


def gen_xib(name, base_entries, lang, gaps):
    out = []
    for e in base_entries:
        r = resolve(e["value"], lang, gaps)
        if r is None:
            continue
        value, todo = r
        comment = e["comment"]
        if todo:
            comment = f"{todo}: {comment}"
        out.append(dict(comment=comment, key=e["key"], value=value))
    return out


def gen_plain(name, text, lang, gaps):
    out = []
    for m in LOC_RE.finditer(text):
        r = resolve(m.group("value"), lang, gaps)
        if r is None:
            continue
        value, todo = r
        comment = (m.group("comment") or "").strip() or None
        if todo:
            comment = f"{todo}{(': ' + comment) if comment else ''}"
        out.append(dict(comment=comment, key=m.group("qkey") or m.group("bkey"), value=value))
    return out


def gen_stringsdict(base_plist, lang, gaps):
    table = PLURALS.get(lang, {})
    result = {}
    for top_key, spec in base_plist.items():
        spec = dict(spec)
        for var, sub in list(spec.items()):
            if not isinstance(sub, dict) or sub.get("NSStringFormatSpecTypeKey") != "NSStringPluralRuleType":
                continue
            forms = table.get(var, {})
            newsub = dict(sub)
            for cat in ("zero", "one", "two", "few", "many", "other"):
                if cat in newsub:
                    if forms.get(cat):
                        newsub[cat] = forms[cat]
                    else:
                        gaps.append(f"stringsdict:{var}:{cat}")
            spec[var] = newsub
        result[top_key] = spec
    return result


def main():
    base_xibs = {
        os.path.basename(p)[:-4]: ibtool_export(p)
        for p in sorted(glob.glob(os.path.join(APP_DIR, "Base.lproj", "*.xib")))
    }
    plain = {
        f: read_text(os.path.join(APP_DIR, "Base.lproj", f))
        for f in PLAIN_STRINGS
        if os.path.exists(os.path.join(APP_DIR, "Base.lproj", f))
    }
    sd_path = os.path.join(APP_DIR, "Base.lproj", "Localizable.stringsdict")
    with open(sd_path, "rb") as fh:
        base_sd = plistlib.load(fh)

    for lang in LANGS:
        gaps = []
        ldir = os.path.join(APP_DIR, f"{lang}.lproj")
        os.makedirs(ldir, exist_ok=True)

        for name, entries in base_xibs.items():
            out = gen_xib(name, entries, lang, gaps)
            if out:
                write_strings(os.path.join(ldir, f"{name}.strings"), out, "utf-8")

        for fname, text in plain.items():
            enc = "utf-16" if fname in UTF16_FILES else "utf-8"
            out = gen_plain(fname, text, lang, gaps)
            if out:
                write_strings(os.path.join(ldir, fname), out, enc)

        sd = gen_stringsdict(base_sd, lang, gaps)
        with open(os.path.join(ldir, "Localizable.stringsdict"), "wb") as fh:
            plistlib.dump(sd, fh)

        files = len([f for f in os.listdir(ldir)])
        print(f"{lang}: wrote {files} files, {len(gaps)} untranslated", end="")
        if gaps:
            uniq = sorted(set(gaps))
            print(f" ({len(uniq)} unique)")
            for g in uniq[:40]:
                print(f"    TODO {g!r}")
            if len(uniq) > 40:
                print(f"    … +{len(uniq) - 40} more")
        else:
            print()


if __name__ == "__main__":
    main()
