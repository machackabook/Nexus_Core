#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json, os, subprocess, sys, time
from dataclasses import asdict, dataclass
from typing import Any

@dataclass
class BackendReceipt:
    provider: str
    transport: str
    host: str
    model: str
    started_at_unix_ms: int
    duration_ms: int
    exit_code: int
    stdout_sha256: str
    text: str
    raw: Any

def _extract_text(payload: Any) -> str:
    try:
        return "".join(str(p.get("text", "")) for p in payload["candidates"][0]["content"]["parts"] if isinstance(p, dict))
    except (KeyError, IndexError, TypeError):
        return ""

def invoke(prompt: str, *, host: str | None = None, timeout: int = 180) -> BackendReceipt:
    host = host or os.environ.get("NEXUS_COLAB_HOST", "colab")
    ssh_bin = os.environ.get("NEXUS_SSH_BIN", "ssh")
    model = os.environ.get("GEMINI_MODEL", "gemini-flash-latest")
    started = int(time.time() * 1000)
    t0 = time.perf_counter()
    proc = subprocess.run([ssh_bin, host], input=prompt, text=True, capture_output=True, timeout=timeout, check=False)
    duration = int((time.perf_counter() - t0) * 1000)
    stdout = proc.stdout or ""
    digest = hashlib.sha256(stdout.encode("utf-8")).hexdigest()
    if proc.returncode != 0:
        raise RuntimeError(f"Colab backend failed exit={proc.returncode}: {(proc.stderr or '').strip()}")
    try:
        raw = json.loads(stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError("Colab backend returned non-JSON output") from exc
    return BackendReceipt(
        provider="gemini", transport="colab-ssh", host=host, model=model,
        started_at_unix_ms=started, duration_ms=duration, exit_code=proc.returncode,
        stdout_sha256=digest, text=_extract_text(raw), raw=raw
    )

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("prompt", nargs="*")
    parser.add_argument("--host", default=None)
    parser.add_argument("--timeout", type=int, default=180)
    parser.add_argument("--raw", action="store_true")
    parser.add_argument("--receipt", action="store_true")
    args = parser.parse_args()
    prompt = " ".join(args.prompt).strip() if args.prompt else sys.stdin.read().strip()
    if not prompt:
        print("empty prompt", file=sys.stderr)
        return 64
    receipt = invoke(prompt, host=args.host, timeout=args.timeout)
    if args.receipt:
        print(json.dumps(asdict(receipt), ensure_ascii=False))
    elif args.raw:
        print(json.dumps(receipt.raw, ensure_ascii=False))
    else:
        print(receipt.text)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
