# GAIA / NEXUS — Multi-Account Drive ↔ Colab Federation

**Release:** 2.1.0  
**Repository:** machackabook/Nexus_Core  
**State:** implementation committed; live Colab execution remains pending  
**Lineage:** Bibliothèque / ADAM registry → CAT-2026-00012 (Gemini notebook lineage)

## Executive result

This release provides a valid Colab entrypoint backed by a reusable Python module. It inventories Drive metadata visible to the active Colab principal, follows configured shared roots (including shared-drive roots where the API permits), inspects every discovered relevant notebook/source candidate by default, computes byte and normalized hashes, identifies exact/normalized duplicates, builds parent/duplicate lineage edges, flags execution-risk patterns without running imported code, writes a chained receipt ledger, and pushes the complete report set—including a receipt-ledger snapshot—to a Drive outbox. Notebook source is secret-redacted before it is included in exported reports; the source-projection hash is calculated from the original unredacted source so identity remains stable without exporting credential values.

## Multi-account model: what is and is not federated

ChatGPT-connected Google OAuth sessions are not exportable into a Colab runtime. The nine Drive identities observed in the earlier connector session are therefore not nine credentials that Colab can silently reuse.

The implemented federation is a shared-resource model:

1. Each source account shares its project/Colab root folder with the one Google identity authenticated in the Colab runtime, or places selected artifacts in the common bridge folder.
2. The active Colab principal scans its own Drive corpus plus files shared with it and any configured shared-drive roots.
3. Colab pulls source bytes into its local workspace, records provenance and hashes, and writes reports/new versions into the bridge outbox.
4. An original is never overwritten by the default push path. In-place replacement is a separate explicit operation that requires an expected current SHA-256 and creates/verifies a backup first.

This is bidirectional file movement, not credential cloning. Files not shared with the active Colab principal cannot be discovered by that runtime.

## Historical anchors recovered in the earlier connected-Drive session

The earlier connector pass reported nine connected Drive identities and a shared Colab Notebooks area. Four identities initially exposed the native shared Colab folder; selected bridge files were then shared to the other identities and the bridge notebook was reported visible to all nine. This is historical connector evidence, not a fresh check in the current session.

Known project candidates from that pass:

- Great Assimilation / Cloud Purge v2.0 — Drive createdTime reported as 2025-07-16.
- The Nexus Generation — Drive createdTime reported as 2025-07-21.
- Quantum coherence record, expansion script, and cron script — metadata reported around 2025-07-22.
- A Gemini Colab backend notebook and a later multi-account bridge notebook.
- An exact notebook titled Phi/Phil Coherence Engine was not located. The quantum_coherence files are a supported related lineage candidate, not proof of the same artifact.

The prior query returned no native Colab notebooks with Drive createdTime between 2025-01-01 and 2025-06-30. This was not a complete historical account export. Drive createdTime is metadata for the current Drive object and does not establish when the underlying source was first authored; copied/imported material can have newer timestamps. The new scan also reports the Jan–Jun 2025 count for all relevant inspected artifacts, a month-by-month timeline, metadata-scan completeness for both user and shared-drive corpora, configured-root access, pagination warnings, and whether an optional inspection cap was reached. The default Colab configuration sets max_inspect_files to null, meaning every discovered candidate is inspected; a per-file download ceiling (default 50 MB) still protects the runtime.

## Runtime discovery scope

The notebook searches:

- all files visible in the active principal's Drive user corpus;
- allDrives where the Drive API permits the query;
- configured folder roots;
- indexed fullText matches for Great Assimilation, Cloud Purge, Phi, Phil, coherence, quantum coherence, Nexus Generation, Gemini, GAIA, ADAM, SYNAPSE, Chimera, sparsebundle, Colab, Macintosh, NEXUS_STAGING, core_functions, assimilated_archives, Aether, Gemini CLI, embeddings, Weaviate, and transfer;
- all native Colab/IPYNB files visible to the principal.

For each candidate it records file ID, name, MIME type, createdTime, modifiedTime, parents, owner aliases (one-way SHA-256 labels, not email addresses), byte size, exact SHA-256, normalized content SHA-256, notebook cell projection, and risk findings. Raw credentials and notebook outputs are not included in the public repository.

## Full-scope and redaction behavior

The default scan inspects all candidates discovered from the active principal's visible user corpus, shared-drive corpus, configured shared roots, and indexed full-text matches. It does not silently stop at the former 1,200-file inspection cap. Set max_inspect_files in the private Colab Secret only when an intentional bounded pass is needed. The report marks a bounded pass with inspection_limit_reached=true.

The default per-file download ceiling is 50,000,000 bytes. Files above that ceiling, unsupported Google-native exports, permission failures, or malformed notebooks are retained in the inventory with an inspection-failure state and warning rather than silently omitted. The report separately records user-corpus and shared-drive metadata completeness, incompleteSearch, pagination-limit warnings, and configured-root access.

Notebook identity hashes are computed from original notebook cell source. Exported cell text is passed through credential-pattern redaction before it is placed in registry.json, inventory.jsonl, execution_review.json, or excerpts. This prevents known API-key/token patterns from being copied into the report. It is not a guarantee that every possible secret format is recognized; treat source archives as private and rotate credentials that were pasted into chats or public files.

## Evidence outputs

The Colab run writes:

- registry.json
- inventory.jsonl
- lineage.json
- duplicates.json
- execution_review.json
- account_summary.json
- receipts.jsonl (local append-only hash chain and uploaded snapshot)

The receipt file is hash chained. Each entry contains sequence, timestamp, event, predecessor digest, data, and its own SHA-256. The uploaded ledger is a point-in-time snapshot made before the Drive API records the upload of that snapshot itself; that final upload receipt remains in the live Colab workspace ledger for the next export. The chain detects modification of recorded receipts; it does not prove Google account ownership or source authorship.

## Safe execution policy

Imported notebooks and shell scripts are downloaded and statically inspected only. No imported code is executed by the discovery pass. The Great Assimilation / Cloud Purge and sparsebundle-related scripts are marked for review when mutation patterns are present.

Default push behavior creates a new file in the bridge outbox. The optional replace_original method is guarded by confirm=True, an expected current content hash, and a verified backup. Its preflight is optimistic rather than an atomic compare-and-swap; concurrent edits can still race. Use the new-version path unless replacement is essential.

## Gemini backend

The Colab notebook reads GEMINI_API_KEY from Colab Secrets and writes a runtime-only, mode-0600 config file for /root/nexus/bin/gemini-backend. The key is never committed, printed, included in a receipt, or uploaded to Drive. The backend uses the X-goog-api-key header and gemini-flash-latest by default.

A key pasted into a chat or public source should be rotated before reuse. Add the replacement only to Colab Secrets under GEMINI_API_KEY.

SSH client contract:

    Host colab
      User root
      ProxyCommand colab ssh --proxy-mode -s colab
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
      RequestTTY no
      RemoteCommand cd /content 2>/dev/null && exec /root/nexus/bin/gemini-backend

## Runtime configuration

Optional Colab Secret: NEXUS_DRIVE_BRIDGE_CONFIG_JSON

Example structure (use actual folder IDs privately in Colab Secrets; do not commit them):

    {
      "bridge_folder_id": "",
      "source_roots": [
        {"label": "drive-account-a", "folder_id": ""},
        {"label": "drive-account-b", "folder_id": ""}
      ]
    }

When this secret is absent, the notebook searches for a folder named NEXUS_MULTIACCOUNT_BRIDGE and the Colab Notebooks root visible to the active principal. Add additional source roots only after those folders have been shared with that principal.

## Verification status

- Notebook JSON structure: independently parsed from the committed GitHub files in this session; both notebooks are nbformat 4 with correctly separated source lines.
- Python module compilation and deterministic unit tests: committed but not executed here. GitHub Actions created failed jobs with no step records or downloadable logs, so no passing CI result is claimed.
- Live Drive enumeration, cross-owner access, Gemini API execution, and SSH proxy execution: not claimed until the notebook is run in an authenticated Colab runtime.
- The earlier nine-identity connector visibility result is retained as historical evidence only.
