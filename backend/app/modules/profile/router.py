from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.core.container import AppContainer
from app.core.dependencies import get_container, get_current_user_id
from app.modules.profile.schemas import ProfileRead, ProfileUpdateRequest

router = APIRouter(prefix="/profiles", tags=["profiles"])


class PhotoItem(BaseModel):
    url: str = Field(min_length=1)
    order: int = Field(ge=0)


class PhotosUpdateRequest(BaseModel):
    photos: list[PhotoItem] = Field(min_length=1, max_length=10)


def _enrich_with_role(profile, container: AppContainer) -> dict:
    """Add user role to profile dict for ProfileRead serialization."""
    data = profile.__dict__.copy()
    user = container.auth_service.get_user(profile.user_id)
    data["role"] = user.role.value if user else "blogger"
    return data


@router.get("/me", response_model=ProfileRead)
def get_my_profile(
    current_user_id: str = Depends(get_current_user_id),
    container: AppContainer = Depends(get_container),
) -> ProfileRead:
    profile = container.profile_service.get_profile(current_user_id)
    return ProfileRead.model_validate(_enrich_with_role(profile, container))


@router.put("/me", response_model=ProfileRead)
def update_my_profile(
    payload: ProfileUpdateRequest,
    current_user_id: str = Depends(get_current_user_id),
    container: AppContainer = Depends(get_container),
) -> ProfileRead:
    profile = container.profile_service.update_profile(current_user_id, payload)
    return ProfileRead.model_validate(_enrich_with_role(profile, container))


@router.put("/me/photos", response_model=ProfileRead)
def update_my_photos(
    payload: PhotosUpdateRequest,
    current_user_id: str = Depends(get_current_user_id),
    container: AppContainer = Depends(get_container),
) -> ProfileRead:
    """
    Upload/reorder profile photos.

    Body: { photos: [{ url: str, order: int }, ...] }
    Photos are sorted by order field. The first photo becomes the primary.
    """
    sorted_photos = sorted(payload.photos, key=lambda p: p.order)
    photo_urls = [p.url for p in sorted_photos]
    primary = photo_urls[0] if photo_urls else ""

    update_payload = ProfileUpdateRequest(
        photo_urls=photo_urls,
        primary_photo_url=primary,
    )
    profile = container.profile_service.update_profile(current_user_id, update_payload)
    return ProfileRead.model_validate(_enrich_with_role(profile, container))


@router.get("/{user_id}", response_model=ProfileRead)
def get_profile(
    user_id: str,
    container: AppContainer = Depends(get_container),
) -> ProfileRead:
    profile = container.profile_service.get_profile(user_id)
    return ProfileRead.model_validate(_enrich_with_role(profile, container))


# ---------------------------------------------------------------------------
# UGC Gallery — auto-populated from Content Proof submissions
# ---------------------------------------------------------------------------

class UGCPostRead(BaseModel):
    id: str
    blogger_name: str
    blogger_photo_url: str | None = None
    post_url: str
    screenshot_url: str | None = None
    thumbnail_url: str | None = None
    submitted_at: str
    is_hidden: bool = False


@router.get("/{user_id}/ugc", response_model=list[UGCPostRead])
def get_ugc_gallery(
    user_id: str,
    container: AppContainer = Depends(get_container),
) -> list[UGCPostRead]:
    """
    Return UGC Gallery for a business profile.
    Auto-populated from Content Proof submissions by bloggers
    on deals where this user was a participant.
    """
    from datetime import timezone

    # Ensure user exists
    user = container.auth_service.get_user(user_id)
    if not user:
        return []

    # Get all deals where this user was a participant
    deals = container.deal_service.deal_repo.list_for_user(user_id)

    ugc_posts: list[UGCPostRead] = []
    for deal in deals:
        for proof in deal.content_proofs:
            # Only include proofs submitted by the OTHER party (bloggers posting content)
            if proof.submitter_id == user_id:
                continue

            # Resolve blogger profile for name and photo
            blogger_name = "Blogger"
            blogger_photo_url = None
            try:
                blogger_profile = container.profile_service.get_profile(proof.submitter_id)
                blogger_name = blogger_profile.display_name
                blogger_photo_url = blogger_profile.primary_photo_url or None
            except Exception:
                pass

            submitted_at = proof.submitted_at
            if hasattr(submitted_at, "isoformat"):
                submitted_str = submitted_at.isoformat()
            else:
                submitted_str = str(submitted_at)

            ugc_posts.append(
                UGCPostRead(
                    id=f"{deal.id}:{proof.submitter_id}",
                    blogger_name=blogger_name,
                    blogger_photo_url=blogger_photo_url,
                    post_url=proof.post_url,
                    screenshot_url=proof.screenshot_url,
                    thumbnail_url=None,
                    submitted_at=submitted_str,
                    is_hidden=False,
                )
            )

    # Sort by submitted_at descending (newest first)
    ugc_posts.sort(key=lambda p: p.submitted_at, reverse=True)
    return ugc_posts
