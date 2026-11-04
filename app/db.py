"""
Backward compatibility proxy module.
Re-exports from app.core.database.
"""
from .core.database import Base, engine, SessionLocal, get_db

__all__ = ["Base", "engine", "SessionLocal", "get_db"]
