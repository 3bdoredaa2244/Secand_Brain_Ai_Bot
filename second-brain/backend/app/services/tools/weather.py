"""
WeatherTool — current conditions via wttr.in (free, no API key).

Parses the city from the query using a simple heuristic.
Falls back to a configurable default city when no location is found.
"""
import re

import httpx

from app.core.config import get_settings
from app.core.logging import get_logger
from app.services.tools.base import BaseTool, ToolResult

logger = get_logger(__name__)
settings = get_settings()

_TRIGGER_WORDS = {
    "weather", "temperature", "forecast", "rain", "raining",
    "sunny", "cloudy", "humid", "humidity", "wind", "windy",
    "snow", "snowing", "hot", "cold", "climate",
}

# Pattern: "weather in Cairo", "forecast for London", "weather at Dubai"
_CITY_RE = re.compile(
    r"\b(?:in|for|at|of)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)",
)


class WeatherTool(BaseTool):
    name = "weather"
    description = "Current weather via wttr.in (free, no API key)"

    def matches(self, query: str) -> bool:
        return any(w in query.lower() for w in _TRIGGER_WORDS)

    async def run(self, query: str) -> ToolResult:
        city = _extract_city(query) or getattr(settings, "default_weather_city", "London")

        try:
            async with httpx.AsyncClient(timeout=8) as client:
                resp = await client.get(
                    f"https://wttr.in/{city}",
                    params={"format": "j1"},
                    headers={"User-Agent": "second-brain/1.0"},
                )
                resp.raise_for_status()
                data: dict = resp.json()
        except httpx.TimeoutException:
            logger.warning("WeatherTool: wttr.in timed out for '%s'", city)
            return ToolResult(answer="Weather service timed out. Try again in a moment.", data={})
        except Exception as exc:
            logger.error("WeatherTool: error for '%s' — %s", city, exc)
            return ToolResult(answer=f"Could not fetch weather for {city}.", data={})

        try:
            current = data["current_condition"][0]
            desc    = current["weatherDesc"][0]["value"]
            temp_c  = current["temp_C"]
            temp_f  = current["temp_F"]
            feels_c = current["FeelsLikeC"]
            humidity = current["humidity"]
            visibility = current.get("visibility", "?")

            # Tomorrow's forecast (first entry in weather array)
            tomorrow_desc = ""
            if data.get("weather"):
                w = data["weather"][0]
                hi = w.get("maxtempC", "?")
                lo = w.get("mintempC", "?")
                tomorrow_desc = f"\nTomorrow: {lo}°C – {hi}°C"

            answer = (
                f"**{city}** — {desc}\n"
                f"🌡 {temp_c}°C / {temp_f}°F  (feels like {feels_c}°C)\n"
                f"💧 Humidity: {humidity}%  · 👁 Visibility: {visibility} km"
                f"{tomorrow_desc}"
            )
        except (KeyError, IndexError, TypeError) as exc:
            logger.warning("WeatherTool: unexpected response shape for '%s' — %s", city, exc)
            answer = f"Got a weather response for {city} but couldn't parse it."
            data = {}

        return ToolResult(answer=answer, data=data)


def _extract_city(query: str) -> str | None:
    m = _CITY_RE.search(query)
    return m.group(1) if m else None
