"""
Chats router.

Endpoints
---------
GET  /chats                         — Chat home: list all chats (matches + conversations)
GET  /chats/{chat_id}               — Full chat detail with messages
GET  /chats/{chat_id}/messages      — Messages for a chat (iOS primary path)
POST /chats/{chat_id}/messages      — Send a message
GET  /chats/{chat_id}/quick-replies — Contextual quick-reply suggestions
POST /chats/{chat_id}/typing        — Signal that the current user is typing
GET  /chats/{chat_id}/typing        — Check if the partner is typing
POST /chats/{chat_id}/mute          — Mute a chat for the current user
POST /chats/{chat_id}/unmute        — Unmute a chat for the current user
POST /chats/{chat_id}/unmatch       — Unmatch: cancel deals, remove chat and match
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from typing import Annotated

from app.core.container import AppContainer
from app.core.dependencies import get_container, get_current_user_id
from app.modules.chats.schemas import (
    ChatDetailRead,
    ChatRead,
    MessageCreateRequest,
    MessageRead,
    QuickRepliesRead,
)

router = APIRouter(prefix="/chats", tags=["chats"])


# ---------------------------------------------------------------------------
# Chat list  — the "Chat Home" screen
# ---------------------------------------------------------------------------

@router.get("", response_model=list[ChatRead])
def list_chats(
    current_user_id: str = Depends(get_current_user_id),
    container: AppContainer = Depends(get_container),
) -> list[ChatRead]:
    """
    Return all chats for the current user (matched + in-progress conversations).
    Each chat exposes participant_ids and match_id so the iOS client can resolve
    profile cards for the chat list header.
    """
    chats = container.chat_service.list_chats(current_user_id)
    return [ChatRead.model_validate(chat) for chat in chats]


# ---------------------------------------------------------------------------
# Create chat (for first message from a match)
# ---------------------------------------------------------------------------

class CreateChatRequest(BaseModel):
    partner_id: str
    match_id: str | None = None


@router.post("", response_model=ChatRead, status_code=201)
def create_chat(
    payload: CreateChatRequest,
    current_user_id: str = Depends(get_current_user_id),
    container: AppContainer = Depends(get_container),
) -> ChatRead:
    """Create or return existing chat between current user and partner."""
    chat = container.chat_service.ensure_direct_chat(
        current_user_id, payload.partner_id, match_id=payload.match_id
    )
    return ChatRead.model_validate(chat)


# ---------------------------------------------------------------------------
# Chat detail
# ---------------------------------------------------------------------------

@router.get("/{chat_id}", response_model=ChatDetailRead)
def get_chat(
    chat_id: str,
    current_user_id: str = Depends(get_current_user_id),
    container: AppContainer = Depends(get_container),
) -> ChatDetailRead:
    """Return a single chat with its full message history."""
    chat, messages = container.chat_service.get_chat(current_user_id, chat_id)
    return ChatDetailRead(
        **ChatRead.model_validate(chat).model_dump(),
        messages=[MessageRead.model_validate(message) for message in messages],
    )


# ---------------------------------------------------------------------------
# Messages sub-resource  (iOS uses these two endpoints directly)
# ---------------------------------------------------------------------------

@router.get("/{chat_id}/messages", response_model=list[MessageRead])
def list_messages(
    chat_id: str,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
    current_user_id: str = Depends(get_current_user_id),
    container: AppContainer = Depends(get_container),
) -> list[MessageRead]:
    """
    Return messages for a chat, newest-last, paginated.

    Query params:
      limit  — max messages to return (default 50)
      offset — skip first N messages
    """
    _, messages = container.chat_service.get_chat(current_user_id, chat_id)
    # Messages are stored oldest-first; honour that ordering for the client
    paged = messages[offset: offset + limit]
    return [MessageRead.model_validate(msg) for msg in paged]


@router.post("/{chat_id}/messages", response_model=MessageRead)
def send_message(
    chat_id: str,
    payload: MessageCreateRequest,
    current_user_id: str = Depends(get_current_user_id),
    container: AppContainer = Depends(get_container),
) -> MessageRead:
    """Send a new message to the chat."""
    message = container.chat_service.send_message(current_user_id, chat_id, payload)
    return MessageRead.model_validate(message)


# ---------------------------------------------------------------------------
# Quick Replies
# ---------------------------------------------------------------------------

@router.get("/{chat_id}/quick-replies", response_model=QuickRepliesRead)
def get_quick_replies(
    chat_id: str,
    current_user_id: str = Depends(get_current_user_id),
    container: AppContainer = Depends(get_container),
) -> QuickRepliesRead:
    """
    Return contextual quick-reply suggestions for the chat.

    Based on deal status, user role, and conversation state.
    """
    replies = container.chat_service.get_quick_replies(current_user_id, chat_id)
    return QuickRepliesRead(replies=replies)


# ---------------------------------------------------------------------------
# Typing Indicator
# ---------------------------------------------------------------------------

_TYPING_TTL_SECONDS = 5  # typing state expires after 5 seconds


class TypingStatusResponse(BaseModel):
    is_typing: bool


@router.post("/{chat_id}/typing", status_code=204)
def post_typing(
    chat_id: str,
    current_user_id: str = Depends(get_current_user_id),
    container: AppContainer = Depends(get_container),
) -> None:
    """Signal that the current user is typing in this chat."""
    from datetime import datetime, timezone

    # Verify user is a participant
    container.chat_service.get_chat(current_user_id, chat_id)
    # Store timestamp
    key = f"{chat_id}:{current_user_id}"
    container.settings  # ensure container is alive
    # Access store's typing_state (works for both in-memory and db)
    if not hasattr(container, "_typing_state"):
        container._typing_state = {}
    container._typing_state[key] = datetime.now(timezone.utc)


@router.get("/{chat_id}/typing", response_model=TypingStatusResponse)
def get_typing(
    chat_id: str,
    current_user_id: str = Depends(get_current_user_id),
    container: AppContainer = Depends(get_container),
) -> TypingStatusResponse:
    """Check if the partner is currently typing."""
    from datetime import datetime, timezone, timedelta

    chat, _ = container.chat_service.get_chat(current_user_id, chat_id)
    partner_id = (
        chat.participant_ids[0]
        if chat.participant_ids[1] == current_user_id
        else chat.participant_ids[1]
    )

    key = f"{chat_id}:{partner_id}"
    if not hasattr(container, "_typing_state"):
        container._typing_state = {}

    last_typed = container._typing_state.get(key)
    if last_typed is None:
        return TypingStatusResponse(is_typing=False)

    elapsed = (datetime.now(timezone.utc) - last_typed).total_seconds()
    is_typing = elapsed < _TYPING_TTL_SECONDS
    # Cleanup expired entry
    if not is_typing:
        container._typing_state.pop(key, None)
    return TypingStatusResponse(is_typing=is_typing)


# ---------------------------------------------------------------------------
# Mute / Unmute / Unmatch
# ---------------------------------------------------------------------------

@router.post("/{chat_id}/mute", response_model=ChatRead)
def mute_chat(
    chat_id: str,
    current_user_id: str = Depends(get_current_user_id),
    container: AppContainer = Depends(get_container),
) -> ChatRead:
    """Mute a chat for the current user."""
    chat = container.chat_service.mute_chat(current_user_id, chat_id)
    return ChatRead.model_validate(chat)


@router.post("/{chat_id}/unmute", response_model=ChatRead)
def unmute_chat(
    chat_id: str,
    current_user_id: str = Depends(get_current_user_id),
    container: AppContainer = Depends(get_container),
) -> ChatRead:
    """Unmute a chat for the current user."""
    chat = container.chat_service.unmute_chat(current_user_id, chat_id)
    return ChatRead.model_validate(chat)


@router.post("/{chat_id}/unmatch")
def unmatch_chat(
    chat_id: str,
    current_user_id: str = Depends(get_current_user_id),
    container: AppContainer = Depends(get_container),
) -> dict:
    """Unmatch: cancel deals, remove chat and match."""
    container.chat_service.unmatch_chat(current_user_id, chat_id)
    return {"detail": "Unmatched successfully."}
