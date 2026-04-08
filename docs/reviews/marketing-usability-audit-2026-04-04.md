# Marketing & UX Review — 2026-04-04

## Overall Launch Readiness: 6.5/10

**Comparison vs 2026-04-02:** effectively unchanged. I rechecked the same iOS surfaces after the current round of work, and the relevant onboarding, feed, offers, activity, chats, and profile experiences still communicate the product structure well, but they do not yet close the last mile on profile usability, deals clarity, or Bali-first story clarity. The app is still visually premium and logically coherent, but launch conversion remains copy- and CTA-limited.

---

## Screen Scores

| Screen | Score | Current Readout |
|--------|-------|-----------------|
| **Onboarding** | 3.5/5 | Fast and lightweight, but still too generic to create urgency or role-specific payoff |
| **Match Feed** | 4/5 | Strong visual shell, but not yet a persuasive “why now / why Bali / why verify” surface |
| **Offers** | 3/5 | Clean marketplace layout, but still layout-led instead of outcome-led |
| **Activity** | 3.5/5 | Better as proof than before, but still reads like a list instead of a momentum dashboard |
| **Chats** | 3/5 | New matches and conversations are visible, but deal progression is not yet obvious |
| **Profile** | 3/5 | The weakest activation surface: verification and profile completion are present, but not yet compelling |

---

## Comparison to Previous Audit

### What stayed the same

- The core five-tab structure is still in place and still maps to the product spec.
- Shadow-mode mechanics are still conceptually correct.
- Dark premium visual language still supports the brand direction.
- Bali context is still mostly carried by seed data and underlying model values, not by user-facing copy.

### What matters most now

- The previous audit flagged missing Bali-first value prop, weak onboarding payoff, feed conversion gaps, and missing next-action CTAs. Those same issues remain the highest-risk blockers.
- This round I would elevate **profile usability** and **chats/deals clarity** slightly above the rest, because they are the clearest missing links between interest and actual conversion.

---

## Findings

### 1. Bali-first value prop is still too implicit

Where: [OnboardingFlowView.swift](file:///Users/dorffoto/Documents/New%20project/matcha/ios/MATCHA/Features/Onboarding/OnboardingFlowView.swift#L17), [MatchFeedView.swift](file:///Users/dorffoto/Documents/New%20project/matcha/ios/MATCHA/Features/MatchFeed/MatchFeedView.swift#L22), [OffersView.swift](file:///Users/dorffoto/Documents/New%20project/matcha/ios/MATCHA/Features/Offers/OffersView.swift#L35)

The app still depends on the user inferring “Bali-first creator/business network” from the data model and examples. That is not enough for launch. The welcome step says “Brew connections. Blend success.”, the feed says “MATCHA”, and offers says “Marketplace”. None of those are wrong, but none of them say the thing the launch actually needs to say.

Why it still blocks launch:
- A first-time user can still mistake the product for a generic networking app.
- The marketing story in the GTM is stronger than the app copy.
- The local advantage is underplayed right where conversion decisions happen.

What should change:
- Add one explicit Bali-first line in onboarding.
- Add one persistent local proof cue in feed and offers.
- Use “verified” language at least once on the first two screens a user sees after onboarding.

### 2. Onboarding is efficient, but not yet persuasive enough

Where: [OnboardingFlowView.swift](file:///Users/dorffoto/Documents/New%20project/matcha/ios/MATCHA/Features/Onboarding/OnboardingFlowView.swift#L69), [OnboardingFlowView.swift](file:///Users/dorffoto/Documents/New%20project/matcha/ios/MATCHA/Features/Onboarding/OnboardingFlowView.swift#L87), [OnboardingFlowView.swift](file:///Users/dorffoto/Documents/New%20project/matcha/ios/MATCHA/Features/Onboarding/OnboardingFlowView.swift#L121)

The flow is short, which is good. The problem is that the payoff is still described in broad terms rather than in user terms. “Shadow mode” and “queued likes” are product concepts, but they do not yet feel like benefits. The role step also does not make the creator/business split feel materially different.

What this means in practice:
- Creators do not see “why finish now.”
- Businesses do not see “what I unlock after verification.”
- The last onboarding step feels like a form, not a launchpad.

What to add:
- Creator payoff line: free discovery, verified Bali businesses, first match access.
- Business payoff line: verified creators, campaign discovery, 7-day Pro trial clarity.
- A clearer completion moment that frames verification as a milestone.

### 3. Profile usability is still too shallow for an activation hub

Where: [ProfileView.swift](file:///Users/dorffoto/Documents/New%20project/matcha/ios/MATCHA/Features/Profile/ProfileView.swift#L16), [ProfileView.swift](file:///Users/dorffoto/Documents/New%20project/matcha/ios/MATCHA/Features/Profile/ProfileView.swift#L52)

Profile is currently readable, but it does not yet behave like the place where a user understands their status, their missing steps, and their next unlocks. The hero card shows identity, verification state, and some stats, but the verification checklist is still generic and the settings block is doing too much of the visual real estate.

Why this matters:
- Profile should be the place that finishes the activation story.
- Right now it is more “account overview” than “progress toward trust and distribution.”
- The user does not get a strong enough answer to “what should I complete next?”

Recommendation:
- Replace placeholder-style verification items with explicit unlock language.
- Add a visible progress bar or checklist completion state.
- Surface a small “what this unlocks” block near the hero card.
- Make the stats read as proof, not just counters.

### 4. Chats and deals still lack a visible path from match to action

Where: [ChatsView.swift](file:///Users/dorffoto/Documents/New%20project/matcha/ios/MATCHA/Features/Chats/ChatsView.swift#L14), [ChatsView.swift](file:///Users/dorffoto/Documents/New%20project/matcha/ios/MATCHA/Features/Chats/ChatsView.swift#L39)

Chats shows the ingredients of a conversation system, but not the conversion path. New matches are visible, conversations are visible, and some translation/muted-state detail is present, but there is still no obvious “propose a deal / start the collaboration” action. That leaves the core loop underpowered.

Why this is a launch issue:
- Match volume is only useful if users can turn it into action quickly.
- A chat screen without deal CTA feels like messaging, not collaboration.
- The app still lacks a strong answer to “what do I do after a match?”

Recommendation:
- Add a prominent deal CTA in chats.
- Separate “new match” from “active conversation” more clearly.
- Show a next-step prompt when a match is fresh, not buried in the list.

### 5. Offers and Activity are still list-first, outcome-second

Where: [OffersView.swift](file:///Users/dorffoto/Documents/New%20project/matcha/ios/MATCHA/Features/Offers/OffersView.swift#L35), [ActivityView.swift](file:///Users/dorffoto/Documents/New%20project/matcha/ios/MATCHA/Features/Activity/ActivityView.swift#L16), [ActivityView.swift](file:///Users/dorffoto/Documents/New%20project/matcha/ios/MATCHA/Features/Activity/ActivityView.swift#L53)

Offers still feels like a tidy shelf of cards. Activity still feels like a structured list of records. Both are functional, but neither yet answers the user’s immediate question: “what is hot right now, and what should I do next?”

What is missing:
- Better urgency language in offers.
- Summary state in activity.
- More obvious next actions after a successful match or pending response.

Why it matters:
- This is where conversion either accelerates or stalls.
- If the surfaces feel informational, they will not drive repeat usage.
- These screens should communicate momentum, not just inventory.

## Launch Readiness for Bali

**Verdict:** not launch-ready yet, but close enough in structure that copy and CTA changes could move it meaningfully.

The product already supports the right story on paper:
- Bali-first geography.
- Free creators, paid businesses.
- Verification as trust infrastructure.
- Offers plus match feed as the core loop.

The problem is that the story is not yet carried hard enough by the UI. A launch user should not have to infer the positioning from mock data or internal logic. They should see it immediately in onboarding, then feel it again in feed, then get a next step in profile/chats.

## What To Simplify or Add Next

- Add explicit Bali-first and verified language to onboarding, feed, and offers.
- Turn Profile into a real trust/progress hub.
- Add a “Propose a Deal” style CTA in Chats.
- Make Activity show momentum and next actions instead of only lists.
- Reframe Offers around urgency, response, and outcome.

## Priority Order

1. Clarify the Bali-first value prop in user-facing copy.
2. Fix Profile so it explains progress, trust, and unlocks.
3. Add a deal-creation path in Chats.
4. Make Offers and Activity more outcome-led.
5. Keep onboarding short, but make the payoff explicit.

## Changed Files

- [marketing-usability-audit-2026-04-04.md](/Users/dorffoto/Documents/New%20project/matcha/docs/reviews/marketing-usability-audit-2026-04-04.md)
