#!/usr/bin/env python3
"""Tests for update_appcast.py. Run: python3 dist/test_update_appcast.py"""

import base64
import os
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import update_appcast as appcast  # noqa: E402

OPENSSL = os.environ.get("OPENSSL", "openssl")
SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                      "update_appcast.py")
S = "{%s}" % appcast.SPARKLE_NS
M = "{%s}" % appcast.MIXIN_NS


def make_key(directory, name):
    key = os.path.join(directory, name + ".pem")
    subprocess.run([OPENSSL, "genpkey", "-algorithm", "ed25519", "-out", key],
                   check=True, capture_output=True)
    der = subprocess.run([OPENSSL, "pkey", "-in", key, "-pubout",
                          "-outform", "DER"],
                         check=True, capture_output=True).stdout
    pub = os.path.join(directory, name + ".pub")
    with open(pub, "w") as f:
        f.write(base64.b64encode(der[len(appcast.ED25519_SPKI_PREFIX):])
                .decode())
    return key, pub


class UpdateAppcastTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = self.tmp.name
        self.key, self.pub = make_key(self.dir, "key")
        self.files = {}
        for package, name in [("dmg", "mixin-6.3.7.dmg"),
                              ("inno-x64",
                               "mixin_desktop_windows_setup_amd64.exe"),
                              ("appimage-arm64",
                               "mixin_desktop_linux_arm64.AppImage")]:
            path = os.path.join(self.dir, name)
            with open(path, "wb") as f:
                f.write(os.urandom(4096))
            self.files[package] = path
        self.out = os.path.join(self.dir, "appcast.xml")

    def tearDown(self):
        self.tmp.cleanup()

    def run_script(self, pub):
        return subprocess.run(
            [sys.executable, SCRIPT, "--tag", "v6.3.7", "--build", "602",
             "--key", self.key, "--public-key", pub,
             "--url-prefix", "https://example.com/v6.3.7/",
             "--out", self.out, "--openssl", OPENSSL,
             *[f"{p}={f}" for p, f in self.files.items()]],
            capture_output=True, text=True)

    def verify(self, data, signature):
        path = os.path.join(self.dir, "data")
        with open(path, "wb") as f:
            f.write(data)
        return appcast.verify(OPENSSL, appcast.read_public_key(self.pub),
                              path, signature)

    def test_items_and_signatures(self):
        result = self.run_script(self.pub)
        self.assertEqual(result.returncode, 0, result.stderr)
        items = ET.parse(self.out).getroot().findall("channel/item")
        self.assertEqual(len(items), 3)

        for item in items:
            self.assertEqual(item.find(S + "version").text, "602")
            self.assertEqual(item.find(S + "shortVersionString").text, "6.3.7")
            enclosure = item.find("enclosure")
            package = enclosure.get(M + "package")
            path = self.files[package]
            name = os.path.basename(path)
            with open(path, "rb") as f:
                content = f.read()

            self.assertEqual(enclosure.get("url"),
                             "https://example.com/v6.3.7/" + name)
            self.assertEqual(enclosure.get("length"), str(len(content)))
            self.assertEqual(enclosure.get(S + "os"),
                             appcast.PACKAGES[package])
            sha256 = appcast.sha256_file(path)
            self.assertEqual(enclosure.get(M + "sha256"), sha256)

            if package == "dmg":
                signature = enclosure.get(S + "edSignature")
                self.assertIsNone(enclosure.get(M + "signature"))
                self.assertTrue(self.verify(content, signature))
                self.assertFalse(self.verify(content + b"x", signature))
            else:
                signature = enclosure.get(M + "signature")
                self.assertIsNone(enclosure.get(S + "edSignature"))
                self.assertEqual(enclosure.get(M + "tag"), "v6.3.7")
                signed = ("v6.3.7", "602", package, name, sha256)
                self.assertTrue(self.verify(appcast.signed_text(*signed),
                                            signature))
                # Any other tag, build, package, file name or file must not
                # match.
                for i, value in enumerate(["v6.3.6", "9999", "deb-x64",
                                           "other", "0" * 64]):
                    changed = list(signed)
                    changed[i] = value
                    self.assertFalse(self.verify(
                        appcast.signed_text(*changed), signature))

    def test_rejects_key_that_does_not_match_app_key(self):
        _, other_pub = make_key(self.dir, "other")
        result = self.run_script(other_pub)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("does not match the public key", result.stderr)
        self.assertFalse(os.path.exists(self.out))


if __name__ == "__main__":
    unittest.main()
