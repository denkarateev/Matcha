# MATCHA Brand Guidelines

## 1. Brand Identity

**Name:** MATCHA
**Tagline:** Brew connections. Blend success.
**Logo:** Two intertwined matcha leaves, #B8FF43 on black
**Philosophy:** MATCHA = Match + Matcha. The matcha drink metaphor runs through the product.

---

## 2. Color Palette

### Primary Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#050505` | App background |
| `backgroundAlt` | `#0A0A0A` | Alternative bg (cards, sheets) |
| `accent` | `#B8FF43` | Primary CTA, active states, branding |
| `accentMuted` | `#6F8F31` | Disabled accent |
| `accentGlow` | `#D8FF8F` | Glow effects, progress bars |

### Surface Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `surface` | `#101314` | Card backgrounds |
| `surfaceSoft` | `#141918` | Elevated cards |
| `elevated` | `#171C1B` | Input fields, chips |
| `elevatedSoft` | `#1C2321` | Hover states |

### Text Colors
| Token | Opacity | Usage |
|-------|---------|-------|
| `textPrimary` | white 100% | Headlines, names |
| `textSecondary` | white 72% | Body text, labels |
| `textMuted` | white 48% | Hints, timestamps |

### Status Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `success` | `#56D987` | Confirmed, online, success |
| `warning` | `#FFB84D` | SuperSwipe gold, caution |
| `danger` | `#FF6B6B` | Error, destructive, Last Minute |
| `baliBlue` | `#74C6FF` | Blue Check, info accent |

### Missing tokens (to add)
| Token | Hex | Usage |
|-------|-----|-------|
| `infoBlue` | `#7EB2FF` | Secondary info tint (used 65+ times) |
| `verificationBlue` | `#1DA1F2` | Verified badges |
| `accentPurple` | `#C084FC` | Support/settings accent |

---

## 3. Typography

### Scale
| Token | Size | Weight | Design | Usage |
|-------|------|--------|--------|-------|
| `heroTitle` | 32pt | Bold | Rounded | Welcome screen title |
| `title1` | 24pt | Bold | Default | Section headers |
| `title2` | 20pt | Semibold | Default | Card titles |
| `headline` | 17pt | Semibold | Default | Row titles |
| `body` | 17pt | Regular | Default | Body copy |
| `callout` | 16pt | Regular | Default | Callout text |
| `subheadline` | 15pt | Regular | Default | Secondary text |
| `footnote` | 13pt | Regular | Default | Meta info |
| `caption` | 12pt | Medium | Default | Labels, badges |

### Display sizes (not yet tokenized)
- Logo: 44-60pt, Bold, Rounded
- Big numbers: 26-30pt, Bold, Rounded
- Profile name: 28pt, Bold, Rounded

### Rules
- Headlines: White, Bold, optional soft shadow
- Body: White 72% opacity
- On accent backgrounds: Black text
- Never use light gray text on dark gray backgrounds

---

## 4. Spacing

### Token Scale
| Token | Value | Usage |
|-------|-------|-------|
| `xSmall` | 6pt | Tight gaps, badge padding |
| `small` | 10pt | Chip padding, compact spacing |
| `medium` | 16pt | Standard padding, card content |
| `large` | 24pt | Section spacing, horizontal margins |
| `xLarge` | 32pt | Major section gaps |

### Common hardcoded values to tokenize
- 8pt: chip gaps, small horizontal spacing
- 12pt: compact card padding, row spacing
- 14pt: field vertical padding
- 20pt: screen horizontal margins (use `large` - 24pt instead)
- 40pt: bottom scroll padding

---

## 5. Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| `card` | 24pt | Cards, bottom sheets |
| `button` | 18pt | Buttons, toast |
| `pill` | 999pt | Capsule chips, badges |
| (missing) `field` | 12pt | Input fields, small cards |
| (missing) `small` | 8pt | Thumbnail corners |

---

## 6. Shadows

| Level | Radius | Y | Opacity | Usage |
|-------|--------|---|---------|-------|
| `level1` | 8pt | 4pt | 30% | Subtle lift (cards) |
| `level2` | 16pt | 8pt | 40% | Medium elevation (modals) |
| `level3` | 24pt | 12pt | 50% | High elevation (overlays) |

---

## 7. Effects

### Glassmorphism
- `.ultraThinMaterial` as base
- Top highlight: white 8% linear gradient
- Border: white 12-18% gradient stroke, 0.75pt
- Shadow: black 25%, radius 12, y 4
- Usage: overlays on photos, info cards on images

### Liquid Glass Pill
- Same as glassmorphism but with `pill` radius
- Usage: badges, action chips on photo backgrounds

---

## 8. Animations

| Token | Type | Response | Damping | Usage |
|-------|------|----------|---------|-------|
| `cardAppear` | Spring | 0.4 | 0.8 | Card entry, drag revert |
| `cardDismiss` | Spring | 0.3 | 0.7 | Card exit, swipe off |
| `tabSwitch` | EaseInOut | 0.2s | — | Tab transitions |
| `sheetPresent` | Spring | 0.35 | 0.85 | Bottom sheets, modals |
| `buttonPress` | Spring | 0.2 | 0.6 | Button feedback |
| `matchReveal` | Spring | 0.5 | 0.65 | Match celebration |

---

## 9. Component Library

### Core Components
| Component | Status | Variants |
|-----------|--------|----------|
| GlassCard | ✅ | Default, Surface, Section |
| MatchaAvatar | ✅ | small/medium/large/xlarge, blueCheck |
| MatchaBadge | ✅ | blueCheck, new, pro, bali |
| TagChip | ✅ | Selected/unselected, with action |
| MatchaTextField | ✅ | Normal, error, success states |
| MatchaToast | ✅ | Default with auto-dismiss |
| SkeletonView | ✅ | Generic loading placeholder |
| EmptyStateView | ✅ | Icon + title + subtitle |
| OfflineBanner | ✅ | Warning bar |
| ServerErrorView | ✅ | Fullscreen with retry |
| DealStatusBadge | ✅ | 6 deal statuses |
| ProfileCard | ✅ | Swipe card variant |
| OfferCard | ✅ | Photo + info |

### Button Styles
| Style | Usage |
|-------|-------|
| MatchaPrimaryButton | Main CTA (accent bg, black text) |
| MatchaSecondaryButton | Secondary actions (elevated bg, white text) |
| MatchaActionButton | Circular icon buttons |

---

## 10. Microcopy Voice

| Moment | Text |
|--------|------|
| Welcome | "Your first cup is on us" |
| Verified | "You're in the blend" |
| Match | "Fresh Match!" |
| Deal confirmed | "Your matcha is brewing" |
| Deal finished | "Perfect blend! Rate your experience" |
| Empty feed | "You've finished your cup. Come back tomorrow" |
| SuperSwipe | "Double shot sent! They'll notice" |

---

## 11. Audit Score: 62/100

### Issues
- 65+ hardcoded hex colors in features
- 20+ unique font sizes not tokenized
- 3 major colors used everywhere but not in MatchaTokens
- Spacing inconsistency (8, 12, 14, 20 used directly)

### Priority Fixes
1. Add `infoBlue`, `verificationBlue`, `accentPurple` to MatchaTokens
2. Add `backgroundAlt` (#0A0A0A) — used in 10+ files
3. Create typography tokens for sizes 11, 14, 22, 28
4. Add `field` radius (12pt) and `small` radius (8pt)
5. Standardize screen margins to `large` (24pt) everywhere
