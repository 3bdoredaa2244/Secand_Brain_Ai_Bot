"""
Health-related models.

Data is stored as Obsidian notes (health/ subfolder in vault) so everything
stays local-first and queryable via the RAG system.
"""
from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, Field


class VitaminLog(BaseModel):
    date: date
    vitamins_taken: list[str] = Field(default_factory=list)
    vitamins_missed: list[str] = Field(default_factory=list)
    notes: str = ""


class DailyRoutine(BaseModel):
    name: str
    steps: list[str] = Field(default_factory=list)
    # daily | weekdays | weekends | weekly
    frequency: Literal["daily", "weekdays", "weekends", "weekly"] = "daily"
    # morning | afternoon | evening | anytime
    time_of_day: Literal["morning", "afternoon", "evening", "anytime"] = "morning"
    enabled: bool = True


class DailyHealthSummary(BaseModel):
    """Payload carried by the daily_health_check TriggerEvent."""
    date: str                          # ISO date string
    check_time: str                    # HH:MM
    vitamins_due: list[str] = Field(default_factory=list)
    routines_due: list[str] = Field(default_factory=list)
    notes: str = ""
