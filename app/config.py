"""
Backward compatibility proxy module.
Re-exports from app.core.config.
"""
from .core.config import settings, Settings

__all__ = ["settings", "Settings"]
