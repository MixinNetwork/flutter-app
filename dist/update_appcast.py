#!/usr/bin/env python3
"""Write appcast.xml for the desktop app updater and sign every package.

Each package gets one <item>. The macOS DMG has a Sparkle EdDSA signature over
the whole file. The other packages have a signature over this text, so a valid
package of an older release cannot be listed as a newer one:

    mixin-desktop-update\\n<tag>\\n<file name>\\n<sha256 hex>

The script verifies every signature with the public key that the app ships
before it writes the file. Needs OpenSSL 3 (LibreSSL has no Ed25519).

Usage:
  update_appcast.py --tag v6.3.7 --build 602 --key key.pem \\
      --public-key dist/update_ed25519.pub --url-prefix <download url prefix> \\
      --out appcast.xml <package>=<file> ...
"""

import argparse
import base64
import hashlib
import os
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
MIXIN_NS = "https://mixin.one/xml-namespaces/desktop-update"

# package id -> sparkle:os
PACKAGES = {
    "dmg": "macos",
    "inno-x64": "windows",
    "appimage-x64": "linux",
    "appimage-arm64": "linux",
    "deb-x64": "linux",
    "deb-arm64": "linux",
    "tar-x64": "linux",
    "tar-arm64": "linux",
}

# DER prefix of an Ed25519 SubjectPublicKeyInfo; the raw 32-byte key follows.
ED25519_SPKI_PREFIX = bytes.fromhex("302a300506032b6570032100")


def sha256_file(path):
    digest = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def signed_text(tag, name, sha256):
    return f"mixin-desktop-update\n{tag}\n{name}\n{sha256}".encode()


def openssl(openssl_bin, *args):
    subprocess.run([openssl_bin, *args], check=True, capture_output=True)


def sign(openssl_bin, key, data_path):
    with tempfile.TemporaryDirectory() as tmp:
        sig_path = os.path.join(tmp, "sig")
        # -rawin needs -in <file>: it cannot size stdin.
        openssl(openssl_bin, "pkeyutl", "-sign", "-rawin", "-inkey", key,
                "-in", data_path, "-out", sig_path)
        with open(sig_path, "rb") as f:
            return base64.b64encode(f.read()).decode()


def verify(openssl_bin, public_key_der, data_path, signature):
    with tempfile.TemporaryDirectory() as tmp:
        pub_path = os.path.join(tmp, "pub.der")
        sig_path = os.path.join(tmp, "sig")
        with open(pub_path, "wb") as f:
            f.write(public_key_der)
        with open(sig_path, "wb") as f:
            f.write(base64.b64decode(signature))
        result = subprocess.run(
            [openssl_bin, "pkeyutl", "-verify", "-rawin", "-pubin",
             "-keyform", "DER", "-inkey", pub_path, "-in", data_path,
             "-sigfile", sig_path],
            capture_output=True)
        return result.returncode == 0


def read_public_key(path):
    with open(path) as f:
        raw = base64.b64decode(f.read().strip())
    if len(raw) != 32:
        sys.exit(f"{path}: expected a base64 raw 32-byte Ed25519 key")
    return ED25519_SPKI_PREFIX + raw


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True)
    parser.add_argument("--build", required=True,
                        help="build number, compared with CFBundleVersion")
    parser.add_argument("--key", required=True, help="Ed25519 private key PEM")
    parser.add_argument("--public-key", required=True,
                        help="base64 raw public key that the app ships")
    parser.add_argument("--url-prefix", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--openssl", default="openssl")
    parser.add_argument("packages", nargs="+", metavar="PACKAGE=FILE")
    args = parser.parse_args()

    public_key = read_public_key(args.public_key)
    version = args.tag.removeprefix("v")

    ET.register_namespace("sparkle", SPARKLE_NS)
    ET.register_namespace("mixin", MIXIN_NS)
    rss = ET.Element("rss", {"version": "2.0"})
    channel = ET.SubElement(rss, "channel")
    ET.SubElement(channel, "title").text = "Mixin Messenger"

    with tempfile.TemporaryDirectory() as tmp:
        for spec in args.packages:
            package, _, path = spec.partition("=")
            if package not in PACKAGES or not path:
                sys.exit(f"unknown package or missing file: {spec}")
            name = os.path.basename(path)
            sha256 = sha256_file(path)

            enclosure = {
                "url": f"{args.url_prefix.rstrip('/')}/{name}",
                "length": str(os.path.getsize(path)),
                "type": "application/octet-stream",
                f"{{{SPARKLE_NS}}}os": PACKAGES[package],
                f"{{{MIXIN_NS}}}package": package,
                f"{{{MIXIN_NS}}}sha256": sha256,
            }
            if package == "dmg":
                signature = sign(args.openssl, args.key, path)
                signed_path = path
                enclosure[f"{{{SPARKLE_NS}}}edSignature"] = signature
            else:
                signed_path = os.path.join(tmp, name + ".txt")
                with open(signed_path, "wb") as f:
                    f.write(signed_text(args.tag, name, sha256))
                signature = sign(args.openssl, args.key, signed_path)
                enclosure[f"{{{MIXIN_NS}}}signature"] = signature

            if not verify(args.openssl, public_key, signed_path, signature):
                sys.exit(f"{name}: signature does not match the public key "
                         f"in {args.public_key}; is the signing key right?")

            item = ET.SubElement(channel, "item")
            ET.SubElement(item, "title").text = version
            ET.SubElement(item, f"{{{SPARKLE_NS}}}version").text = args.build
            ET.SubElement(item, f"{{{SPARKLE_NS}}}shortVersionString").text = \
                version
            ET.SubElement(item, "enclosure", enclosure)

    ET.indent(rss)
    ET.ElementTree(rss).write(args.out, encoding="utf-8",
                              xml_declaration=True)


if __name__ == "__main__":
    main()
