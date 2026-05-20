#!/usr/bin/env python3
"""Fetch real-time A-share quote for a stock code.

Example:
    python3 stock_quote.py 513500
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from urllib.error import URLError, HTTPError
from urllib.request import Request, urlopen


def infer_market_prefix(code: str) -> str:
    """Infer market prefix from a 6-digit A-share code."""
    code = code.strip()
    if len(code) != 6 or not code.isdigit():
        raise ValueError(f"invalid stock code: {code!r}")

    # Shanghai: main board, ETFs, bonds, indices often start with 5/6/9.
    if code[0] in {"5", "6", "9"}:
        return "sh"
    return "sz"


@dataclass
class Quote:
    code: str
    name: str
    price: float
    change: float
    change_pct: float
    open: float | None = None
    high: float | None = None
    low: float | None = None
    prev_close: float | None = None
    volume: int | None = None
    amount: float | None = None


def _to_float(value: str) -> float | None:
    value = value.strip()
    if not value or value == "-":
        return None
    try:
        return float(value)
    except ValueError:
        return None


def _to_int(value: str) -> int | None:
    value = value.strip()
    if not value or value == "-":
        return None
    try:
        return int(float(value))
    except ValueError:
        return None


def fetch_quote(code: str) -> Quote:
    prefix = infer_market_prefix(code)
    symbol = f"{prefix}{code}"
    url = f"https://hq.sinajs.cn/list={symbol}"

    req = Request(
        url,
        headers={
            "User-Agent": (
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
            ),
            "Referer": "https://finance.sina.com.cn",
        },
    )

    try:
        with urlopen(req, timeout=10) as resp:
            raw = resp.read()
    except (HTTPError, URLError) as exc:
        raise RuntimeError(f"request failed: {exc}") from exc

    text = raw.decode("gbk", errors="replace").strip()
    # Format:
    # var hq_str_sh513500="名称,今日开盘价,昨收,现价,最高,最低,...";
    try:
        _, payload = text.split("=", 1)
        payload = payload.strip().strip(";").strip('"')
    except ValueError as exc:
        raise RuntimeError(f"unexpected response: {text!r}") from exc

    fields = payload.split(",")
    if len(fields) < 6 or not fields[0]:
        raise RuntimeError(f"empty or malformed quote: {text!r}")

    name = fields[0]
    open_price = _to_float(fields[1])
    prev_close = _to_float(fields[2])
    price = _to_float(fields[3])
    high = _to_float(fields[4])
    low = _to_float(fields[5])
    volume = _to_int(fields[8]) if len(fields) > 8 else None
    amount = _to_float(fields[9]) if len(fields) > 9 else None

    if price is None:
        raise RuntimeError(f"missing latest price in response: {text!r}")

    change = price - prev_close if prev_close is not None else 0.0
    change_pct = (change / prev_close * 100) if prev_close not in (None, 0) else 0.0

    return Quote(
        code=code,
        name=name,
        price=price,
        change=change,
        change_pct=change_pct,
        open=open_price,
        high=high,
        low=low,
        prev_close=prev_close,
        volume=volume,
        amount=amount,
    )


def format_quote(q: Quote) -> str:
    parts = [
        f"{q.code} {q.name}",
        f"最新价: {q.price:.4f}",
        f"涨跌: {q.change:+.4f}",
        f"涨跌幅: {q.change_pct:+.2f}%",
    ]
    if q.open is not None:
        parts.append(f"开盘: {q.open:.4f}")
    if q.high is not None:
        parts.append(f"最高: {q.high:.4f}")
    if q.low is not None:
        parts.append(f"最低: {q.low:.4f}")
    if q.prev_close is not None:
        parts.append(f"昨收: {q.prev_close:.4f}")
    if q.volume is not None:
        parts.append(f"成交量: {q.volume}")
    if q.amount is not None:
        parts.append(f"成交额: {q.amount:.2f}")
    return " | ".join(parts)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Query real-time A-share price")
    parser.add_argument("code", help="6-digit stock code, e.g. 513500")
    parser.add_argument(
        "--json",
        action="store_true",
        help="print raw JSON-like output",
    )
    args = parser.parse_args(argv)

    try:
        quote = fetch_quote(args.code)
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(quote.__dict__, ensure_ascii=False, indent=2))
    else:
        print(format_quote(quote))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
