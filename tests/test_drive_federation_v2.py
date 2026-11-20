import json
import tempfile
import unittest
from pathlib import Path

from gaia.nexus.drive_federation_v2 import (
    HashChain,
    analyze_source,
    canonical_json_bytes,
    normalize_text,
    notebook_projection,
    redact_secrets,
    sanitized_notebook_projection,
    sha256_bytes,
)

class DriveFederationPureTests(unittest.TestCase):
    def test_sha256_known_vector(self):
        self.assertEqual(
            sha256_bytes(b"abc"),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
        )

    def test_normalize_text(self):
        self.assertEqual(normalize_text("cafe\u0301  \r\nline  \r"), "café\nline")

    def test_canonical_json_is_key_order_independent(self):
        self.assertEqual(
            canonical_json_bytes({"b": 2, "a": 1}),
            canonical_json_bytes({"a": 1, "b": 2}),
        )

    def test_notebook_projection_ignores_outputs_and_execution_count(self):
        a = {
            "cells": [{
                "cell_type": "code",
                "source": ["print(1)\n"],
                "outputs": [{"text": ["one"]}],
                "execution_count": 1,
            }]
        }
        b = {
            "cells": [{
                "cell_type": "code",
                "source": "print(1)\n",
                "outputs": [],
                "execution_count": None,
            }]
        }
        self.assertEqual(notebook_projection(a), notebook_projection(b))

    def test_notebook_projection_redacts_secrets_in_reported_cells(self):
        payload = {
            "cells": [{
                "cell_type": "code",
                "source": [
                    "GEMINI_API_KEY = 'AIza" + ("A" * 35) + "'\\n",
                    "print('safe')\\n",
                ],
            }]
        }
        raw = notebook_projection(payload)
        safe = sanitized_notebook_projection(payload)
        self.assertIn("AIza", raw[0]["source"])
        self.assertNotIn("AIza", safe[0]["source"])
        self.assertIn("[REDACTED_SECRET]", safe[0]["source"])
        self.assertIn("print('safe')", safe[0]["source"])

    def test_destructive_source_is_flagged_not_executed(self):
        result = analyze_source("import shutil\nshutil.rmtree('/tmp/archive')", "purge.py")
        self.assertEqual(result["risk_level"], "HIGH_REVIEW_REQUIRED")
        self.assertFalse(result["automatic_execution"])

    def test_credentials_are_redacted(self):
        source = "GEMINI_API_KEY=AIza" + ("A" * 35)
        self.assertIn("[REDACTED_SECRET]", redact_secrets(source))
        self.assertNotIn("AIza", redact_secrets(source))

    def test_receipt_chain_and_tamper_detection(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "receipts.jsonl"
            chain = HashChain(path)
            chain.append("PULL", file_id="one", sha256="abc")
            chain.append("PUSH", file_id="two", sha256="def")
            self.assertTrue(chain.verify()[0])
            rows = path.read_text(encoding="utf-8").splitlines()
            altered = json.loads(rows[0])
            altered["data"]["sha256"] = "tampered"
            rows[0] = json.dumps(altered)
            path.write_text("\n".join(rows) + "\n", encoding="utf-8")
            self.assertFalse(HashChain(path).verify()[0])

if __name__ == "__main__":
    unittest.main()
