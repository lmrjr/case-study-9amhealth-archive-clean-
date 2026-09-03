# 9amHealth Brand Guidelines — deck-relevant extract

Source: `dump/9amHealth_BrandGuidelines_compressed.pdf` (115 pp). This is the
**working subset** that governs the case-study deck — colors, type, pattern,
layout motif, and voice. Page numbers below are the PDF's printed numbers
(off by one from the file page index).

> Complements `brand-tokens.md` (which already had Cream / Charcoal / Sunrise).
> This file adds the full spectrum set, the font source, the pattern rule, the
> billboard layout motif, and the messaging/voice rules that shape deck copy.

---

## 1. Typography (p.48)

- Family: **STK Bureau** — serif + sans in one family.
  - **STK Bureau Serif** — *primary typeface*, editorial feel, credibility. Weight used: Light.
  - **STK Bureau Sans** — clean/readable/simple. Weights: Light, Book, Medium.
- **License / download:** https://typekiosk.smuss.studio/  ← the specific font.
- Pairing logic: serif for headlines (editorial, credible), sans for body (simple, readable).
- **Deck stand-ins:** Noto Serif (→ Bureau Serif), Noto Sans (→ Bureau Sans) until the license is bought. Swap the two font constants in `build_deck.py` once installed.

## 2. Color (p.54–56)

Exact values — use as-is. CMYK omitted by design (use Pantone for print).

### Core / neutrals
| Name | HEX | RGB | Use |
|---|---|---|---|
| Cream | `#FFFCF3` | 255,252,243 | **Background** with Charcoal text; container for collage/card work |
| White | `#FFFFFF` | 255,255,255 | Background alt |
| Charcoal | `#212121` | 33,33,33 | **Text** on Cream/White |

### Sunrise — primary spectrum (vertical gradient, top→bottom)
Derived from a sun rising. Use for high-level brand comms, intros, app avatars, packaging.
| Stop | HEX | RGB | Pantone |
|---|---|---|---|
| Top (blue) | `#80AEFF` | 128,174,255 | 659C |
| Mid (pink) | `#F7BDE6` | 247,189,230 | 243C |
| Bottom (orange) | `#FFBD70` | 255,222,112* | 1365C |

\* guidelines print RGB 255,289,112 — impossible (289>255); HEX `#FFBD70` is authoritative.

### Secondary spectrums (each a vertical gradient, bottom fades to Cream `#FFFCF3`)
| Spectrum | Top | Mid | When |
|---|---|---|---|
| **Mid-Morning** | `#FFEFF9` | `#ABD4FF` (blue) | contrasting freshness |
| **Afternoon** | `#FFF3C7` | `#B0F2CE` (green) | **educational content** (per p.68) |
| **Golden Hour** | `#FFDEB8` | `#FBDEF3` (pink) | contrasting freshness |

## 3. Light-pattern construction (p.62)

Light patterns + color spectrums combine into graphic elements (the app icon is the worked example).
1. Start with a full **color spectrum** (Sunrise: blue→pink→orange).
2. **Crop** to the application's dimensions.
3. Apply the spectrum to a **foreground "sun"** element (a circle/arc), positioned for contrast.
4. Combine sun + background, rotate/position → the rising-sun horizon.
5. Apply artwork on top (e.g. the "9am" wordmark).

Icon spectrum stops (as printed): `85AFFE` · `F8BEE2` · `FFCE86` (≈ our Sunrise stops).

## 4. Billboard / Cream-usage layout motif (p.68) — the one to copy

The layout Luis keeps eyeing. Rules for OOH / marketing on Cream:
- **Cream card** background, **Charcoal serif** text. Builds credibility/clarity.
- **Image sits right**, flush to the edge, **full card height** (≈⅓ width). Text/copy left (≈⅔).
- Logo bottom-right; tagline bottom-left ("Diabetes care for busy people.").
- **A thin light-pattern strip runs along the bottom edge of the card** (horizontal gradient).
  - Use **Sunrise** strip for *overarching brand communications*.
  - Use **Afternoon** strip when *content is educational*.

**Applied to the deck:** cream slides, charcoal serif headlines, **chart flush-right**, text left, **thin gradient strip above the footer**. (See `build_deck.py` → `strip()` + `content()`.)

## 5. Voice & messaging (p.5–6, 42–54)

### Positioning
> Concierge cardiometabolic care that's actually there every step of the way, to level up daily life.

Recurring platform motif: **"every day."** Personality: **Uplifting · Real · At-your-service · Solid.**

### Tonal values (DO / DON'T)
- **Encouraging, not peppy** — "Expert guidance for living your healthiest life," not "First day of the rest of your life!"
- **Respectful, not formal.**
- **Informative, not complicated** — plain, not clinical jargon.
- **Honest, not blunt** — "we'll build a plan around what works for you," not "you need to change your diet."

### Vocabulary rules (apply to deck copy)
- Write **"9amHealth"** — one word, capital **H**.
- Say **"whole body"**, not "holistic".
- Say **"people with diabetes / obesity"**, not "diabetic" / "obese". Center **"weight loss."**
- Care areas = **"cardiometabolic health"** / **"specialized care."**
- Avoid "chronic care" / "heart disease" in member-facing copy.
- **Members**, not "users/patients," for our people.

### Deck copy check
- Slide labels using "GLP-1 diabetes" → prefer "GLP-1 (diabetes indication)" or reference the condition respectfully.
- Recommendations column: keep it encouraging + honest, not blunt directives.
