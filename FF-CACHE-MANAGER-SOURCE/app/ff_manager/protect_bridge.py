import hashlib
import json
import sys
from pathlib import Path

import lief


PUBLIC_SYMBOLS = {
    "_MCMFilzaStart": "_FKX0A7Q2M9Z",
    "_MCMFilzaDataContainerPath": "_FKX1R4V8N6P",
    "_MCMFilzaSetUnrestrictedFilesystem": "_FKX2C5J9T3W",
    "_MCMFilzaVirtualRoot": "_FKX3D8H4K7R",
}

ARM64_RET = bytes.fromhex("c0035fd6")


def should_scrub_release_string(value):
    lower = value.lower()
    return (
        lower.startswith((b"[tweak]", b"[wallpaperlab]", b"[containerarchive]", b"[mcmfilza]"))
        or b"research" in lower
        or b" for test" in lower
        or lower.startswith((b"filza_paste_probe", b"filza_write_probe", b"filza_generated_delete_probe"))
        or lower.startswith((b".filza-mod-paste-", b".filza-mod-write-probe"))
        or lower in {
            b"canary app data", b"canary app data tmp", b"inspect source", b"open source",
            b"probe setup does not create or modify target files. the custom filza copy/paste route is disabled inside this folder.",
        }
    )


def harden_slice(binary):
    tweak = binary.get_symbol("_TweakInit")
    text = binary.get_section("__text")
    if tweak is None or text is None:
        raise RuntimeError("Bridge constructor or text section is missing")
    tweak_offset = tweak.value - text.virtual_address
    text_content = bytearray(text.content)
    if tweak_offset < 0 or tweak_offset + len(ARM64_RET) > len(text_content):
        raise RuntimeError("Bridge constructor is outside __text")
    text_content[tweak_offset:tweak_offset + len(ARM64_RET)] = ARM64_RET
    text.content = list(text_content)

    scrubbed = 0
    cstrings = binary.get_section("__cstring")
    if cstrings is None:
        raise RuntimeError("Bridge cstring section is missing")
    content = bytearray(cstrings.content)
    cursor = 0
    while cursor < len(content):
        end = content.find(b"\0", cursor)
        if end < 0:
            end = len(content)
        value = bytes(content[cursor:end])
        if value and should_scrub_release_string(value):
            content[cursor:end] = b"\0" * (end - cursor)
            scrubbed += 1
        cursor = end + 1
    cstrings.content = list(content)
    return scrubbed


def opaque_symbol(name):
    return "_Q" + hashlib.sha256(name.encode("utf-8")).hexdigest()[:14].upper()


def section_digest(binary):
    payload = bytearray()
    for section in binary.sections:
        content = bytes(section.content)
        if content:
            payload.extend(content)
    return hashlib.sha256(payload).hexdigest()

def exported_names(fat_binary):
    return [{symbol.name for symbol in binary.exported_symbols} for binary in fat_binary]


def digest(values):
    return hashlib.sha256(bytes(values)).hexdigest()


def main():
    if len(sys.argv) != 4:
        raise SystemExit("usage: protect_bridge.py INPUT OUTPUT METADATA_JSON")
    source = Path(sys.argv[1])
    destination = Path(sys.argv[2])
    metadata_path = Path(sys.argv[3])
    fat_binary = lief.MachO.parse(source)
    if fat_binary is None or len(fat_binary) != 2:
        raise RuntimeError("Expected the supplied two-slice arm64/arm64e bridge")

    changed = 0
    scrubbed = 0
    for binary in fat_binary:
        present = {symbol.name for symbol in binary.exported_symbols}
        missing = sorted(set(PUBLIC_SYMBOLS) - present)
        if missing:
            raise RuntimeError(f"Missing expected bridge exports: {missing}")
        scrubbed += harden_slice(binary)
        for symbol in binary.exported_symbols:
            symbol.name = PUBLIC_SYMBOLS.get(symbol.name, opaque_symbol(symbol.name))
            changed += 1

    if changed < len(PUBLIC_SYMBOLS) * len(fat_binary) or scrubbed < 6:
        raise RuntimeError(f"Bridge hardening was incomplete: exports={changed} strings={scrubbed}")
    fat_binary.write(str(destination))

    verified = lief.MachO.parse(destination)
    if verified is None or len(verified) != len(fat_binary):
        raise RuntimeError("Protected bridge could not be reopened")
    metadata = []
    for index, (binary, names) in enumerate(zip(verified, exported_names(verified))):
        old_names = sorted(set(PUBLIC_SYMBOLS) & names)
        missing_names = sorted(set(PUBLIC_SYMBOLS.values()) - names)
        if old_names or missing_names:
            raise RuntimeError(
                f"Export verification failed: old={old_names}, missing={missing_names}"
            )
        text = binary.get_section("__text")
        exports = binary.dyld_exports_trie
        if text is None or exports is None:
            raise RuntimeError(f"Required protected regions are absent from slice {index}")
        metadata.append({
            "slice": index,
            "text_sha256": digest(text.content),
            "export_sha256": digest(exports.content),
            "section_sha256": section_digest(binary),
        })

    metadata_path.write_text(json.dumps({"slices": metadata}, indent=2) + "\n", encoding="utf-8")
    print(
        f"Protected {changed} exports, disabled {len(verified)} constructors, "
        f"and scrubbed {scrubbed} release strings across {len(verified)} Mach-O slices"
    )


if __name__ == "__main__":
    main()
