#!/usr/bin/env python3
from __future__ import annotations

import json
import os
from dataclasses import asdict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from gaia.nexus.providers.colab_gemini import invoke as invoke_colab_gemini

BIND = os.environ.get("NEXUS_AI_GATEWAY_BIND", "127.0.0.1")
PORT = int(os.environ.get("NEXUS_AI_GATEWAY_PORT", "8765"))


class Handler(BaseHTTPRequestHandler):
    server_version = "NexusAIGateway/1.0"

    def _json(self, status: int, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/health":
            self._json(200, {
                "status": "ready",
                "provider": "gemini",
                "backend": "colab-ssh",
                "ssh_host": os.environ.get("NEXUS_COLAB_HOST", "colab"),
            })
            return
        self._json(404, {"error": "not_found"})

    def do_POST(self):
        if self.path not in ("/v1/gemini/generate", "/api/gemini"):
            self._json(404, {"error": "not_found"})
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length <= 0 or length > 2_000_000:
                self._json(413, {"error": "invalid_payload_size"})
                return
            data = json.loads(self.rfile.read(length))
            prompt = str(data.get("prompt", "")).strip()
            if not prompt:
                self._json(400, {"error": "prompt_required"})
                return

            receipt = invoke_colab_gemini(
                prompt,
                host=os.environ.get("NEXUS_COLAB_HOST", "colab"),
                timeout=int(os.environ.get("NEXUS_COLAB_TIMEOUT", "180")),
            )
            self._json(200, {
                "text": receipt.text,
                "provider": receipt.provider,
                "transport": receipt.transport,
                "model": receipt.model,
                "duration_ms": receipt.duration_ms,
                "exit_code": receipt.exit_code,
                "stdout_sha256": receipt.stdout_sha256,
                "raw": receipt.raw if data.get("include_raw") else None,
            })
        except json.JSONDecodeError:
            self._json(400, {"error": "invalid_json"})
        except Exception as exc:
            self._json(502, {"error": "backend_failure", "detail": str(exc)})

    def log_message(self, fmt, *args):
        print("[NEXUS-AI-GATEWAY] " + (fmt % args))


def main():
    server = ThreadingHTTPServer((BIND, PORT), Handler)
    print(f"[NEXUS-AI-GATEWAY] listening on http://{BIND}:{PORT}")
    print("[NEXUS-AI-GATEWAY] POST /v1/gemini/generate")
    server.serve_forever()


if __name__ == "__main__":
    main()
