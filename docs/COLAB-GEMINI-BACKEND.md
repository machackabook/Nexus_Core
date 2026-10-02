# Colab Gemini Backend — GAIA/NEXUS Provider Contract

Transport: local process → SSH host `colab` → Colab `gemini-backend` → Gemini REST API.

The API credential stays on the Colab backend side. Do not commit it to repositories,
browser code, HTML artifacts, notebooks, receipts, or logs.

## SSH contract

```sshconfig
Host colab
  User root
  ProxyCommand colab ssh --proxy-mode -s colab
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  RequestTTY no
  RemoteCommand cd /content 2>/dev/null && exec bash -lc '/root/nexus/bin/gemini-backend'
```

## Canonical command

```bash
bin/nexus-gemini-colab 'hello from GAIA'
bin/nexus-gemini-colab --receipt 'return a one-line health response'
```

Client environment:
- `NEXUS_COLAB_HOST` defaults to `colab`
- `NEXUS_SSH_BIN` defaults to `ssh`
- `GEMINI_MODEL` defaults to `gemini-flash-latest`

Colab backend:
- `GEMINI_API_KEY` is supplied through the Colab secret/environment boundary.
- `GEMINI_MODEL` may override the model.

The receipt includes provider, transport, host, model, timing, exit code, SHA-256 of
the raw backend response, extracted text, and raw JSON. A successful call is execution
evidence only; canonical promotion still requires the normal ADAM verification and ledger gates.
