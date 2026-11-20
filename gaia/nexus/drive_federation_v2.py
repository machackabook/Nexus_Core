from __future__ import annotations

import csv
import hashlib
import io
import json
import re
import time
import unicodedata
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable

SCHEMA_VERSION = "2.0.0"
DEFAULT_TERMS = (
    "great assimilation", "cloud purge", "phi", "phil", "coherence",
    "quantum coherence", "nexus generation", "gemini", "gaia", "adam",
    "synapse", "chimera", "sparsebundle", "colab", "macintosh",
    "nexus staging", "core functions", "assimilated archives", "aether",
    "geminicli", "embeddings", "weaviate", "transfer",
)
NOTEBOOK_MIMES = {
    "application/vnd.google.colaboratory",
    "application/x-ipynb+json",
}
TEXT_SUFFIXES = {
    ".ipynb", ".py", ".sh", ".json", ".md", ".txt", ".html", ".htm",
    ".yaml", ".yml", ".toml", ".js", ".ts", ".tsx", ".jsx", ".css",
}
GOOGLE_EXPORTS = {
    "application/vnd.google-apps.document": "text/plain",
    "application/vnd.google-apps.spreadsheet": "text/csv",
}
SECRET_PATTERNS = (
    re.compile(r"AIza[0-9A-Za-z_-]{30,}"),
    re.compile(r"AQ\.[0-9A-Za-z_-]{20,}"),
    re.compile(r"(?i)(api[_-]?key\s*[:=]\s*)['\"]?[^'\"\s,}]+"),
    re.compile(r"(?i)(bearer\s+)[A-Za-z0-9._~-]{16,}"),
    re.compile(r"(?i)(access_token\s*[:=]\s*)['\"]?[^'\"\s,}]+"),
)
RISK_PATTERNS = {
    "DESTRUCTIVE_STORAGE": (
        r"\bshutil\.rmtree\s*\(", r"\bos\.remove\s*\(",
        r"\.unlink\s*\(", r"\brm\s+-rf\b", r"\bmkfs(?:\.\w+)?\b",
        r"\bdiskutil\s+(?:erase|partition)\b", r"\bformat\s+[a-z]:",
    ),
    "BULK_DELETE_OR_PURGE": (
        r"\bfiles\(\)\.delete\s*\(", r"\bdrive\.files\(\)\.delete\s*\(",
        r"\bgsutil\s+rm\b", r"\bgcloud\s+storage\s+rm\b",
    ),
    "CREDENTIAL_HANDLING": (
        r"\bGEMINI_API_KEY\b", r"\buserdata\.get\s*\(",
        r"\bapi[_-]?key\b", r"\boauth\b", r"\bcredentials\b",
    ),
    "NETWORK_ACCESS": (
        r"\brequests\.", r"\burllib\.", r"\bfetch\s*\(",
        r"\bgoogleapiclient\b", r"\bhttpx\.",
    ),
    "RUNTIME_MUTATION": (
        r"\bsubprocess\.", r"\bos\.system\s*\(", r"\bpip\s+install\b",
        r"\bapt-get\b", r"\bchmod\b",
    ),
}

def canonical_json_bytes(value: Any) -> bytes:
    return json.dumps(
        value, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")

def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def normalize_text(value: str) -> str:
    value = unicodedata.normalize("NFC", value.replace("\r\n", "\n").replace("\r", "\n"))
    return "\n".join(line.rstrip() for line in value.split("\n")).strip()

def redact_secrets(value: str) -> str:
    result = value
    for pattern in SECRET_PATTERNS:
        result = pattern.sub("[REDACTED_SECRET]", result)
    return result

def notebook_projection(payload: dict[str, Any]) -> list[dict[str, str]]:
    projection = []
    for cell in payload.get("cells", []):
        source = cell.get("source", "")
        if isinstance(source, list):
            source = "".join(source)
        projection.append({
            "cell_type": str(cell.get("cell_type", "unknown")),
            "source": normalize_text(str(source)),
        })
    return projection


def sanitized_notebook_projection(payload: dict[str, Any]) -> list[dict[str, str]]:
    """Return report-safe cell source while leaving byte/source hashes unchanged."""
    return [
        {"cell_type": cell["cell_type"], "source": redact_secrets(cell["source"])}
        for cell in notebook_projection(payload)
    ]

def analyze_source(source: str, name: str = "") -> dict[str, Any]:
    text = (name + "\n" + source).lower()
    matches: dict[str, list[str]] = {}
    for category, patterns in RISK_PATTERNS.items():
        found = [pattern for pattern in patterns if re.search(pattern, text, re.I)]
        if found:
            matches[category] = found
    destructive = "DESTRUCTIVE_STORAGE" in matches or "BULK_DELETE_OR_PURGE" in matches
    if destructive:
        level = "HIGH_REVIEW_REQUIRED"
    elif matches:
        level = "REVIEW_REQUIRED"
    else:
        level = "NO_KNOWN_MUTATION_PATTERN"
    return {
        "risk_level": level,
        "categories": sorted(matches),
        "matched_patterns": matches,
        "automatic_execution": False,
    }

class HashChain:
    def __init__(self, path: str | Path):
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.touch(exist_ok=True)

    def append(self, event: str, **data: Any) -> dict[str, Any]:
        previous = "0" * 64
        if self.path.stat().st_size:
            rows = self.path.read_text(encoding="utf-8").splitlines()
            if rows:
                previous = json.loads(rows[-1])["receipt_sha256"]
        with self.path.open("r", encoding="utf-8") as handle:
            sequence = sum(1 for _ in handle)
        body = {
            "schema": "nexus.receipt.v1",
            "sequence": sequence,
            "timestamp_unix_ms": int(time.time() * 1000),
            "event": event,
            "previous_receipt_sha256": previous,
            "data": data,
        }
        digest = sha256_bytes(canonical_json_bytes(body))
        row = {**body, "receipt_sha256": digest}
        with self.path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")
        return row

    def verify(self) -> tuple[bool, list[str]]:
        errors: list[str] = []
        previous = "0" * 64
        expected_sequence = 0
        for line_number, line in enumerate(self.path.read_text(encoding="utf-8").splitlines(), 1):
            try:
                row = json.loads(line)
                digest = row.pop("receipt_sha256")
                if row.get("sequence") != expected_sequence:
                    errors.append(f"line {line_number}: sequence mismatch")
                if row.get("previous_receipt_sha256") != previous:
                    errors.append(f"line {line_number}: predecessor mismatch")
                actual = sha256_bytes(canonical_json_bytes(row))
                if actual != digest:
                    errors.append(f"line {line_number}: digest mismatch")
                previous = digest
                expected_sequence += 1
            except Exception as exc:
                errors.append(f"line {line_number}: invalid receipt ({type(exc).__name__})")
        return not errors, errors

class DriveFederation:
    FIELDS = (
        "nextPageToken,incompleteSearch,files("
        "id,name,mimeType,createdTime,modifiedTime,owners(emailAddress),"
        "parents,shared,webViewLink,md5Checksum,size,"
        "capabilities(canEdit,canDownload),driveId,shortcutDetails(targetId,targetMimeType))"
    )
    FILE_FIELDS = (
        "id,name,mimeType,createdTime,modifiedTime,owners(emailAddress),"
        "parents,shared,webViewLink,md5Checksum,size,"
        "capabilities(canEdit,canDownload),driveId,shortcutDetails(targetId,targetMimeType)"
    )

    def __init__(self, service: Any, workspace: str | Path, max_download_bytes: int = 50_000_000):
        self.service = service
        self.workspace = Path(workspace)
        self.workspace.mkdir(parents=True, exist_ok=True)
        self.max_download_bytes = max_download_bytes
        self.receipts = HashChain(self.workspace / "receipts.jsonl")
        self.warnings: list[str] = []
        self.corpus_status: dict[str, str] = {}
        self.incomplete_search: dict[str, bool] = {}

    def _list_query(self, query: str, corpora: str = "user", page_limit: int = 1000) -> list[dict[str, Any]]:
        found: list[dict[str, Any]] = []
        token = None
        pages = 0
        while pages < page_limit:
            request = self.service.files().list(
                q=query,
                corpora=corpora,
                pageSize=1000,
                pageToken=token,
                orderBy="createdTime",
                fields=self.FIELDS,
                includeItemsFromAllDrives=True,
                supportsAllDrives=True,
            )
            response = request.execute()
            if response.get("incompleteSearch"):
                self.incomplete_search[corpora] = True
            found.extend(response.get("files", []))
            token = response.get("nextPageToken")
            pages += 1
            if not token:
                break
        if token:
            self.incomplete_search[corpora] = True
            self.warnings.append(f"pagination limit reached for corpora={corpora}")
        return found

    def list_all_files(self) -> list[dict[str, Any]]:
        unique: dict[str, dict[str, Any]] = {}
        for corpora in ("user", "allDrives"):
            try:
                for item in self._list_query("trashed = false", corpora=corpora):
                    unique[item["id"]] = item
                self.corpus_status[corpora] = "AVAILABLE"
            except Exception as exc:
                self.corpus_status[corpora] = "UNAVAILABLE"
                self.warnings.append(f"corpora={corpora}: {type(exc).__name__}: {str(exc)[:180]}")
        return list(unique.values())

    def list_children(self, folder_id: str) -> list[dict[str, Any]]:
        query = f"'{folder_id}' in parents and trashed = false"
        try:
            return self._list_query(query, corpora="allDrives")
        except Exception as all_drives_error:
            try:
                self.warnings.append(
                    f"folder listing fell back to user corpus for {folder_id}: "
                    f"{type(all_drives_error).__name__}"
                )
                return self._list_query(query, corpora="user")
            except Exception:
                raise

    def walk_folder(self, folder_id: str, label: str, max_depth: int = 8) -> tuple[list[dict[str, Any]], dict[str, str]]:
        collected: dict[str, dict[str, Any]] = {}
        labels: dict[str, str] = {}
        visited: set[str] = set()

        def visit(current_id: str, depth: int) -> None:
            if current_id in visited or depth > max_depth:
                return
            visited.add(current_id)
            for item in self.list_children(current_id):
                collected[item["id"]] = item
                labels[item["id"]] = label
                if item.get("mimeType") == "application/vnd.google-apps.folder":
                    visit(item["id"], depth + 1)

        visit(folder_id, 0)
        return list(collected.values()), labels

    def get_metadata(self, file_id: str) -> dict[str, Any]:
        return self.service.files().get(
            fileId=file_id,
            fields=self.FILE_FIELDS,
            supportsAllDrives=True,
        ).execute()

    def download_bytes(self, meta: dict[str, Any]) -> tuple[bytes, str]:
        from googleapiclient.http import MediaIoBaseDownload

        file_id = meta["id"]
        mime = meta.get("mimeType", "")
        if mime in GOOGLE_EXPORTS:
            request = self.service.files().export_media(fileId=file_id, mimeType=GOOGLE_EXPORTS[mime])
            content_type = GOOGLE_EXPORTS[mime]
        elif mime == "application/vnd.google-apps.presentation":
            request = self.service.files().export_media(fileId=file_id, mimeType="application/pdf")
            content_type = "application/pdf"
        elif mime.startswith("application/vnd.google-apps."):
            raise ValueError(f"unsupported Google-native export: {mime}")
        else:
            request = self.service.files().get_media(fileId=file_id, supportsAllDrives=True)
            content_type = mime or "application/octet-stream"

        buffer = io.BytesIO()
        downloader = MediaIoBaseDownload(buffer, request, chunksize=1024 * 1024)
        done = False
        while not done:
            _, done = downloader.next_chunk()
            if buffer.tell() > self.max_download_bytes:
                raise ValueError("download exceeds configured size limit")
        return buffer.getvalue(), content_type

    def pull_file(self, file_id: str, filename: str | None = None) -> tuple[Path, str]:
        meta = self.get_metadata(file_id)
        data, _ = self.download_bytes(meta)
        safe_name = Path(filename or meta.get("name") or file_id).name
        target = self.workspace / "downloads" / f"{file_id}_{safe_name}"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        digest = sha256_bytes(data)
        self.receipts.append(
            "PULL",
            file_id=file_id,
            name=safe_name,
            byte_size=len(data),
            content_sha256=digest,
        )
        return target, digest

    def inspect_file(self, meta: dict[str, Any], source_label: str | None = None) -> dict[str, Any]:
        record: dict[str, Any] = {
            "file_id": meta.get("id"),
            "name": meta.get("name"),
            "mime_type": meta.get("mimeType"),
            "created_time": meta.get("createdTime"),
            "modified_time": meta.get("modifiedTime"),
            "size": int(meta["size"]) if str(meta.get("size", "")).isdigit() else None,
            "md5_checksum": meta.get("md5Checksum"),
            "parents": meta.get("parents", []),
            "shared": bool(meta.get("shared", False)),
            "can_edit": meta.get("capabilities", {}).get("canEdit"),
            "owner_aliases": [],
            "source_root_label": source_label,
            "content_state": "NOT_INSPECTED",
        }
        for owner in meta.get("owners", []):
            email = str(owner.get("emailAddress", "")).strip().lower()
            if email:
                record["owner_aliases"].append(sha256_bytes(email.encode("utf-8"))[:12])
        try:
            data, content_type = self.download_bytes(meta)
            record["byte_size"] = len(data)
            record["content_sha256"] = sha256_bytes(data)
            record["content_type"] = content_type
            text = ""
            if meta.get("mimeType") in NOTEBOOK_MIMES or str(meta.get("name", "")).lower().endswith(".ipynb"):
                payload = json.loads(data.decode("utf-8-sig"))
                raw_projection = notebook_projection(payload)
                projection = [
                    {"cell_type": cell["cell_type"], "source": redact_secrets(cell["source"])}
                    for cell in raw_projection
                ]
                text = "\n".join(cell["source"] for cell in projection)
                record["notebook"] = {
                    "nbformat": payload.get("nbformat"),
                    "nbformat_minor": payload.get("nbformat_minor"),
                    "cell_count": len(projection),
                    "code_cell_count": sum(1 for cell in projection if cell["cell_type"] == "code"),
                    "source_projection_sha256": sha256_bytes(canonical_json_bytes(raw_projection)),
                    "secret_redaction_applied": any(
                        safe["source"] != raw["source"]
                        for safe, raw in zip(projection, raw_projection)
                    ),
                    "cells": projection,
                }
                record["normalized_sha256"] = record["notebook"]["source_projection_sha256"]
                record["content_state"] = "NOTEBOOK_PARSED"
            elif content_type.startswith("text/") or content_type in ("application/json", "application/x-ipynb+json"):
                text = data.decode("utf-8-sig", errors="replace")
                record["normalized_sha256"] = sha256_bytes(normalize_text(text).encode("utf-8"))
                record["content_state"] = "TEXT_DECODED"
            else:
                record["content_state"] = "BINARY_HASHED"
            if text:
                safe = redact_secrets(text)
                record["matched_terms"] = [
                    term for term in DEFAULT_TERMS if term in (str(meta.get("name", "")) + "\n" + safe).lower()
                ]
                record["execution_review"] = analyze_source(safe, str(meta.get("name", "")))
                record["content_excerpt"] = safe[:500]
        except Exception as exc:
            record["content_state"] = "INSPECTION_FAILED"
            record["inspection_error"] = f"{type(exc).__name__}: {str(exc)[:220]}"
        return record

    def discover(
        self,
        terms: Iterable[str] = DEFAULT_TERMS,
        root_ids: Iterable[dict[str, str] | str] = (),
        max_inspect_files: int | None = None,
    ) -> dict[str, Any]:
        terms = tuple(terms)
        metadata = {item["id"]: item for item in self.list_all_files()}
        matched: dict[str, set[str]] = defaultdict(set)

        for term in terms:
            safe_term = term.replace("'", "\\'")
            try:
                for item in self._list_query(
                    f"fullText contains '{safe_term}' and trashed = false",
                    corpora="user",
                    page_limit=10,
                ):
                    metadata[item["id"]] = item
                    matched[item["id"]].add(term)
            except Exception as exc:
                self.warnings.append(f"fullText query {term!r}: {type(exc).__name__}")

        root_labels: dict[str, str] = {}
        root_records = []
        for root in root_ids:
            if isinstance(root, dict):
                folder_id = str(root.get("folder_id", "")).strip()
                label = str(root.get("label", "shared-root")).strip()
            else:
                folder_id, label = str(root).strip(), "configured-root"
            if not folder_id:
                continue
            try:
                descendants, labels = self.walk_folder(folder_id, label)
                for item in descendants:
                    metadata[item["id"]] = item
                root_labels.update(labels)
                root_records.append({"folder_id": folder_id, "label": label, "accessible": True, "descendant_count": len(descendants)})
            except Exception as exc:
                root_records.append({"folder_id": folder_id, "label": label, "accessible": False, "error": f"{type(exc).__name__}: {str(exc)[:180]}"})

        candidates = []
        for item in metadata.values():
            name = str(item.get("name", ""))
            lower = name.lower()
            mime = str(item.get("mimeType", ""))
            is_notebook = mime in NOTEBOOK_MIMES or lower.endswith(".ipynb")
            is_project_named = any(term in lower for term in terms)
            is_text_source = Path(lower).suffix in TEXT_SUFFIXES
            if is_notebook or is_project_named or (is_text_source and item["id"] in matched):
                candidates.append(item)

        candidates.sort(key=lambda x: (x.get("createdTime", ""), x.get("name", "").lower()))
        inspection_candidates = (
            candidates if max_inspect_files is None else candidates[:max_inspect_files]
        )
        inspected = [
            self.inspect_file(item, root_labels.get(item["id"]))
            for item in inspection_candidates
        ]
        for row in inspected:
            row["query_matched_terms"] = sorted(matched.get(row["file_id"], set()))
            if not row.get("matched_terms"):
                row["matched_terms"] = row["query_matched_terms"]

        exact_groups: dict[str, list[str]] = defaultdict(list)
        normalized_groups: dict[str, list[str]] = defaultdict(list)
        owners: dict[str, int] = defaultdict(int)
        parent_edges = []
        for row in inspected:
            if row.get("content_sha256"):
                exact_groups[row["content_sha256"]].append(row["file_id"])
            if row.get("normalized_sha256"):
                normalized_groups[row["normalized_sha256"]].append(row["file_id"])
            for owner_alias in row.get("owner_aliases", []):
                owners[owner_alias] += 1
            for parent in row.get("parents", []):
                parent_edges.append({"from": parent, "to": row["file_id"], "type": "DRIVE_PARENT"})
        exact_duplicates = [
            {"sha256": digest, "file_ids": ids}
            for digest, ids in exact_groups.items() if len(ids) > 1
        ]
        normalized_duplicates = [
            {"normalized_sha256": digest, "file_ids": ids}
            for digest, ids in normalized_groups.items() if len(ids) > 1
        ]
        lineage_edges = list(parent_edges)
        for group in exact_duplicates:
            first = group["file_ids"][0]
            lineage_edges.extend({"from": first, "to": other, "type": "EXACT_DUPLICATE"} for other in group["file_ids"][1:])
        for group in normalized_duplicates:
            first = group["file_ids"][0]
            lineage_edges.extend({"from": first, "to": other, "type": "NORMALIZED_CONTENT_DUPLICATE"} for other in group["file_ids"][1:])

        colab_rows = [
            row for row in inspected
            if row.get("mime_type") in NOTEBOOK_MIMES or str(row.get("name", "")).lower().endswith(".ipynb")
        ]
        early_2025 = [
            row for row in colab_rows
            if (row.get("created_time") or "") >= "2025-01-01T00:00:00"
            and (row.get("created_time") or "") < "2025-07-01T00:00:00"
        ]
        early_2025_artifacts = [
            row for row in inspected
            if (row.get("created_time") or "") >= "2025-01-01T00:00:00"
            and (row.get("created_time") or "") < "2025-07-01T00:00:00"
        ]
        timeline = defaultdict(int)
        for row in inspected:
            created = str(row.get("created_time") or "")
            if len(created) >= 7:
                timeline[created[:7]] += 1
        risks = defaultdict(int)
        for row in inspected:
            for category in row.get("execution_review", {}).get("categories", []):
                risks[category] += 1

        return {
            "schema": "nexus.drive-federation.registry.v2",
            "module_version": SCHEMA_VERSION,
            "generated_at_unix_ms": int(time.time() * 1000),
            "scope": {
                "visible_metadata_count": len(metadata),
                "candidate_count": len(candidates),
                "inspected_count": len(inspected),
                "colab_notebook_count": len(colab_rows),
                "jan_jun_2025_colab_count": len(early_2025),
                "jan_jun_2025_relevant_artifact_count": len(early_2025_artifacts),
                "relevant_artifact_timeline_by_month": dict(sorted(timeline.items())),
                "earliest_relevant_artifact_created_time": min(
                    (row.get("created_time") for row in inspected if row.get("created_time")),
                    default=None,
                ),
                "inspection_limit_reached": (
                    max_inspect_files is not None and len(candidates) > max_inspect_files
                ),
                "metadata_scan_complete_for_user_corpus": (
                    self.corpus_status.get("user") == "AVAILABLE"
                    and not self.incomplete_search.get("user", False)
                ),
                "metadata_scan_complete_for_all_drives": (
                    self.corpus_status.get("allDrives") == "AVAILABLE"
                    and not self.incomplete_search.get("allDrives", False)
                ),
                "corpora_status": self.corpus_status,
                "incomplete_search": self.incomplete_search,
                "earliest_colab_created_time": min(
                    (row.get("created_time") for row in colab_rows if row.get("created_time")),
                    default=None,
                ),
                "distinct_owner_alias_count": len(owners),
                "configured_roots": root_records,
                "warnings": self.warnings,
                "created_time_is_drive_metadata_not_proven_source_creation": True,
            },
            "account_owner_summary": [
                {"owner_alias": alias, "inspected_artifact_count": count}
                for alias, count in sorted(owners.items())
            ],
            "artifacts": inspected,
            "duplicates": {
                "exact": exact_duplicates,
                "normalized": normalized_duplicates,
            },
            "lineage_edges": lineage_edges,
            "execution_review_summary": dict(sorted(risks.items())),
        }

    def write_report(self, report: dict[str, Any]) -> dict[str, Path]:
        paths = {
            "registry": self.workspace / "registry.json",
            "inventory": self.workspace / "inventory.jsonl",
            "lineage": self.workspace / "lineage.json",
            "duplicates": self.workspace / "duplicates.json",
            "execution_review": self.workspace / "execution_review.json",
            "account_summary": self.workspace / "account_summary.json",
        }
        paths["registry"].write_bytes(canonical_json_bytes(report) + b"\n")
        with paths["inventory"].open("w", encoding="utf-8") as handle:
            for row in report.get("artifacts", []):
                handle.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")
        paths["lineage"].write_bytes(canonical_json_bytes(report.get("lineage_edges", [])) + b"\n")
        paths["duplicates"].write_bytes(canonical_json_bytes(report.get("duplicates", {})) + b"\n")
        paths["execution_review"].write_bytes(canonical_json_bytes([
            {
                "file_id": row.get("file_id"),
                "name": row.get("name"),
                "review": row.get("execution_review"),
            }
            for row in report.get("artifacts", []) if row.get("execution_review")
        ]) + b"\n")
        paths["account_summary"].write_bytes(canonical_json_bytes({
            "scope": report.get("scope", {}),
            "owners": report.get("account_owner_summary", []),
        }) + b"\n")
        self.receipts.append(
            "REGISTRY_EXPORT",
            file_count=len(report.get("artifacts", [])),
            registry_sha256=sha256_bytes(paths["registry"].read_bytes()),
        )
        # Export a snapshot of the chain after registry generation. Its own
        # subsequent Drive-upload receipt is intentionally recorded locally,
        # not recursively embedded into the snapshot being uploaded.
        paths["receipts"] = self.receipts.path
        return paths

    def upload_new_version(self, local_path: str | Path, folder_id: str, name: str | None = None) -> dict[str, Any]:
        from googleapiclient.http import MediaFileUpload

        path = Path(local_path)
        digest = sha256_bytes(path.read_bytes())
        body = {
            "name": name or path.name,
            "parents": [folder_id],
            "appProperties": {
                "nexusArtifactSha256": digest,
                "nexusFederationVersion": SCHEMA_VERSION,
            },
        }
        media = MediaFileUpload(str(path), resumable=True)
        result = self.service.files().create(
            body=body,
            media_body=media,
            fields="id,name,mimeType,createdTime,webViewLink",
            supportsAllDrives=True,
        ).execute()
        self.receipts.append(
            "PUSH_NEW_VERSION",
            file_id=result.get("id"),
            name=result.get("name"),
            content_sha256=digest,
            parent_folder_id=folder_id,
        )
        return result

    def replace_original(
        self,
        file_id: str,
        local_path: str | Path,
        expected_current_sha256: str,
        backup_folder_id: str,
        confirm: bool = False,
    ) -> dict[str, Any]:
        from googleapiclient.http import MediaFileUpload

        if not confirm:
            raise PermissionError("replace_original requires confirm=True")
        local_path = Path(local_path)
        original = self.get_metadata(file_id)
        if str(original.get("mimeType", "")).startswith("application/vnd.google-apps."):
            raise ValueError("in-place replacement is limited to binary files; export/import native Docs separately")
        current_bytes, _ = self.download_bytes(original)
        current_hash = sha256_bytes(current_bytes)
        if current_hash != expected_current_sha256:
            raise RuntimeError("precondition failed: original bytes changed")
        backup_body = {
            "name": f"{original.get('name', file_id)}.backup.{int(time.time())}",
            "parents": [backup_folder_id],
            "appProperties": {"nexusBackupOf": file_id, "nexusBackupSha256": current_hash},
        }
        backup = self.service.files().copy(
            fileId=file_id, body=backup_body, fields="id,name", supportsAllDrives=True
        ).execute()
        backup_meta = self.get_metadata(backup["id"])
        backup_bytes, _ = self.download_bytes(backup_meta)
        if sha256_bytes(backup_bytes) != expected_current_sha256:
            raise RuntimeError("backup verification failed; original was not updated")
        recheck, _ = self.download_bytes(self.get_metadata(file_id))
        if sha256_bytes(recheck) != expected_current_sha256:
            raise RuntimeError("precondition changed after backup; original was not updated")
        new_hash = sha256_bytes(local_path.read_bytes())
        updated = self.service.files().update(
            fileId=file_id,
            media_body=MediaFileUpload(str(local_path), resumable=True),
            fields="id,name,mimeType,modifiedTime,webViewLink",
            supportsAllDrives=True,
        ).execute()
        self.receipts.append(
            "REPLACE_ORIGINAL",
            file_id=file_id,
            backup_file_id=backup["id"],
            old_sha256=expected_current_sha256,
            new_sha256=new_hash,
            consistency="optimistic_preflight_not_atomic_compare_and_swap",
        )
        return {"updated": updated, "backup": backup, "new_sha256": new_hash}

def group_duplicates(records: Iterable[dict[str, Any]], field: str) -> list[dict[str, Any]]:
    groups: dict[str, list[str]] = defaultdict(list)
    for row in records:
        value = row.get(field)
        if value:
            groups[str(value)].append(str(row.get("file_id")))
    return [{"digest": digest, "file_ids": ids} for digest, ids in groups.items() if len(ids) > 1]
