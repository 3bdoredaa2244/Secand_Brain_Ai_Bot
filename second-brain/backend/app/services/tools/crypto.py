"""
CryptoTool — real-time cryptocurrency prices via CoinGecko free tier.

No API key required. Rate limit: ~30 req/min on the free plan.
Matches queries containing crypto ticker symbols or trigger words.
"""
import re

import httpx

from app.core.logging import get_logger
from app.services.tools.base import BaseTool, ToolResult

logger = get_logger(__name__)

# ── coin name/ticker → CoinGecko ID ──────────────────────────────────────────
_COIN_MAP: dict[str, str] = {
    "btc": "bitcoin",       "bitcoin": "bitcoin",
    "eth": "ethereum",      "ethereum": "ethereum",
    "sol": "solana",        "solana": "solana",
    "bnb": "binancecoin",   "binance": "binancecoin",
    "xrp": "ripple",        "ripple": "ripple",
    "ada": "cardano",       "cardano": "cardano",
    "doge": "dogecoin",     "dogecoin": "dogecoin",
    "dot": "polkadot",      "polkadot": "polkadot",
    "usdt": "tether",       "tether": "tether",
    "usdc": "usd-coin",
    "link": "chainlink",    "chainlink": "chainlink",
    "matic": "matic-network", "polygon": "matic-network",
    "avax": "avalanche-2",  "avalanche": "avalanche-2",
    "ltc": "litecoin",      "litecoin": "litecoin",
    "shib": "shiba-inu",    "shiba": "shiba-inu",
    "trx": "tron",          "tron": "tron",
    "atom": "cosmos",       "cosmos": "cosmos",
}

# Pre-compiled regex: matches any known ticker/name as a whole word
_COIN_RE = re.compile(
    r"\b(" + "|".join(re.escape(k) for k in sorted(_COIN_MAP, key=len, reverse=True)) + r")\b",
    re.IGNORECASE,
)

# Words that signal "this is a crypto query" even without a ticker
_TRIGGER_WORDS = {"crypto", "cryptocurrency", "token", "coin", "defi", "blockchain", "nft"}

_COINGECKO_URL = "https://api.coingecko.com/api/v3/simple/price"


class CryptoTool(BaseTool):
    name = "crypto"
    description = "Real-time crypto prices from CoinGecko (free, no key)"

    def matches(self, query: str) -> bool:
        lower = query.lower()
        return bool(_COIN_RE.search(lower)) or any(w in lower for w in _TRIGGER_WORDS)

    async def run(self, query: str) -> ToolResult:
        # Extract all mentioned coin IDs, preserving order, deduplicating
        found_ids: list[str] = list(dict.fromkeys(
            _COIN_MAP[m.group(0).lower()]
            for m in _COIN_RE.finditer(query)
            if m.group(0).lower() in _COIN_MAP
        ))

        if not found_ids:
            return ToolResult(
                answer="I recognized this as a crypto question but couldn't identify which coin you mean. "
                       "Try mentioning BTC, ETH, SOL, or another ticker.",
                data={},
            )

        try:
            async with httpx.AsyncClient(timeout=8) as client:
                resp = await client.get(
                    _COINGECKO_URL,
                    params={
                        "ids": ",".join(found_ids),
                        "vs_currencies": "usd",
                        "include_24hr_change": "true",
                        "include_market_cap": "true",
                    },
                )
                resp.raise_for_status()
                data: dict = resp.json()
        except httpx.TimeoutException:
            logger.warning("CryptoTool: CoinGecko request timed out")
            return ToolResult(
                answer="CoinGecko is not responding right now. Try again in a moment.",
                data={},
            )
        except httpx.HTTPStatusError as exc:
            logger.error("CryptoTool: CoinGecko HTTP %s", exc.response.status_code)
            return ToolResult(
                answer=f"CoinGecko returned an error ({exc.response.status_code}). Try again later.",
                data={},
            )
        except Exception as exc:
            logger.error("CryptoTool: unexpected error — %s", exc)
            return ToolResult(answer="Could not fetch crypto prices right now.", data={})

        if not data:
            return ToolResult(
                answer="CoinGecko returned no data for the requested coins. "
                       "The API may be rate-limited — try again in a minute.",
                data={},
            )

        lines: list[str] = []
        for coin_id in found_ids:
            if coin_id not in data:
                continue
            prices = data[coin_id]
            usd = prices.get("usd")
            chg = prices.get("usd_24h_change")
            mcap = prices.get("usd_market_cap")

            usd_str = f"${usd:,.2f}" if usd is not None else "N/A"
            chg_str = f" ({chg:+.2f}% 24h)" if chg is not None else ""
            mcap_str = f" · MCap ${mcap/1e9:.1f}B" if mcap and mcap > 1e9 else ""
            lines.append(f"**{coin_id.title()}**: {usd_str} USD{chg_str}{mcap_str}")

        answer = "\n".join(lines) if lines else "No price data available for the requested coins."
        return ToolResult(answer=answer, data=data)
