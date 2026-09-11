#!/usr/bin/env python3
"""Sovereign AI Factory Forge: deterministic opportunity computation.

This first financial layer is analysis-only: it ingests normalized quotes,
calculates executable spreads after fees/slippage, ranks opportunities, and
emits JSON. It does not place orders, move funds, or bypass provider controls.
"""
from __future__ import annotations

import argparse, json, math, time
from dataclasses import dataclass, asdict
from pathlib import Path

@dataclass(frozen=True)
class Quote:
    venue: str
    asset: str
    bid: float
    ask: float
    fee_bps: float = 0.0

@dataclass(frozen=True)
class Opportunity:
    asset: str
    buy_venue: str
    sell_venue: str
    buy: float
    sell: float
    gross_spread_bps: float
    estimated_cost_bps: float
    net_spread_bps: float
    viable: bool


def compute(quotes: list[Quote], slippage_bps: float = 10.0, min_net_bps: float = 25.0) -> list[Opportunity]:
    out: list[Opportunity] = []
    for buy in quotes:
        for sell in quotes:
            if buy.asset != sell.asset or buy.venue == sell.venue:
                continue
            if buy.ask <= 0 or sell.bid <= 0:
                continue
            gross = (sell.bid / buy.ask - 1.0) * 10_000
            costs = buy.fee_bps + sell.fee_bps + slippage_bps
            net = gross - costs
            out.append(Opportunity(buy.asset, buy.venue, sell.venue,
                                   buy.ask, sell.bid, gross, costs, net,
                                   net >= min_net_bps))
    return sorted(out, key=lambda x: x.net_spread_bps, reverse=True)


def load(path: Path) -> list[Quote]:
    raw = json.loads(path.read_text())
    return [Quote(**x) for x in raw]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("quotes")
    ap.add_argument("--slippage-bps", type=float, default=10.0)
    ap.add_argument("--min-net-bps", type=float, default=25.0)
    ap.add_argument("--out", default="artifacts/arbitrage-report.json")
    args = ap.parse_args()
    quotes = load(Path(args.quotes))
    opportunities = compute(quotes, args.slippage_bps, args.min_net_bps)
    report = {
        "schema": "nexus.finance.arbitrage.v1",
        "mode": "analysis_only",
        "generated_at": int(time.time()),
        "capital_required": False,
        "opportunities": [asdict(x) for x in opportunities],
    }
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))

if __name__ == "__main__":
    main()
