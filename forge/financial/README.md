# Forge Financial Compute

## Phase 1 — free/capital-preserving computation

The Forge begins with computation rather than execution:

1. Collect legally accessible/public quote data.
2. Normalize quotes into the `Quote` schema.
3. Compute gross spread across venues.
4. Subtract configurable fees and slippage.
5. Reject opportunities below the configured net threshold.
6. Record provenance and timestamp before any later promotion.

### Hard boundary

This module is **analysis-only**. It does not place trades, withdraw funds,
rotate accounts, evade limits, or access credentials. Any future execution
adapter must be separately authorized, rate-limited, auditable, and tested in
sandbox/test mode before production use.

## First run

```bash
python3 forge/financial/arbitrage_engine.py forge/financial/sample_quotes.json
```

The output is a ranked report under `artifacts/`.
