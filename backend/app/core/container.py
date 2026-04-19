from __future__ import annotations

import os
import pickle
import threading
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from uuid import uuid4

from app.core.config import Settings

STORE_PERSIST_PATH = os.environ.get("STORE_PERSIST_PATH", "/opt/matcha-backend/data/store.pickle")
from app.modules.auth.domain.models import PlanTier, User, UserRole, VerificationLevel
from app.modules.auth.repository import InMemoryAuthRepository
from app.modules.auth.service import AuthService
from app.modules.chats.domain.models import Chat, Message
from app.modules.chats.repository import InMemoryChatRepository
from app.modules.chats.service import ChatService
from app.modules.deals.domain.models import ContentProof, Deal, DealReview, DealStatus
from app.modules.deals.repository import InMemoryDealRepository
from app.modules.deals.service import DealService
from app.modules.matches.domain.models import Match, MatchSource, MATCH_EXPIRY_HOURS
from app.modules.matches.repository import InMemoryMatchRepository
from app.modules.matches.service import MatchService
from app.modules.offers.domain.models import (
    Offer,
    OfferResponse,
    OfferResponseStatus,
    OfferStatus,
    OfferType,
)
from app.modules.offers.repository import InMemoryOfferRepository
from app.modules.offers.service import OfferService
from app.modules.profile.domain.models import Profile
from app.modules.profile.repository import InMemoryProfileRepository
from app.modules.profile.service import ProfileService

# DB-backed sync repositories (loaded lazily when USE_DB_REPOS=true)
from app.modules.auth.db_repository import SyncDBAuthRepository
from app.modules.profile.db_repository import SyncDBProfileRepository
from app.modules.matches.db_repository import SyncDBMatchRepository
from app.modules.offers.db_repository import SyncDBOfferRepository
from app.modules.chats.db_repository import SyncDBChatRepository
from app.modules.deals.db_repository import SyncDBDealRepository


@dataclass
class InMemoryStore:
    users: dict[str, object] = field(default_factory=dict)
    profiles: dict[str, object] = field(default_factory=dict)
    swipes: dict[str, object] = field(default_factory=dict)
    matches: dict[str, object] = field(default_factory=dict)
    offers: dict[str, object] = field(default_factory=dict)
    offer_responses: dict[str, object] = field(default_factory=dict)
    chats: dict[str, object] = field(default_factory=dict)
    messages: dict[str, object] = field(default_factory=dict)
    deals: dict[str, object] = field(default_factory=dict)
    typing_state: dict[str, object] = field(default_factory=dict)
    # typing_state: { "chat_id:user_id": datetime } — last typing timestamp

    def __getstate__(self):
        """Remove non-pickleable fields."""
        state = self.__dict__.copy()
        state.pop("_lock", None)
        return state

    def __setstate__(self, state):
        self.__dict__.update(state)

    def persist(self) -> None:
        """Save store to disk so data survives restarts."""
        try:
            tmp = STORE_PERSIST_PATH + ".tmp"
            with open(tmp, "wb") as f:
                pickle.dump(self, f, protocol=pickle.HIGHEST_PROTOCOL)
            os.replace(tmp, STORE_PERSIST_PATH)
        except Exception as e:
            import logging
            logging.getLogger(__name__).warning("Failed to persist store: %s", e)

    @staticmethod
    def load_from_disk() -> "InMemoryStore | None":
        """Load store from disk if available."""
        try:
            if os.path.exists(STORE_PERSIST_PATH) and os.path.getsize(STORE_PERSIST_PATH) > 0:
                with open(STORE_PERSIST_PATH, "rb") as f:
                    store = pickle.load(f)
                    if isinstance(store, InMemoryStore):
                        return store
        except Exception as e:
            import logging
            logging.getLogger(__name__).warning("Failed to load store: %s", e)
        return None


@dataclass
class AppContainer:
    settings: Settings
    auth_service: AuthService
    profile_service: ProfileService
    match_service: MatchService
    offer_service: OfferService
    chat_service: ChatService
    deal_service: DealService


# ---------------------------------------------------------------------------
# Seed helpers
# ---------------------------------------------------------------------------

def _now() -> datetime:
    now = datetime.now(timezone.utc)
    return now.replace(microsecond=(now.microsecond // 1000) * 1000)


def _ago(**kwargs) -> datetime:
    dt = _now() - timedelta(**kwargs)
    return dt.replace(microsecond=(dt.microsecond // 1000) * 1000)


def _seed_store(store: InMemoryStore) -> None:
    """Populate the store with realistic Bali business & blogger profiles for development/demo."""
    from app.core.security import hash_password

    # ------------------------------------------------------------------
    # Users  (stable IDs survive pickle reloads)
    # ------------------------------------------------------------------
    pw = hash_password("Password123!")

    # --- Businesses ---
    business1 = User(
        id="business-1",
        email="hello@thelawncanggu.com",
        password_hash=pw,
        role=UserRole.BUSINESS,
        full_name="The Lawn Canggu",
        is_active=True,
        verification_level=VerificationLevel.VERIFIED,
        plan_tier=PlanTier.PRO,
        offer_credits=5,
        created_at=_ago(days=90),
        updated_at=_ago(days=1),
    )
    business2 = User(
        id="business-2",
        email="collab@motelmexicola.com",
        password_hash=pw,
        role=UserRole.BUSINESS,
        full_name="Motel Mexicola",
        is_active=True,
        verification_level=VerificationLevel.BLUE_CHECK,
        plan_tier=PlanTier.BLACK,
        offer_credits=10,
        created_at=_ago(days=120),
        updated_at=_ago(hours=6),
    )
    business3 = User(
        id="business-3",
        email="marketing@comoumacanggu.com",
        password_hash=pw,
        role=UserRole.BUSINESS,
        full_name="COMO Uma Canggu",
        is_active=True,
        verification_level=VerificationLevel.VERIFIED,
        plan_tier=PlanTier.PRO,
        offer_credits=4,
        created_at=_ago(days=60),
        updated_at=_ago(days=2),
    )
    business4 = User(
        id="business-4",
        email="collab@potatohead.co",
        password_hash=pw,
        role=UserRole.BUSINESS,
        full_name="Potato Head",
        is_active=True,
        verification_level=VerificationLevel.BLUE_CHECK,
        plan_tier=PlanTier.BLACK,
        offer_credits=12,
        created_at=_ago(days=180),
        updated_at=_ago(hours=3),
    )
    business5 = User(
        id="business-5",
        email="hello@zincafe.com",
        password_hash=pw,
        role=UserRole.BUSINESS,
        full_name="Zin Cafe",
        is_active=True,
        verification_level=VerificationLevel.VERIFIED,
        plan_tier=PlanTier.FREE,
        offer_credits=2,
        created_at=_ago(days=30),
        updated_at=_ago(days=1),
    )

    # --- Bloggers ---
    blogger1 = User(
        id="blogger-1",
        email="sarah@adventures.blog",
        password_hash=pw,
        role=UserRole.BLOGGER,
        full_name="Sarah Adventures",
        is_active=True,
        verification_level=VerificationLevel.VERIFIED,
        plan_tier=PlanTier.PRO,
        offer_credits=3,
        created_at=_ago(days=45),
        updated_at=_ago(days=1),
    )
    blogger2 = User(
        id="blogger-2",
        email="kevin@wellnesslife.de",
        password_hash=pw,
        role=UserRole.BLOGGER,
        full_name="Kevin Wellness",
        is_active=True,
        verification_level=VerificationLevel.VERIFIED,
        plan_tier=PlanTier.FREE,
        offer_credits=1,
        created_at=_ago(days=20),
        updated_at=_ago(hours=4),
    )
    blogger3 = User(
        id="blogger-3",
        email="maya@pacestyle.fr",
        password_hash=pw,
        role=UserRole.BLOGGER,
        full_name="Maya Pace",
        is_active=True,
        verification_level=VerificationLevel.VERIFIED,
        plan_tier=PlanTier.FREE,
        offer_credits=1,
        created_at=_ago(days=15),
        updated_at=_ago(days=2),
    )
    blogger4 = User(
        id="blogger-4",
        email="aria@moonlife.us",
        password_hash=pw,
        role=UserRole.BLOGGER,
        full_name="Aria Moon",
        is_active=True,
        verification_level=VerificationLevel.BLUE_CHECK,
        plan_tier=PlanTier.PRO,
        offer_credits=5,
        created_at=_ago(days=75),
        updated_at=_ago(hours=1),
    )
    blogger5 = User(
        id="blogger-5",
        email="marco@surflife.br",
        password_hash=pw,
        role=UserRole.BLOGGER,
        full_name="Marco Surf",
        is_active=True,
        verification_level=VerificationLevel.VERIFIED,
        plan_tier=PlanTier.PRO,
        offer_credits=3,
        created_at=_ago(days=40),
        updated_at=_ago(days=1),
    )

    # --- Dev test user (pre-seeded so matches work immediately) ---
    dev_user = User(
        id="dev-user-1",
        email="dev@matcha.app",
        password_hash=pw,
        role=UserRole.BLOGGER,
        full_name="Dev User",
        is_active=True,
        verification_level=VerificationLevel.VERIFIED,
        plan_tier=PlanTier.PRO,
        offer_credits=5,
        created_at=_ago(days=7),
        updated_at=_now(),
    )

    # --- Ded test user ---
    ded_user = User(
        id="ded-user-1",
        email="ded@matcha.app",
        password_hash=pw,
        role=UserRole.BLOGGER,
        full_name="Ded",
        is_active=True,
        verification_level=VerificationLevel.VERIFIED,
        plan_tier=PlanTier.PRO,
        offer_credits=5,
        created_at=_ago(days=3),
        updated_at=_now(),
    )

    all_users = [
        dev_user, ded_user,
        business1, business2, business3, business4, business5,
        blogger1, blogger2, blogger3, blogger4, blogger5,
    ]
    for u in all_users:
        store.users[u.id] = u

    # ------------------------------------------------------------------
    # Profiles
    # ------------------------------------------------------------------

    # --- Business profiles ---
    p_biz1 = Profile(
        user_id="business-1",
        display_name="The Lawn Canggu",
        photo_urls=[
            "https://images.unsplash.com/photo-1540541338287-41700207dee6?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1551632436-cbf8dd35adfa?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=1000&fit=crop",
        ],
        primary_photo_url="https://images.unsplash.com/photo-1540541338287-41700207dee6?w=800&h=1000&fit=crop",
        country="Indonesia",
        instagram_handle="thelawncanggu",
        audience_size=87000,
        category="beach_club",
        district="Canggu",
        niches=["lifestyle", "food", "nightlife"],
        languages=["en", "id"],
        bio="Beachfront club & restaurant on Batu Bolong, Canggu. Sunset sessions, craft cocktails & live DJs.",
        what_we_offer="Free dinner for 2 + sunset cocktails in exchange for 1 Reel + 3 Stories.",
        collab_type="barter",
        badges=["verified_business"],
        verified_visits=56,
        rating=4.7,
        review_count=42,
        created_at=_ago(days=90),
        updated_at=_ago(days=1),
    )
    p_biz2 = Profile(
        user_id="business-2",
        display_name="Motel Mexicola",
        photo_urls=[
            "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1551024506-0bccd828d307?w=800&h=1000&fit=crop",
        ],
        primary_photo_url="https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800&h=1000&fit=crop",
        country="Indonesia",
        instagram_handle="motelmexicola",
        audience_size=124000,
        category="restaurant",
        district="Seminyak",
        niches=["food", "nightlife", "lifestyle", "travel"],
        languages=["en", "id"],
        bio="Neon-lit Mexican cantina & bar in Seminyak. Tacos, tequila & fiesta every night.",
        what_we_offer="Dinner for 2 + signature margaritas in exchange for 1 Reel + 2 Stories + 1 post.",
        collab_type="barter",
        badges=["verified_business", "top_brand"],
        verified_visits=89,
        rating=4.8,
        review_count=67,
        created_at=_ago(days=120),
        updated_at=_ago(hours=6),
    )
    p_biz3 = Profile(
        user_id="business-3",
        display_name="COMO Uma Canggu",
        photo_urls=[
            "https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800&h=1000&fit=crop",
        ],
        primary_photo_url="https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&h=1000&fit=crop",
        country="Indonesia",
        instagram_handle="comoumacanggu",
        audience_size=52000,
        category="accommodation",
        district="Canggu",
        niches=["travel", "wellness", "lifestyle"],
        languages=["en", "id"],
        bio="Luxury surf resort on Echo Beach. World-class spa, surf butler & beachfront pool.",
        what_we_offer="2-night villa stay + spa treatment in exchange for 1 YouTube video or 2 Reels + 5 Stories.",
        collab_type="both",
        badges=["verified_business"],
        verified_visits=31,
        rating=4.9,
        review_count=22,
        created_at=_ago(days=60),
        updated_at=_ago(days=2),
    )
    p_biz4 = Profile(
        user_id="business-4",
        display_name="Potato Head",
        photo_urls=[
            "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1533777857889-4be7c70b33f7?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&h=1000&fit=crop",
        ],
        primary_photo_url="https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800&h=1000&fit=crop",
        country="Indonesia",
        instagram_handle="potatoheadbali",
        audience_size=210000,
        category="beach_club",
        district="Seminyak",
        niches=["lifestyle", "food", "nightlife", "travel"],
        languages=["en", "id"],
        bio="Iconic beach club, restaurant & creative space on Petitenget Beach, Seminyak.",
        what_we_offer="VIP day pass + lunch for 2 + cocktails in exchange for 1 Reel + 3 Stories.",
        collab_type="barter",
        badges=["verified_business", "top_brand"],
        verified_visits=112,
        rating=4.8,
        review_count=95,
        created_at=_ago(days=180),
        updated_at=_ago(hours=3),
    )
    p_biz5 = Profile(
        user_id="business-5",
        display_name="Zin Cafe",
        photo_urls=[
            "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1498804103079-a6351b050096?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800&h=1000&fit=crop",
        ],
        primary_photo_url="https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&h=1000&fit=crop",
        country="Indonesia",
        instagram_handle="zincafebali",
        audience_size=15000,
        category="restaurant",
        district="Canggu",
        niches=["food", "wellness", "lifestyle"],
        languages=["en", "id"],
        bio="Plant-based cafe & smoothie bar in Berawa, Canggu. Organic bowls, cold-pressed juice & good vibes.",
        what_we_offer="Brunch for 2 in exchange for 3 Stories featuring our menu.",
        collab_type="barter",
        badges=["verified_business"],
        verified_visits=8,
        rating=4.5,
        review_count=6,
        created_at=_ago(days=30),
        updated_at=_ago(days=1),
    )

    # --- Blogger profiles ---
    p_b1 = Profile(
        user_id="blogger-1",
        display_name="Sarah Adventures",
        photo_urls=[
            "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1528164344705-47542687000d?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1519046904884-53103b34b206?w=800&h=1000&fit=crop",
        ],
        primary_photo_url="https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&h=1000&fit=crop",
        country="Australia",
        instagram_handle="sarahadventures",
        tiktok_handle="sarahadventures",
        audience_size=34000,
        category="travel",
        district="Uluwatu",
        niches=["travel", "food", "lifestyle"],
        languages=["en"],
        bio="Aussie travel creator exploring Southeast Asia. Beaches, temples & hidden gems.",
        description="Documenting life across Bali one sunrise at a time. Specialising in travel guides and honest restaurant reviews.",
        collab_type="both",
        badges=["verified", "top_creator"],
        verified_visits=18,
        rating=4.7,
        review_count=14,
        created_at=_ago(days=45),
        updated_at=_ago(days=1),
    )
    p_b2 = Profile(
        user_id="blogger-2",
        display_name="Kevin Wellness",
        photo_urls=[
            "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&h=1000&fit=crop",
        ],
        primary_photo_url="https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&h=1000&fit=crop",
        country="Germany",
        instagram_handle="kevinwellness",
        audience_size=18000,
        category="fitness",
        district="Canggu",
        niches=["fitness", "wellness", "travel"],
        languages=["en", "de"],
        bio="German fitness coach living in Canggu. Yoga, surf & healthy living content.",
        description="Creating workout and wellness content from Bali. Partner with gyms, retreats and health brands.",
        collab_type="barter",
        badges=["verified"],
        verified_visits=7,
        rating=4.5,
        review_count=5,
        created_at=_ago(days=20),
        updated_at=_ago(hours=4),
    )
    p_b3 = Profile(
        user_id="blogger-3",
        display_name="Maya Pace",
        photo_urls=[
            "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1540555700478-4be289fbec6d?w=800&h=1000&fit=crop",
        ],
        primary_photo_url="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&h=1000&fit=crop",
        country="France",
        instagram_handle="mayapace",
        audience_size=12000,
        category="beauty",
        district="Seminyak",
        niches=["beauty", "lifestyle", "fashion"],
        languages=["en", "fr"],
        bio="French beauty & lifestyle creator based in Seminyak. Skincare, fashion & tropical aesthetics.",
        description="Beauty content with a tropical twist. Working with skincare brands, spas and fashion boutiques in Bali.",
        collab_type="both",
        badges=["verified"],
        verified_visits=4,
        rating=4.6,
        review_count=3,
        created_at=_ago(days=15),
        updated_at=_ago(days=2),
    )
    p_b4 = Profile(
        user_id="blogger-4",
        display_name="Aria Moon",
        photo_urls=[
            "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=800&h=1000&fit=crop",
        ],
        primary_photo_url="https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&h=1000&fit=crop",
        country="United States",
        instagram_handle="ariamoon",
        tiktok_handle="ariamoonlife",
        audience_size=45000,
        category="lifestyle",
        district="Ubud",
        niches=["lifestyle", "wellness", "travel", "food"],
        languages=["en"],
        bio="NYC to Ubud. Lifestyle & wellness creator sharing intentional living from the rice terraces.",
        description="Creating aesthetic lifestyle content around mindful living, co-working culture and Ubud's food scene.",
        collab_type="both",
        badges=["blue_check", "top_creator"],
        verified_visits=22,
        rating=4.9,
        review_count=19,
        created_at=_ago(days=75),
        updated_at=_ago(hours=1),
    )
    p_b5 = Profile(
        user_id="blogger-5",
        display_name="Marco Surf",
        photo_urls=[
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1502933691298-84fc14542831?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1530549387789-4c1017266635?w=800&h=1000&fit=crop",
        ],
        primary_photo_url="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&h=1000&fit=crop",
        country="Brazil",
        instagram_handle="marcosurf",
        tiktok_handle="marcosurfbali",
        audience_size=28000,
        category="sports",
        district="Berawa",
        niches=["surf", "fitness", "travel"],
        languages=["en", "pt"],
        bio="Brazilian surfer & content creator. Chasing waves from Berawa to Uluwatu.",
        description="Action sports content — surf, skate and adventure. Working with board brands, camps and active-lifestyle businesses.",
        collab_type="both",
        badges=["verified"],
        verified_visits=15,
        rating=4.7,
        review_count=11,
        created_at=_ago(days=40),
        updated_at=_ago(days=1),
    )

    all_profiles = [
        p_biz1, p_biz2, p_biz3, p_biz4, p_biz5,
        p_b1, p_b2, p_b3, p_b4, p_b5,
    ]
    for p in all_profiles:
        store.profiles[p.user_id] = p

    # Dev user profile
    p_dev = Profile(
        user_id="dev-user-1",
        display_name="Dev User",
        photo_urls=[
            "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1506863530036-1efeddceb993?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=800&h=1000&fit=crop",
            "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&h=1000&fit=crop",
        ],
        primary_photo_url="https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&h=1000&fit=crop",
        country="Russia",
        instagram_handle="devuser",
        audience_size=5000,
        district="Canggu",
        niches=["lifestyle", "travel"],
        languages=["en", "ru"],
        bio="Testing MATCHA app. Looking for collab opportunities in Bali.",
        collab_type="both",
        badges=[],
        verified_visits=3,
        rating=4.8,
        review_count=5,
        created_at=_ago(days=7),
        updated_at=_now(),
    )
    store.profiles["dev-user-1"] = p_dev

    # Ded user profile
    p_ded = Profile(
        user_id="ded-user-1",
        display_name="Ded",
        photo_urls=["https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&h=1000&fit=crop"],
        primary_photo_url="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&h=1000&fit=crop",
        country="Russia",
        instagram_handle="ded",
        audience_size=15000,
        district="Canggu",
        niches=["lifestyle", "travel", "food"],
        languages=["en", "ru"],
        bio="Exploring Bali life. Content creator & travel blogger.",
        collab_type="both",
        badges=["verified"],
        verified_visits=3,
        rating=4.5,
        review_count=2,
        created_at=_ago(days=3),
        updated_at=_now(),
    )
    store.profiles["ded-user-1"] = p_ded

    # ------------------------------------------------------------------
    # Matches (dev user matched with 3 businesses)
    # ------------------------------------------------------------------
    match1_id = "match-1"
    match2_id = "match-2"
    match_dev1_id = "match-dev-1"
    match_dev2_id = "match-dev-2"
    match_dev3_id = "match-dev-3"

    def _match_expires(created):
        """expires_at = created_at + 48h (MATCH_EXPIRY_HOURS)."""
        return created + timedelta(hours=MATCH_EXPIRY_HOURS)

    match1 = Match(
        id=match1_id,
        user_ids=("blogger-1", "business-1"),
        source=MatchSource.SWIPE,
        created_at=_ago(days=5),
        expires_at=_match_expires(_ago(days=5)),
    )
    match2 = Match(
        id=match2_id,
        user_ids=("blogger-4", "business-2"),
        source=MatchSource.OFFER,
        created_at=_ago(days=10),
        expires_at=_match_expires(_ago(days=10)),
    )
    # Dev user matches — varied timer states for demo
    _dev1_created = _ago(hours=6)
    match_dev1 = Match(
        id=match_dev1_id,
        user_ids=("dev-user-1", "business-1"),
        source=MatchSource.SWIPE,
        created_at=_dev1_created,
        expires_at=_match_expires(_dev1_created),
    )
    _dev2_created = _ago(hours=36)
    match_dev2 = Match(
        id=match_dev2_id,
        user_ids=("dev-user-1", "business-2"),
        source=MatchSource.SWIPE,
        created_at=_dev2_created,
        expires_at=_match_expires(_dev2_created),
    )
    _dev3_created = _ago(hours=2)
    match_dev3 = Match(
        id=match_dev3_id,
        user_ids=("dev-user-1", "business-3"),
        source=MatchSource.SWIPE,
        created_at=_dev3_created,
        expires_at=_match_expires(_dev3_created),
    )
    # Ded user matches — with 3 businesses, fresh timers
    _ded1_created = _ago(hours=2)
    match_ded1 = Match(
        id="match-ded-1",
        user_ids=tuple(sorted(("ded-user-1", "business-1"))),
        source=MatchSource.SWIPE,
        created_at=_ded1_created,
        expires_at=_match_expires(_ded1_created),
    )
    _ded2_created = _ago(hours=6)
    match_ded2 = Match(
        id="match-ded-2",
        user_ids=tuple(sorted(("ded-user-1", "business-2"))),
        source=MatchSource.SWIPE,
        created_at=_ded2_created,
        expires_at=_match_expires(_ded2_created),
    )
    _ded3_created = _ago(hours=1)
    match_ded3 = Match(
        id="match-ded-3",
        user_ids=tuple(sorted(("ded-user-1", "business-4"))),
        source=MatchSource.OFFER,
        created_at=_ded3_created,
        expires_at=_match_expires(_ded3_created),
    )

    store.matches[match1_id] = match1
    store.matches[match2_id] = match2
    store.matches[match_dev1_id] = match_dev1
    store.matches[match_dev2_id] = match_dev2
    store.matches[match_dev3_id] = match_dev3
    store.matches["match-ded-1"] = match_ded1
    store.matches["match-ded-2"] = match_ded2
    store.matches["match-ded-3"] = match_ded3

    # Fresh matches WITHOUT chats — show in New Matches stories with timer rings
    _dev_fresh1_created = _ago(hours=3)
    store.matches["match-dev-fresh-1"] = Match(
        id="match-dev-fresh-1",
        user_ids=tuple(sorted(("dev-user-1", "business-4"))),
        source=MatchSource.SWIPE,
        first_message_by="dev-user-1",
        created_at=_dev_fresh1_created,
        expires_at=_match_expires(_dev_fresh1_created),
    )
    _dev_fresh2_created = _ago(hours=40)
    store.matches["match-dev-fresh-2"] = Match(
        id="match-dev-fresh-2",
        user_ids=tuple(sorted(("dev-user-1", "business-5"))),
        source=MatchSource.SWIPE,
        first_message_by="dev-user-1",
        created_at=_dev_fresh2_created,
        expires_at=_match_expires(_dev_fresh2_created),
    )
    _dev_fresh3_created = _ago(minutes=30)
    store.matches["match-dev-fresh-3"] = Match(
        id="match-dev-fresh-3",
        user_ids=tuple(sorted(("dev-user-1", "blogger-3"))),
        source=MatchSource.SWIPE,
        first_message_by="dev-user-1",
        created_at=_dev_fresh3_created,
        expires_at=_match_expires(_dev_fresh3_created),
    )

    # Fresh matches for ded-user without chats
    _ded_fresh1 = _ago(hours=4)
    store.matches["match-ded-fresh-1"] = Match(
        id="match-ded-fresh-1",
        user_ids=tuple(sorted(("ded-user-1", "business-5"))),
        source=MatchSource.SWIPE,
        first_message_by="ded-user-1",
        created_at=_ded_fresh1,
        expires_at=_match_expires(_ded_fresh1),
    )
    _ded_fresh2 = _ago(hours=44)
    store.matches["match-ded-fresh-2"] = Match(
        id="match-ded-fresh-2",
        user_ids=tuple(sorted(("ded-user-1", "blogger-3"))),
        source=MatchSource.SWIPE,
        first_message_by="ded-user-1",
        created_at=_ded_fresh2,
        expires_at=_match_expires(_ded_fresh2),
    )

    # ------------------------------------------------------------------
    # Chats
    # ------------------------------------------------------------------
    chat1_id = "chat-1"
    chat2_id = "chat-2"
    chat1 = Chat(
        id=chat1_id,
        participant_ids=("blogger-1", "business-1"),
        match_id=match1_id,
        created_at=_ago(days=5),
        updated_at=_ago(hours=1),
    )
    chat2 = Chat(
        id=chat2_id,
        participant_ids=("blogger-4", "business-2"),
        match_id=match2_id,
        created_at=_ago(days=10),
        updated_at=_ago(days=1),
    )
    # Dev user chats
    chat_dev1 = Chat(
        id="chat-dev-1",
        participant_ids=("business-1", "dev-user-1"),
        match_id=match_dev1_id,
        created_at=_ago(days=2),
        updated_at=_ago(hours=1),
    )
    chat_dev2 = Chat(
        id="chat-dev-2",
        participant_ids=("business-2", "dev-user-1"),
        match_id=match_dev2_id,
        created_at=_ago(days=1),
        updated_at=_ago(hours=3),
    )
    chat_dev3 = Chat(
        id="chat-dev-3",
        participant_ids=("business-3", "dev-user-1"),
        match_id=match_dev3_id,
        created_at=_ago(hours=12),
        updated_at=_ago(hours=6),
    )
    # Ded user chats
    chat_ded1 = Chat(
        id="chat-ded-1",
        participant_ids=tuple(sorted(("ded-user-1", "business-1"))),
        match_id="match-ded-1",
        created_at=_ago(hours=2),
        updated_at=_ago(minutes=30),
    )
    chat_ded2 = Chat(
        id="chat-ded-2",
        participant_ids=tuple(sorted(("ded-user-1", "business-2"))),
        match_id="match-ded-2",
        created_at=_ago(hours=6),
        updated_at=_ago(hours=1),
    )
    chat_ded3 = Chat(
        id="chat-ded-3",
        participant_ids=tuple(sorted(("ded-user-1", "business-4"))),
        match_id="match-ded-3",
        created_at=_ago(hours=1),
        updated_at=_ago(minutes=10),
    )

    # Dev user: chats WITHOUT deals (appear in Messages segment)
    chat_dev_msg1 = Chat(
        id="chat-dev-msg-1",
        participant_ids=tuple(sorted(("dev-user-1", "blogger-1"))),
        match_id=match1_id,
        created_at=_ago(hours=4),
        updated_at=_ago(minutes=15),
    )
    chat_dev_msg2 = Chat(
        id="chat-dev-msg-2",
        participant_ids=tuple(sorted(("dev-user-1", "blogger-3"))),
        match_id=None,
        created_at=_ago(hours=8),
        updated_at=_ago(hours=1),
    )

    store.chats[chat1_id] = chat1
    store.chats[chat2_id] = chat2
    store.chats["chat-dev-1"] = chat_dev1
    store.chats["chat-dev-2"] = chat_dev2
    store.chats["chat-dev-3"] = chat_dev3
    store.chats["chat-dev-msg-1"] = chat_dev_msg1
    store.chats["chat-dev-msg-2"] = chat_dev_msg2
    store.chats["chat-ded-1"] = chat_ded1
    store.chats["chat-ded-2"] = chat_ded2
    store.chats["chat-ded-3"] = chat_ded3

    # Messages
    msgs = [
        Message(
            id="msg-1",
            chat_id=chat1_id,
            sender_id="business-1",
            text="Hey Sarah! Loved your travel content. Would love to host you at The Lawn for a collab!",
            created_at=_ago(days=5),
        ),
        Message(
            id="msg-2",
            chat_id=chat1_id,
            sender_id="blogger-1",
            text="Hi! Thanks so much! The Lawn looks incredible. I'm definitely interested!",
            created_at=_ago(days=4, hours=23),
        ),
        Message(
            id="msg-3",
            chat_id=chat1_id,
            sender_id="business-1",
            text="Great! Here's our deal offer:",
            deal_card_id="deal-1",
            created_at=_ago(hours=2),
        ),
        Message(
            id="msg-4",
            chat_id=chat2_id,
            sender_id="blogger-4",
            text="Super excited about the Motel Mexicola collab! The vibe is exactly my aesthetic.",
            created_at=_ago(days=10),
        ),
        Message(
            id="msg-5",
            chat_id=chat2_id,
            sender_id="business-2",
            text="We love your content, Aria! Let's make it happen.",
            created_at=_ago(days=9),
        ),
    ]
    # Dev user messages
    dev_msgs = [
        Message(
            id="msg-dev-1", chat_id="chat-dev-1", sender_id="business-1",
            text="Hey! We'd love to host you at The Lawn for a sunset collab. Interested?",
            created_at=_ago(days=2),
        ),
        Message(
            id="msg-dev-2", chat_id="chat-dev-1", sender_id="dev-user-1",
            text="Sounds amazing! What kind of content are you looking for?",
            created_at=_ago(days=1, hours=23),
        ),
        Message(
            id="msg-dev-3", chat_id="chat-dev-1", sender_id="business-1",
            text="1 Reel + 3 Stories covering the sunset session and our signature cocktails.",
            created_at=_ago(days=1, hours=22),
        ),
        Message(
            id="msg-dev-4", chat_id="chat-dev-2", sender_id="business-2",
            text="Hi! Your content style would be perfect for Motel Mexicola vibes. Let's collab!",
            created_at=_ago(days=1),
        ),
        Message(
            id="msg-dev-5", chat_id="chat-dev-2", sender_id="dev-user-1",
            text="Love it! When would work for you?",
            created_at=_ago(hours=20),
        ),
        Message(
            id="msg-dev-6", chat_id="chat-dev-3", sender_id="business-3",
            text="Welcome to COMO Uma! We offer a 2-night stay for creators. Interested in a luxury content collab?",
            created_at=_ago(hours=12),
        ),
    ]
    # Ded user messages
    ded_msgs = [
        Message(
            id="msg-ded-1", chat_id="chat-ded-1", sender_id="business-1",
            text="Welcome! We'd love to feature you at The Lawn this weekend. Here's a deal 🤝",
            created_at=_ago(hours=2),
        ),
        Message(
            id="msg-ded-2", chat_id="chat-ded-1", sender_id="ded-user-1",
            text="Looks perfect, accepted! See you Saturday 🌅",
            created_at=_ago(hours=1, minutes=30),
        ),
        Message(
            id="msg-ded-3", chat_id="chat-ded-1", sender_id="system",
            text="✅ Deal confirmed!",
            is_system=True,
            message_type="deal_status",
            created_at=_ago(hours=1),
        ),
        Message(
            id="msg-ded-4", chat_id="chat-ded-2", sender_id="ded-user-1",
            text="Hey! Love the Motel Mexicola vibe. Interested in a brunch collab?",
            created_at=_ago(hours=6),
        ),
        Message(
            id="msg-ded-5", chat_id="chat-ded-2", sender_id="business-2",
            text="Sounds fun! What do you have in mind?",
            created_at=_ago(hours=5),
        ),
        Message(
            id="msg-ded-6", chat_id="chat-ded-3", sender_id="business-4",
            text="Hi! Your aesthetic is perfect for our beach club. Let's work together ☕",
            created_at=_ago(hours=1),
        ),
    ]
    # Dev user deal-related messages
    dev_deal_msgs = [
        Message(
            id="msg-dev-deal-1", chat_id="chat-dev-2", sender_id="dev-user-1",
            text="Here's my proposal for the party night collab 🎉",
            deal_card_id="deal-dev-draft",
            created_at=_ago(hours=3),
        ),
        Message(
            id="msg-dev-deal-2", chat_id="chat-dev-2", sender_id="business-2",
            text="Checking with the team, will get back to you!",
            created_at=_ago(hours=2),
        ),
        Message(
            id="msg-dev-deal-3", chat_id="chat-dev-3", sender_id="business-3",
            text="Great! Here's our deal offer 🤝",
            deal_card_id="deal-dev-confirmed",
            created_at=_ago(hours=6),
        ),
        Message(
            id="msg-dev-deal-4", chat_id="chat-dev-3", sender_id="dev-user-1",
            text="This looks amazing, accepted! Can't wait 🙌",
            created_at=_ago(hours=5),
        ),
        Message(
            id="msg-dev-deal-5", chat_id="chat-dev-3", sender_id="system",
            text="✅ Deal confirmed!",
            is_system=True,
            message_type="deal_status",
            created_at=_ago(hours=5),
        ),
        Message(
            id="msg-dev-deal-6", chat_id="chat-dev-1", sender_id="business-1",
            text="Had a great time hosting you! Don't forget to check in 🌴",
            created_at=_ago(days=1, hours=2),
        ),
        Message(
            id="msg-dev-deal-7", chat_id="chat-dev-1", sender_id="system",
            text="📍 Both sides checked in!",
            is_system=True,
            message_type="deal_status",
            created_at=_ago(days=1),
        ),
        Message(
            id="msg-dev-deal-8", chat_id="chat-dev-1", sender_id="dev-user-1",
            text="Amazing experience! Content coming soon 📸",
            created_at=_ago(hours=20),
        ),
    ]
    # Dev user: messages for chats WITHOUT deals (Messages segment)
    dev_plain_msgs = [
        Message(
            id="msg-plain-1", chat_id="chat-dev-msg-1", sender_id="blogger-1",
            text="Hey! Saw your profile, love the travel content. Would be great to connect!",
            created_at=_ago(hours=4),
        ),
        Message(
            id="msg-plain-2", chat_id="chat-dev-msg-1", sender_id="dev-user-1",
            text="Thanks Sarah! Your Bali content is amazing. What spots do you recommend?",
            created_at=_ago(hours=3, minutes=30),
        ),
        Message(
            id="msg-plain-3", chat_id="chat-dev-msg-1", sender_id="blogger-1",
            text="Definitely check out Uluwatu temple at sunset and Tegallalang rice terraces! 🌴",
            created_at=_ago(minutes=15),
        ),
        Message(
            id="msg-plain-4", chat_id="chat-dev-msg-2", sender_id="blogger-3",
            text="Hi! I'm Kevin, wellness content creator. Your fitness approach is cool 💪",
            created_at=_ago(hours=8),
        ),
        Message(
            id="msg-plain-5", chat_id="chat-dev-msg-2", sender_id="dev-user-1",
            text="Hey Kevin! Thanks, been exploring yoga studios in Canggu. Any recommendations?",
            created_at=_ago(hours=7),
        ),
        Message(
            id="msg-plain-6", chat_id="chat-dev-msg-2", sender_id="blogger-3",
            text="The Yoga Barn in Ubud is incredible. Also Desa Seni in Canggu for more chill vibes",
            created_at=_ago(hours=1),
        ),
    ]
    for m in msgs + dev_msgs + ded_msgs + dev_deal_msgs + dev_plain_msgs:
        store.messages[m.id] = m

    # ------------------------------------------------------------------
    # Deals (including one for dev user)
    # ------------------------------------------------------------------
    deal1 = Deal(
        id="deal-1",
        chat_id=chat1_id,
        participant_ids=("blogger-1", "business-1"),
        initiator_id="business-1",
        type=OfferType.BARTER,
        offered_text="Sunset dinner for 2 + cocktails at The Lawn Canggu",
        requested_text="1 Instagram Reel + 3 Stories mentioning @thelawncanggu",
        place_name="The Lawn Canggu, Batu Bolong",
        guests="duo",
        scheduled_for=_now() + timedelta(days=3),
        content_deadline=_now() + timedelta(days=10),
        status=DealStatus.DRAFT,
        created_at=_ago(hours=2),
        updated_at=_ago(hours=2),
    )
    deal2 = Deal(
        id="deal-2",
        chat_id=chat2_id,
        participant_ids=("blogger-4", "business-2"),
        initiator_id="business-2",
        type=OfferType.BARTER,
        offered_text="Dinner for 2 + signature margaritas at Motel Mexicola",
        requested_text="1 Reel + 2 Stories + 1 feed post",
        place_name="Motel Mexicola Seminyak",
        guests="duo",
        scheduled_for=_ago(days=2),
        status=DealStatus.VISITED,
        checked_in_user_ids={"blogger-4", "business-2"},
        created_at=_ago(days=10),
        updated_at=_ago(days=2),
    )
    deal3 = Deal(
        id="deal-3",
        chat_id=chat2_id,
        participant_ids=("blogger-4", "business-2"),
        initiator_id="blogger-4",
        type=OfferType.BARTER,
        offered_text="Instagram takeover for a weekend",
        requested_text="2 dinners + VIP table for event night",
        place_name="Motel Mexicola Seminyak",
        guests="duo",
        scheduled_for=_ago(days=20),
        status=DealStatus.REVIEWED,
        checked_in_user_ids={"blogger-4", "business-2"},
        reviews=[
            DealReview(
                reviewer_id="blogger-4",
                reviewee_id="business-2",
                punctuality=5,
                offer_match=5,
                communication=4,
                comment="Amazing place and great communication!",
                created_at=_ago(days=18),
            ),
            DealReview(
                reviewer_id="business-2",
                reviewee_id="blogger-4",
                punctuality=5,
                offer_match=5,
                communication=5,
                comment="Aria is a true professional. Content was stunning.",
                created_at=_ago(days=17),
            ),
        ],
        content_proofs=[
            ContentProof(
                submitter_id="blogger-4",
                post_url="https://www.instagram.com/p/example123",
                screenshot_url="https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400",
                submitted_at=_ago(days=17),
            )
        ],
        created_at=_ago(days=22),
        updated_at=_ago(days=17),
    )
    # ---- Dev user deals (different stages for demo) ----

    # Draft — waiting for partner to accept
    deal_dev_draft = Deal(
        id="deal-dev-draft",
        chat_id="chat-dev-2",
        participant_ids=tuple(sorted(("dev-user-1", "business-2"))),
        initiator_id="dev-user-1",
        type=OfferType.BARTER,
        offered_text="1 Reel + 3 Stories at the party night",
        requested_text="Dinner for 2 + VIP table + drinks",
        place_name="Motel Mexicola, Seminyak",
        guests="duo",
        scheduled_for=_now() + timedelta(days=2),
        content_deadline=_now() + timedelta(days=9),
        status=DealStatus.DRAFT,
        created_at=_ago(hours=3),
        updated_at=_ago(hours=3),
    )

    # Confirmed — both agreed, visit upcoming
    deal_dev_confirmed = Deal(
        id="deal-dev-confirmed",
        chat_id="chat-dev-3",
        participant_ids=tuple(sorted(("dev-user-1", "business-3"))),
        initiator_id="business-3",
        type=OfferType.BARTER,
        offered_text="2-night stay in a Garden Suite",
        requested_text="2 Reels + 3 Stories + 1 feed post",
        place_name="COMO Uma Canggu",
        guests="solo",
        scheduled_for=_now() + timedelta(days=1),
        content_deadline=_now() + timedelta(days=8),
        status=DealStatus.CONFIRMED,
        created_at=_ago(hours=6),
        updated_at=_ago(hours=2),
    )

    # Visited — collab happened, waiting for review
    deal_dev_visited = Deal(
        id="deal-dev-visited",
        chat_id="chat-dev-1",
        participant_ids=tuple(sorted(("dev-user-1", "business-1"))),
        initiator_id="business-1",
        type=OfferType.BARTER,
        offered_text="Sunset dinner for 2 + cocktails",
        requested_text="1 Reel + 3 Stories mentioning @thelawncanggu",
        place_name="The Lawn Canggu",
        guests="solo",
        scheduled_for=_ago(days=1),
        content_deadline=_now() + timedelta(days=5),
        status=DealStatus.VISITED,
        checked_in_user_ids={"dev-user-1", "business-1"},
        created_at=_ago(days=3),
        updated_at=_ago(days=1),
    )

    # ---- Ded user deals ----

    # Confirmed deal
    deal_ded_confirmed = Deal(
        id="deal-ded-confirmed",
        chat_id="chat-ded-1",
        participant_ids=tuple(sorted(("ded-user-1", "business-1"))),
        initiator_id="business-1",
        type=OfferType.PAID,
        offered_text="$250 for content package",
        requested_text="2 Reels + 5 Stories over the weekend",
        place_name="The Lawn Canggu, Batu Bolong",
        guests="solo",
        scheduled_for=_now() + timedelta(days=3),
        status=DealStatus.CONFIRMED,
        created_at=_ago(hours=2),
        updated_at=_ago(hours=1),
    )

    # Draft deal
    deal_ded_draft = Deal(
        id="deal-ded-draft",
        chat_id="chat-ded-2",
        participant_ids=tuple(sorted(("ded-user-1", "business-2"))),
        initiator_id="ded-user-1",
        type=OfferType.BARTER,
        offered_text="1 Reel reviewing the brunch experience",
        requested_text="Brunch for 2 + welcome cocktails",
        place_name="Motel Mexicola",
        guests="duo",
        scheduled_for=_now() + timedelta(days=5),
        status=DealStatus.DRAFT,
        created_at=_ago(hours=6),
        updated_at=_ago(hours=6),
    )

    for d in [deal1, deal2, deal3, deal_dev_draft, deal_dev_confirmed, deal_dev_visited, deal_ded_confirmed, deal_ded_draft]:
        store.deals[d.id] = d

    # ------------------------------------------------------------------
    # Incoming likes (other users liked dev-user → appear in Likes tab)
    # ------------------------------------------------------------------
    from app.modules.matches.domain.models import Swipe, SwipeDirection
    incoming_likes = [
        Swipe(id="like-to-dev-1", actor_id="blogger-1", target_id="dev-user-1",
              direction=SwipeDirection.RIGHT, delivered=True, created_at=_ago(hours=2)),
        Swipe(id="like-to-dev-2", actor_id="blogger-3", target_id="dev-user-1",
              direction=SwipeDirection.RIGHT, delivered=True, created_at=_ago(hours=5)),
        Swipe(id="like-to-dev-3", actor_id="blogger-4", target_id="dev-user-1",
              direction=SwipeDirection.SUPER, delivered=True, created_at=_ago(hours=8)),
        Swipe(id="like-to-dev-4", actor_id="blogger-5", target_id="dev-user-1",
              direction=SwipeDirection.RIGHT, delivered=True, created_at=_ago(days=1)),
        Swipe(id="like-to-dev-5", actor_id="business-4", target_id="dev-user-1",
              direction=SwipeDirection.RIGHT, delivered=True, created_at=_ago(hours=1)),
    ]
    for s in incoming_likes:
        store.swipes[s.id] = s

    # ------------------------------------------------------------------
    # Offers
    # ------------------------------------------------------------------
    offer1 = Offer(
        id="offer-1",
        business_id="business-1",
        title="Sunset Dinner Collab @ The Lawn Canggu",
        type=OfferType.BARTER,
        blogger_receives="Dinner for 2 + sunset cocktails on the beachfront",
        business_receives="1 Reel + 3 Stories tagged @thelawncanggu",
        slots_total=3,
        slots_remaining=2,
        photo_url="https://images.unsplash.com/photo-1540541338287-41700207dee6?w=600",
        preferred_blogger_niche="food",
        min_audience="10K",
        guests="duo",
        special_conditions="Must post within 5 days of visit",
        is_last_minute=False,
        status=OfferStatus.ACTIVE,
        created_at=_ago(days=3),
        updated_at=_ago(days=3),
    )
    offer2 = Offer(
        id="offer-2",
        business_id="business-3",
        title="Luxury Surf Stay @ COMO Uma Canggu",
        type=OfferType.BARTER,
        blogger_receives="2-night villa stay + spa treatment",
        business_receives="1 YouTube video or 2 Reels + 5 Stories",
        slots_total=2,
        slots_remaining=2,
        photo_url="https://images.unsplash.com/photo-1582719508461-905c673771fd?w=600",
        preferred_blogger_niche="travel",
        min_audience="20K",
        guests="solo",
        special_conditions="Stay must be booked for weekdays",
        is_last_minute=False,
        status=OfferStatus.ACTIVE,
        created_at=_ago(days=7),
        updated_at=_ago(days=7),
    )
    offer3 = Offer(
        id="offer-3",
        business_id="business-4",
        title="[LAST MINUTE] Sunset Session at Potato Head",
        type=OfferType.BARTER,
        blogger_receives="VIP day pass + lunch for 2 + cocktails",
        business_receives="Live Stories during visit + 1 Reel next day",
        slots_total=1,
        slots_remaining=1,
        photo_url="https://images.unsplash.com/photo-1559339352-11d035aa65de?w=600",
        preferred_blogger_niche="lifestyle",
        min_audience="5K",
        guests="duo",
        is_last_minute=True,
        status=OfferStatus.ACTIVE,
        expires_at=_now() + timedelta(days=1),
        created_at=_ago(hours=3),
        updated_at=_ago(hours=3),
    )
    offer4 = Offer(
        id="offer-4",
        business_id="business-1",
        title="[LAST MINUTE] Beachfront Brunch @ The Lawn",
        type=OfferType.BARTER,
        blogger_receives="Brunch for 2 + bottomless mimosas",
        business_receives="2 Stories + 1 Reel",
        slots_total=2,
        slots_remaining=2,
        photo_url="https://images.unsplash.com/photo-1540541338287-41700207dee6?w=600",
        preferred_blogger_niche="food",
        min_audience="5K",
        guests="duo",
        is_last_minute=True,
        status=OfferStatus.ACTIVE,
        expires_at=_now() + timedelta(hours=6),
        created_at=_ago(hours=1),
        updated_at=_ago(hours=1),
    )
    offer5 = Offer(
        id="offer-5",
        business_id="business-5",
        title="[LAST MINUTE] Coffee Tasting @ Zin",
        type=OfferType.BARTER,
        blogger_receives="Full coffee tasting menu + pastries",
        business_receives="3 Stories tagged @zincafe",
        slots_total=3,
        slots_remaining=3,
        photo_url="https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=600",
        preferred_blogger_niche="food",
        min_audience="1K",
        guests="solo",
        is_last_minute=True,
        status=OfferStatus.ACTIVE,
        expires_at=_now() + timedelta(hours=12),
        created_at=_ago(hours=2),
        updated_at=_ago(hours=2),
    )
    # Extended offers: cover all niches + both paid/barter types
    offer6 = Offer(
        id="offer-6",
        business_id="business-5",
        title="Morning Yoga & Smoothie Bowl",
        type=OfferType.BARTER,
        blogger_receives="Yoga class + signature smoothie bowl",
        business_receives="1 Reel + 2 Stories tagged @zincafebali",
        slots_total=5,
        slots_remaining=5,
        photo_url="https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=600",
        preferred_blogger_niche="fitness",
        min_audience="3K",
        guests="solo",
        is_last_minute=False,
        status=OfferStatus.ACTIVE,
        created_at=_ago(days=2),
        updated_at=_ago(days=2),
    )
    offer7 = Offer(
        id="offer-7",
        business_id="business-2",
        title="Fashion Shoot @ Motel Mexicola Rooftop",
        type=OfferType.PAID,
        blogger_receives="$300 + dinner + cocktails for 2",
        business_receives="3 Reels + 5 Stories + usage rights",
        slots_total=2,
        slots_remaining=2,
        photo_url="https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600",
        preferred_blogger_niche="fashion",
        min_audience="30K",
        guests="duo",
        is_last_minute=False,
        status=OfferStatus.ACTIVE,
        created_at=_ago(days=1),
        updated_at=_ago(days=1),
    )
    offer8 = Offer(
        id="offer-8",
        business_id="business-3",
        title="Spa Day Content — COMO Shambhala",
        type=OfferType.BARTER,
        blogger_receives="Full spa day (massage + facial) + lunch",
        business_receives="1 Reel + 4 Stories + blog post",
        slots_total=3,
        slots_remaining=2,
        photo_url="https://images.unsplash.com/photo-1540555700478-4be289fbec6d?w=600",
        preferred_blogger_niche="beauty",
        min_audience="15K",
        guests="solo",
        is_last_minute=False,
        status=OfferStatus.ACTIVE,
        created_at=_ago(days=4),
        updated_at=_ago(days=4),
    )
    offer9 = Offer(
        id="offer-9",
        business_id="business-4",
        title="Potato Head Music Festival — Influencer Pass",
        type=OfferType.BARTER,
        blogger_receives="VIP 2-day festival pass + welcome drinks",
        business_receives="5+ Reels covering the event + live stories",
        slots_total=5,
        slots_remaining=4,
        photo_url="https://images.unsplash.com/photo-1533777857889-4be7c70b33f7?w=600",
        preferred_blogger_niche="music",
        min_audience="25K",
        guests="duo",
        is_last_minute=False,
        status=OfferStatus.ACTIVE,
        created_at=_ago(days=2),
        updated_at=_ago(days=2),
    )
    offer10 = Offer(
        id="offer-10",
        business_id="business-4",
        title="Wellness Weekend Takeover",
        type=OfferType.PAID,
        blogger_receives="$500 + 2-night retreat + meals",
        business_receives="2 Reels + daily stories + final post",
        slots_total=2,
        slots_remaining=2,
        photo_url="https://images.unsplash.com/photo-1545389336-cf090694435e?w=600",
        preferred_blogger_niche="health",
        min_audience="20K",
        guests="solo",
        is_last_minute=False,
        status=OfferStatus.ACTIVE,
        created_at=_ago(days=5),
        updated_at=_ago(days=5),
    )
    offer11 = Offer(
        id="offer-11",
        business_id="business-1",
        title="Beach Volleyball Tournament Coverage",
        type=OfferType.PAID,
        blogger_receives="$200 + day pass + food & drinks",
        business_receives="1 highlight Reel + 10 stories",
        slots_total=3,
        slots_remaining=3,
        photo_url="https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=600",
        preferred_blogger_niche="sports",
        min_audience="10K",
        guests="solo",
        is_last_minute=False,
        status=OfferStatus.ACTIVE,
        created_at=_ago(days=6),
        updated_at=_ago(days=6),
    )
    offer12 = Offer(
        id="offer-12",
        business_id="business-2",
        title="Cocktail Masterclass Content",
        type=OfferType.BARTER,
        blogger_receives="2-hour cocktail class + full dinner for 2",
        business_receives="1 tutorial Reel + 3 stories",
        slots_total=4,
        slots_remaining=4,
        photo_url="https://images.unsplash.com/photo-1551024506-0bccd828d307?w=600",
        preferred_blogger_niche="cooking",
        min_audience="5K",
        guests="duo",
        is_last_minute=False,
        status=OfferStatus.ACTIVE,
        created_at=_ago(days=3),
        updated_at=_ago(days=3),
    )
    offer13 = Offer(
        id="offer-13",
        business_id="business-3",
        title="Photography Workshop @ COMO Beach",
        type=OfferType.PAID,
        blogger_receives="$250 + workshop entry + lunch",
        business_receives="Photo series + 1 blog post + tagged carousel",
        slots_total=3,
        slots_remaining=3,
        photo_url="https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=600",
        preferred_blogger_niche="photography",
        min_audience="15K",
        guests="solo",
        is_last_minute=False,
        status=OfferStatus.ACTIVE,
        created_at=_ago(days=4),
        updated_at=_ago(days=4),
    )
    offer14 = Offer(
        id="offer-14",
        business_id="business-4",
        title="Co-working Space Launch Content",
        type=OfferType.PAID,
        blogger_receives="$400 + 1-month membership + snacks",
        business_receives="1 Reel + Instagram post + Google review",
        slots_total=2,
        slots_remaining=2,
        photo_url="https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600",
        preferred_blogger_niche="business",
        min_audience="20K",
        guests="solo",
        is_last_minute=False,
        status=OfferStatus.ACTIVE,
        created_at=_ago(days=1),
        updated_at=_ago(days=1),
    )
    offer15 = Offer(
        id="offer-15",
        business_id="business-5",
        title="Local Art Exhibition Feature",
        type=OfferType.BARTER,
        blogger_receives="Private tour + brunch + artist meet",
        business_receives="3 Stories + 1 carousel highlighting artists",
        slots_total=4,
        slots_remaining=4,
        photo_url="https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600",
        preferred_blogger_niche="art",
        min_audience="5K",
        guests="solo",
        is_last_minute=False,
        status=OfferStatus.ACTIVE,
        created_at=_ago(days=3),
        updated_at=_ago(days=3),
    )

    all_offers = [
        offer1, offer2, offer3, offer4, offer5,
        offer6, offer7, offer8, offer9, offer10,
        offer11, offer12, offer13, offer14, offer15,
    ]
    # Rolling expires_at: last-minute офферы → 12-36h вперёд (countdown running),
    # обычные → 3-14 дней вперёд. Вычисляется на момент seed чтобы таймеры
    # на клиенте всегда показывали актуальное время.
    _last_minute_hours = [14, 20, 28, 36]
    _regular_days = [3, 5, 7, 10, 14]
    lm_idx = 0
    reg_idx = 0
    for o in all_offers:
        if o.is_last_minute:
            hours = _last_minute_hours[lm_idx % len(_last_minute_hours)]
            o.expires_at = _now() + timedelta(hours=hours)
            lm_idx += 1
        else:
            days = _regular_days[reg_idx % len(_regular_days)]
            o.expires_at = _now() + timedelta(days=days)
            reg_idx += 1
        store.offers[o.id] = o

    # Offer response — blogger-5 (Marco Surf) responded to the COMO stay offer
    resp1 = OfferResponse(
        id="offer-resp-1",
        offer_id="offer-2",
        business_id="business-3",
        blogger_id="blogger-5",
        status=OfferResponseStatus.PENDING,
        message="This would be perfect for my surf content series! I'd love to feature COMO Uma.",
        created_at=_ago(days=1),
        updated_at=_ago(days=1),
    )
    store.offer_responses[resp1.id] = resp1


def build_container(settings: Settings) -> AppContainer:
    import logging
    _log = logging.getLogger(__name__)

    if settings.use_db_repos:
        # -----------------------------------------------------------------
        # PostgreSQL-backed repositories (sync, psycopg2 driver)
        # -----------------------------------------------------------------
        from app.database.session import get_sync_session_factory

        sf = get_sync_session_factory()
        _log.info("Building container with PostgreSQL DB repositories (sync)")

        auth_repo = SyncDBAuthRepository(sf)
        profile_repo = SyncDBProfileRepository(sf)
        match_repo = SyncDBMatchRepository(sf)
        offer_repo = SyncDBOfferRepository(sf)
        chat_repo = SyncDBChatRepository(sf)
        deal_repo = SyncDBDealRepository(sf)

    else:
        # -----------------------------------------------------------------
        # InMemory repositories (default, backward-compatible)
        # -----------------------------------------------------------------
        # Try loading persisted store first (preserves user data across restarts)
        store = InMemoryStore.load_from_disk()
        if store is not None:
            _log.info("Loaded persisted store from %s (users=%d, deals=%d, swipes=%d)",
                      STORE_PERSIST_PATH, len(store.users), len(store.deals), len(store.swipes))
        else:
            # No persisted store — create fresh with seed data
            store = InMemoryStore()
            _seed_store(store)
            store.persist()
            _log.info("Seeded fresh store and persisted to %s", STORE_PERSIST_PATH)

        auth_repo = InMemoryAuthRepository(store)
        profile_repo = InMemoryProfileRepository(store)
        match_repo = InMemoryMatchRepository(store)
        offer_repo = InMemoryOfferRepository(store)
        chat_repo = InMemoryChatRepository(store)
        deal_repo = InMemoryDealRepository(store)

    # -----------------------------------------------------------------
    # Services (same wiring regardless of repository backend)
    # -----------------------------------------------------------------
    auth_service = AuthService(auth_repo=auth_repo, profile_repo=profile_repo)
    profile_service = ProfileService(profile_repo=profile_repo, auth_repo=auth_repo)
    chat_service = ChatService(
        chat_repo=chat_repo,
        auth_repo=auth_repo,
        match_repo=match_repo,
        deal_repo=deal_repo,
    )
    match_service = MatchService(
        match_repo=match_repo,
        auth_repo=auth_repo,
        chat_service=chat_service,
    )
    offer_service = OfferService(
        offer_repo=offer_repo,
        auth_repo=auth_repo,
        match_service=match_service,
        chat_service=chat_service,
        timezone_name=settings.business_timezone,
    )
    deal_service = DealService(
        deal_repo=deal_repo,
        auth_repo=auth_repo,
        chat_service=chat_service,
        profile_repo=profile_repo,
    )

    return AppContainer(
        settings=settings,
        auth_service=auth_service,
        profile_service=profile_service,
        match_service=match_service,
        offer_service=offer_service,
        chat_service=chat_service,
        deal_service=deal_service,
    )
