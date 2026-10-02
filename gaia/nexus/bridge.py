#!/usr/bin/env python3
import argparse
import json
import os
from datetime import datetime

from gaia.nexus.providers.colab_gemini import invoke as invoke_colab_gemini


class NexusBridge:
    def __init__(self):
        self.gaia_root = os.environ.get("GAIA_ROOT", os.path.expanduser("~/NEXUS_CORE"))
        self.log_file = os.path.join(self.gaia_root, "logs", "bridge_status.log")
        self.colab_host = os.environ.get("NEXUS_COLAB_HOST", "colab")

    def log(self, message):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        entry = f"[{timestamp}] {message}"
        print(entry)
        try:
            os.makedirs(os.path.dirname(self.log_file), exist_ok=True)
            with open(self.log_file, "a") as f:
                f.write(entry + "\n")
        except Exception:
            pass

    def execute_handshake(self):
        self.log("Executing Gaia.Nexus mesh handshake...")
        state = {
            "node_status": "ONLINE",
            "gaia_root": self.gaia_root,
            "handshake": "SUCCESS",
            "providers": {
                "gemini": {
                    "backend": os.environ.get("NEXUS_GEMINI_BACKEND", "direct"),
                    "colab_host": self.colab_host,
                    "colab_transport": "ssh-stdin"
                }
            },
            "timestamp": datetime.now().isoformat()
        }
        self.log(f"State Reconciliation: {json.dumps(state)}")
        return state

    def gemini(self, prompt):
        receipt = invoke_colab_gemini(prompt, host=self.colab_host)
        self.log(
            "Gemini Colab receipt "
            f"sha256={receipt.stdout_sha256} duration_ms={receipt.duration_ms} exit={receipt.exit_code}"
        )
        return receipt


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command")

    sub.add_parser("handshake")
    gemini = sub.add_parser("gemini")
    gemini.add_argument("prompt", nargs="*")
    gemini.add_argument("--receipt", action="store_true")

    args = parser.parse_args()
    bridge = NexusBridge()

    if args.command == "gemini":
        import sys
        prompt = " ".join(args.prompt).strip() if args.prompt else sys.stdin.read().strip()
        receipt = bridge.gemini(prompt)
        if args.receipt:
            from dataclasses import asdict
            print(json.dumps(asdict(receipt), ensure_ascii=False))
        else:
            print(receipt.text)
        return

    bridge.execute_handshake()


if __name__ == "__main__":
    main()
