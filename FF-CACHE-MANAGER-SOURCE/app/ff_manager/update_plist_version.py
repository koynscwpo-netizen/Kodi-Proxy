import plistlib
import sys
from pathlib import Path


def main():
    if len(sys.argv) != 4:
        raise SystemExit("usage: update_plist_version.py INFO_PLIST VERSION BUILD")

    path = Path(sys.argv[1])
    with path.open("rb") as handle:
        info = plistlib.load(handle)
    info["CFBundleShortVersionString"] = sys.argv[2]
    info["CFBundleVersion"] = sys.argv[3]
    with path.open("wb") as handle:
        plistlib.dump(info, handle, fmt=plistlib.FMT_XML, sort_keys=False)

    data = path.read_bytes()
    if not data.startswith(b'<?xml version="1.0" encoding="UTF-8"?>\n'):
        raise RuntimeError("Info.plist has a non-standard XML prefix")
    if data.startswith(b"\xef\xbb\xbf") or b"PropertyList-1.0.dtd\"[]>" in data:
        raise RuntimeError("Info.plist contains a BOM or malformed DOCTYPE")


if __name__ == "__main__":
    main()
