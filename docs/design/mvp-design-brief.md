# MATCHA MVP Design Brief

## Purpose
Practical design brief for the SwiftUI MVP of MATCHA, based on the product spec v3.3. The goal is to ship a fast, premium-feeling iOS-first experience for Bali networking with dark mode only, accent green `#B8FF43`, and glassmorphism overlays.

## 1) Information Architecture / Screen List

### Primary navigation
- `Match` — main swipe feed, centered tab
- `Offers` — marketplace of business offers
- `Activity` — likes, deals, responses
- `Chats` — conversations and deal entry points
- `Profile` — user profile, verification, settings

### Required flows
- Onboarding: welcome, auth + role, mini profile, shadow-account feed, profile completion, verification, activation
- Discovery: swipe feed, filters, expanded profile, likes/paywall states
- Offers: browse, filter, respond, create offer for business
- Activity: likes, deals, responses, finished/cancelled/no-show
- Chat: match list, conversation, propose deal, unmatch/mute, block/report
- Profile: edit profile, media upload, portfolio wall, badges, settings, privacy
- System moments: empty states, offline, return after inactivity, notification permission

## 2) Visual System / Tokens

### Design direction
- Dark-first interface with high-contrast type and luminous accent color.
- Glassmorphism is used only for overlays above imagery and for sheets/modals.
- Visual language should feel premium, modern, and slightly playful, with the matcha metaphor present in microcopy and motion.

### Color tokens

| Token | Value | Usage |
|---|---:|---|
| `color.bg.base` | `#000000` | App background |
| `color.bg.surface` | `#0B0B0B` | Cards, sheets, elevated panels |
| `color.bg.surface2` | `#121212` | Secondary surfaces |
| `color.fg.primary` | `#FFFFFF` | Main text |
| `color.fg.secondary` | `rgba(255,255,255,0.72)` | Supporting text |
| `color.fg.muted` | `rgba(255,255,255,0.48)` | Tertiary labels |
| `color.accent` | `#B8FF43` | Primary action, active states, verified, badges |
| `color.accent.on` | `#000000` | Text/icon on accent surfaces |
| `color.success` | `#B8FF43` | Positive confirmations, interested, verified |
| `color.warning` | `#FFB84D` | Limit warnings, low-result counters |
| `color.danger` | `#FF4D4D` | Unmatch, report, destructive actions |
| `color.neutral.line` | `rgba(255,255,255,0.10)` | Hairlines and dividers |
| `color.glass.tint` | `rgba(255,255,255,0.08)` | Glass overlay fill |
| `color.glass.stroke` | `rgba(255,255,255,0.16)` | Glass border |

### Surface and blur rules
- Use frosted glass only where content sits over photos or dark imagery.
- Keep glass panels shallow and readable; do not stack multiple translucent layers.
- On sheets, use a darker surface with a thin glass stroke instead of heavy blur everywhere.

### Typography
- Use a clean SF-based hierarchy for MVP, tuned for strong contrast.
- Keep headings short and bold.
- Use larger numerals and chips for trust signals like verified audience, ratings, and counts.
- Avoid dense paragraph blocks; prefer short labels, chips, and stacked microcopy.

### Spacing and shape
- Base spacing scale: `4, 8, 12, 16, 20, 24, 32`.
- Prefer rounded rectangles and pill chips.
- Cards should feel continuous, with minimal dead space between content, actions, and tab bar.
- Bottom action buttons sit directly above the tab bar with a small gap.

### Core component tokens
- `tabBar.height = 66`
- `matchTab.iconSize = 26`
- `otherTab.iconSize = 20`
- `primaryAction.size = 44`
- `primaryAction.largeSize = 62`
- `primaryAction.gap = 32`
- `contentToActionsGap = 6`
- `glassRadius = 20`
- `cardRadius = 24`

### Semantic state rules
- `Interested` = accent green glow, positive stamp, light haptic
- `Skip` = muted gray fade, no celebratory motion
- `Match` = stronger reveal animation, slightly longer pause
- `SuperSwipe` = gold-highlighted special state, strongest emphasis
- `New` badge = temporary, accent chip, not a reputation badge

## 3) Screen-by-Screen UX Notes

### Onboarding
**Goal:** get users into the feed fast while collecting only the minimum needed for utility.

- Screen 1: full-screen welcome with logo, tagline, and one clear CTA.
- Screen 2: auth plus role selection, with compact role toggle rather than large cards.
- Screen 3: mini profile, name + 1 photo minimum, category for business.
- After sign-up, route directly into shadow feed instead of a long setup funnel.
- Keep pre-verification friction low, but make queued likes feel visible and understandable.
- Use microcopy that explains why verification matters without sounding punitive.

**UX notes**
- The shadow-account state should let users browse immediately.
- Likes are saved locally and clearly marked as pending delivery.
- The “complete profile” prompt should appear as a soft nudge, not a hard lock until the 20-like cap is reached.
- The verification wizard should feel like a checklist with visible progress.

### Swipe / Match
**Goal:** make discovery feel fast, tactile, and premium.

- Card structure is vertical and continuous: alternating photos and info blocks.
- The swipe feed should support both horizontal intent and vertical reading without gesture conflict.
- Photo tap opens fullscreen lightbox with pinch-to-zoom and swipe-down-to-close.
- Action buttons are always visible near the bottom and strongly hierarchical around SuperSwipe.
- Keep the top bar minimal: logo left, filters right.

**UX notes**
- Horizontal swipe should win only when the gesture is clearly intentional.
- Long content should flow naturally; do not use empty placeholder blocks.
- Keep the “Undo” backtrack visible briefly after left swipe only.
- Use filters as a bottom sheet with a live count and clear reset action.

### Offers
**Goal:** feel like a compact marketplace, not a second swipe feed.

- Separate the offer marketplace from the main discovery mechanic.
- Use a Netflix-style browse layout with offer cards and a lightweight filter panel.
- Surface response limits clearly for bloggers.
- Make business offer creation structured and constrained, with obvious required fields.

**UX notes**
- “Last Minute” offers need special visibility for Black users.
- If a business already has a match, accepting an offer should open the existing chat and prefill the deal card.
- If not matched, acceptance should auto-match and still keep the flow compact.
- Response deadlines must be visible enough that the user understands why an action disappears.

### Activity
**Goal:** centralize social proof and collaboration status.

- Use three sub-tabs: Likes, Deals, Responses.
- Likes are fully open for bloggers, paywalled for business on Free tier.
- Deals should be grouped by status with a readable progression.
- Responses should be framed differently for each role but live in the same tab.

**UX notes**
- The user should always be able to answer: “What needs my attention now?”
- Progress in active deals should be visible at a glance.
- Finished deals should reveal review and content proof history, plus repeat-collab entry point for Black users.

### Chats
**Goal:** keep conversations focused on collaboration, with deal creation available at the right moment.

- Show a match strip at the top, then the conversation list below.
- Include a clear proposal path for deals from the chat top bar.
- Keep read receipts and translation as optional, controllable features.
- Use swipe actions for mute and unmatch, with deal-protection safeguards.

**UX notes**
- Proposed deals should not feel hidden behind a menu.
- Unmatch must be blocked or warned when a deal is active or in a protected stage.
- Block and report should stay in the chat menu, not in swipe actions.

### Profile
**Goal:** let users present themselves credibly and edit quickly.

- Profile editing should be broken into understandable blocks: identity, media, niche/category, verification bridge, and settings.
- Media upload needs clear slot rules, reordering, and crop behavior.
- Verified audience and badges should read as trust signals, not vanity stats.
- Expanded profile should show richer details, while the swipe card stays concise.

**UX notes**
- Keep Instagram/TikTok as text-only handles inside the app, not clickable outbound links.
- Portfolio wall and UGC gallery should feel like proof, not decoration.
- Business profiles need a distinct but parallel structure to blogger profiles.
- The “Idea Box” can live inside profile/settings as a lightweight contribution area.

## 4) Motion / Haptics Notes

### Motion principles
- Motion should reinforce state changes, not decorate every interaction.
- Keep most transitions short and crisp; reserve longer motion for match events and key milestones.
- Favor directional motion that matches the action: right for interested, left for skip, center burst for match.

### Recommended motion moments
- Interested: small glow + quick stamp.
- Skip: fast fade and slide out.
- Match: leaf convergence into a brief matcha burst.
- SuperSwipe: stronger accent flash and a premium “Double Shot” feel.
- Splash: slow leaf convergence into the MATCHA logo.

### Haptics
- Interested: light impact.
- Match: stronger confirmation haptic.
- SuperSwipe: highest-intensity success haptic in the set.
- Error/limit states: subtle warning haptic, not a harsh buzz.

### Performance caveat
- Keep animations GPU-friendly and lightweight.
- Provide simplified fallbacks on older devices or when motion performance drops.

## 5) Accessibility Caveats

- Maintain strong contrast between white text and dark surfaces, especially over glass panels.
- Do not encode meaning by color alone; pair accent green with text, icons, or labels.
- Make all tap targets large enough for thumb reach, especially bottom actions and tab bar items.
- Respect Dynamic Type where possible, but cap extreme sizes on dense cards to avoid collapse.
- Ensure blur and translucency never reduce readability below usable levels.
- Support Reduce Motion with simplified transitions and no loss of state clarity.
- Keep gesture alternatives available for swipe-only interactions.
- Avoid tiny labels for trust, verification, and count indicators.
- Make limit states and blocked actions readable in plain language.

## 6) Implementation Priorities for SwiftUI MVP

- Build the navigation shell first: tab bar, top bar, shared dark theme, shared glass tokens.
- Next implement Match feed, because it drives core value and informs most other surfaces.
- Then ship Offers and Activity, since those are the main secondary workflows.
- Chat and Profile can reuse shared components from feed cards, chips, sheets, and buttons.
- Keep token values centralized so future v2 expansions do not require visual rewrites.

## 7) Source File
- Product spec: `/Users/dorffoto/Downloads/Telegram Desktop/MATCHA_Product_Spec_v3.3.md`

## 8) External Inspiration Pass

### Behance direction to borrow
- The Behance reference points to a calm, immersive dark-first presentation with full-screen emotional composition rather than a dense utility layout.
- The strongest transferable qualities for MATCHA are restrained premium contrast, clean editorial spacing, and a feeling that each screen is focused on one human moment.
- For MATCHA, this should be adapted away from generic dating aesthetics and toward creator-business trust signals: verified audience, collab type, district, and proof surfaces should feel native to the layout.
- Glass should be present but disciplined. The inspiration is useful for softness and finish, not for stacking many translucent layers.

### Lottie direction to borrow
- Treat Lottie as motion inspiration for short ceremonial moments, not as a source of constant decorative movement.
- Best fit moments are splash logo convergence, match confirmation, super-swipe emphasis, queued-like activation, and small verification-success transitions.
- Motion should stay light and symbolic: leaves, powder bursts, steam, or cup-like arcs are a better fit than generic particle fireworks.
- All animation work should support a reduced-motion fallback with the same state clarity.

### Translation into MATCHA art direction
- The app should feel more premium hospitality-network than playful dating clone.
- Keep backgrounds atmospheric with deep green-black gradients rather than flat black.
- Use `#B8FF43` as a controlled light source, not a fill color for large surfaces.
- Let photos, profile proof, and status chips carry trust. Let motion and glass carry mood.
