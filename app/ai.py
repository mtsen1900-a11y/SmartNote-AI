"""
Backward compatibility proxy module.
Re-exports from app.services.ai_service.
"""
from .services.ai_service import ai_service

# Aliases matching old app.ai interface
chroma = ai_service.chroma
collection = ai_service.collection
ollama_embed = ai_service.embed_texts
ollama_chat = ai_service.chat
split_text = ai_service.split_text
index_note = ai_service.index_note
remove_note_vectors = ai_service.remove_note_vectors
retrieve = ai_service.retrieve

__all__ = [
    "chroma",
    "collection",
    "ollama_embed",
    "ollama_chat",
    "split_text",
    "index_note",
    "remove_note_vectors",
    "retrieve",
]
