#!/usr/bin/env python3
"""Shared helpers for the localization tooling.

Parse and emit Apple `.strings` files, run `ibtool` to extract the localizable
keyset of a Base xib, and build an English->German translation memory from the
existing `de.lproj` translations. Used by `modernize_de.py` (Phase 1) and
`gen_language.py` (Phase 2).
"""
import os
import re
import subprocess
import tempfile

APP_DIR = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))

# A /* comment */ followed by  "key" = "value";  (value may contain escaped quotes).
ENTRY_RE = re.compile(
    r'/\*(?P<comment>.*?)\*/\s*'
    r'"(?P<key>(?:[^"\\]|\\.)*)"\s*=\s*"(?P<value>(?:[^"\\]|\\.)*)"\s*;',
    re.DOTALL,
)
# Bare  "key" = "value";  with no preceding comment (e.g. Localizable.strings).
BARE_RE = re.compile(
    r'"(?P<key>(?:[^"\\]|\\.)*)"\s*=\s*"(?P<value>(?:[^"\\]|\\.)*)"\s*;'
)

# Source strings that must never be sent for translation: IB design-time
# placeholders, junk, sample/default values, bare URLs, tokens. The generator
# omits these keys so the running language falls back to the Base (English)
# value — correct, since none of these are user-visible (or must stay verbatim).
_BRACKETED = re.compile(r"^<[^>]*>$")
EXCLUDED_EXACT = {
    "Itemasdfasdf", "Item1", "Item3", "Item 1", "Item 2", "Item 3",
    "lorem ipsum", "OtherViews", "Text Cell", "Pop Up", "AUsers Name",
    "SEE_APP_NAME",
}


_TRIVIAL = re.compile(r"^[%@\dlud$.,:()/\sx_-]+$")


def is_translatable(value):
    """False for non-translatable placeholder/junk/url/token strings."""
    t = value.strip()
    if not t:
        return False
    if _BRACKETED.match(t):                      # <do not localize>, <feedback label>, …
        return False
    if t in EXCLUDED_EXACT:
        return False
    if t.startswith(("http://", "https://", "see://")):
        return False
    if t.endswith(".txt"):                       # DocumentName.txt, NetworkDocumentName.txt
        return False
    if "/Users/" in t and t.endswith("install.command"):  # hard-coded dev path
        return False
    return True


def is_trivial(value):
    """True for strings that need no translation (pure number / format / punctuation)."""
    return bool(_TRIVIAL.match(value.strip()))


def needs_translation(value):
    """A Base source value that should appear in the translation table."""
    return is_translatable(value) and not is_trivial(value)


def read_text(path):
    """Read a .strings file, honoring a UTF-16 BOM, else UTF-8."""
    with open(path, "rb") as f:
        raw = f.read()
    if raw[:2] in (b"\xff\xfe", b"\xfe\xff"):
        return raw.decode("utf-16")
    return raw.decode("utf-8-sig")


def detect_encoding(path):
    """Return 'utf-16' if the file has a UTF-16 BOM, else 'utf-8'."""
    with open(path, "rb") as f:
        bom = f.read(2)
    return "utf-16" if bom in (b"\xff\xfe", b"\xfe\xff") else "utf-8"


def source_from_comment(comment, prop):
    """Pull the English source for `prop` out of an ibtool comment."""
    if not prop:
        return None
    m = re.search(r"\b" + re.escape(prop) + r'\s*=\s*"((?:[^"\\]|\\.)*)"', comment)
    return m.group(1) if m else None


def parse_entries(path):
    """Ordered list of {comment, key, value, prop, source_en} for a .strings file."""
    text = read_text(path)
    out = []
    for m in ENTRY_RE.finditer(text):
        comment = m.group("comment").strip()
        key = m.group("key")
        prop = key.split(".", 1)[1] if "." in key else None
        out.append(
            dict(
                comment=comment,
                key=key,
                value=m.group("value"),
                prop=prop,
                source_en=source_from_comment(comment, prop),
            )
        )
    return out


def ibtool_export(xib_path):
    """Run `ibtool --export-strings-file` and return parsed entries (English keyset)."""
    fd, tmp = tempfile.mkstemp(suffix=".strings")
    os.close(fd)
    try:
        subprocess.run(
            ["ibtool", "--export-strings-file", tmp, xib_path],
            check=True,
            capture_output=True,
        )
        return parse_entries(tmp)
    finally:
        os.unlink(tmp)


def build_glossary():
    """English -> German map mined from the existing de.lproj translations.

    Panel `.strings` carry the English source in the ibtool comment and the
    German in the value; `Localizable.strings` frequently keys on the English
    source string itself.
    """
    de_dir = os.path.join(APP_DIR, "de.lproj")
    glossary = {}
    skip = {"ServicesMenu.strings", "SystemVersionCheck.strings", "InfoPlist.strings"}
    for name in sorted(os.listdir(de_dir)):
        if not name.endswith(".strings") or name in skip:
            continue
        path = os.path.join(de_dir, name)
        if name == "Localizable.strings":
            text = read_text(path)
            for m in BARE_RE.finditer(text):
                k, v = m.group("key"), m.group("value")
                if k and v and k != v:
                    glossary.setdefault(k, v)
            continue
        for e in parse_entries(path):
            en, de = e["source_en"], e["value"]
            if en and de and en != de and not de.startswith("[LOCALISATION MISSING"):
                glossary.setdefault(en, de)
    return glossary


def emit_strings(entries, encoding="utf-8"):
    """Serialize entries (each {comment?, key, value}) back to .strings text."""
    chunks = []
    for e in entries:
        if e.get("comment"):
            chunks.append(f"/* {e['comment']} */")
        chunks.append(f'"{e["key"]}" = "{e["value"]}";')
        chunks.append("")
    return "\n".join(chunks).rstrip("\n") + "\n"


def write_strings(path, entries, encoding="utf-8"):
    text = emit_strings(entries, encoding)
    if encoding == "utf-16":
        data = b"\xff\xfe" + text.encode("utf-16-le")
    else:
        data = text.encode("utf-8")
    with open(path, "wb") as f:
        f.write(data)
