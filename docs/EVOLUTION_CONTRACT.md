# NEXUS Core Evolution Contract — 2026-08-26

NEXUS Core is the implementation substrate for the Living System. Changes should remain modular, observable, provenance-aware, and reversible.

## Control loop
OBSERVE → MAP → PROPOSE → VALIDATE → SNAPSHOT → APPLY → TEST → REFLECT → PROMOTE

## Core boundaries
- ADAM governs promotion.
- NEXUS Protocol defines contracts.
- Memory and Ledger remain explicit persistence/provenance boundaries.
- Event Mesh carries typed events rather than implicit global state.
- Runtime adapters isolate Node/Python/Rust/WASM/browser implementations.

## Engineering invariants
1. No credentials or private keys in source control.
2. No destructive migration without a snapshot.
3. No generated mutation is canonical until validation passes.
4. Every capability has an owner, version, input contract, and failure mode.
5. Tests and diagnostics are separated from production execution.
