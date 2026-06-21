# Caply × Instagram Edits — Caption Feature Implementation Plan

> Goal: Replicate the look, feel, and full feature set of Instagram Edits' auto-caption system inside Caply — while keeping every existing Caply feature intact.

---

## Part 1 — What Instagram Edits Has (Caption Features Only)

### 1.1 Auto-Generation
| Feature | Edits | Caply today |
|---|---|---|
| AI speech-to-text (cloud) | ✅ Meta AI / Whisper | ✅ Groq Whisper |
| On-device AI | ✅ | ✅ HuggingFace Transformers |
| Multi-language | ✅ | ✅ |
| Word-level timestamps | ✅ (per word) | ✅ (from Groq & LocalAI) |

**Status: parity achieved. No new work needed here.**

---

### 1.2 Karaoke / Word Highlight
Active word lights up with a different color or background as the video plays — the signature look of modern short-form captions.

| Detail | Edits | Caply today |
|---|---|---|
| Per-word highlight color | ✅ | ❌ not rendered |
| Highlight box behind active word | ✅ | ❌ |
| Rest of caption dimmed | ✅ | ❌ |
| Smooth word-by-word advance | ✅ | ❌ |

**Caply already stores word timestamps from Groq/LocalAI — the render engine just doesn't use them yet.**

---

### 1.3 Caption Style Presets
Horizontal scrollable row of visual "card" tiles, each showing a mini live preview of font + color + animation combo. Tap one → applies globally.

| Detail | Edits | Caply today |
|---|---|---|
| Visual thumbnail cards | ✅ | ❌ (text chips only) |
| Named styles (e.g. "Classic", "Neon", "Bold") | ✅ | ✅ (PRESETS array exists) |
| Horizontal scroll row | ✅ | ❌ (vertical list) |
| Live preview inside card | ✅ | ❌ |

---

### 1.4 Caption Animations (Entry / Exit)
Each caption or word can have an entrance animation — this is what makes Edits feel premium.

| Animation | Edits | Caply today |
|---|---|---|
| None (static) | ✅ | ✅ |
| Fade in | ✅ | ❌ |
| Slide up | ✅ | ❌ |
| Pop / Scale | ✅ | ❌ |
| Typewriter | ✅ | ❌ |
| Word-by-word pop | ✅ | ❌ |
| Bounce | ✅ | ❌ |

---

### 1.5 Typography & Color Controls
| Control | Edits | Caply today |
|---|---|---|
| Font selector | ✅ 14+ fonts | ✅ (+ custom upload) |
| Text color (full color picker) | ✅ | ✅ |
| Background / pill color | ✅ | ✅ |
| Highlight / active-word color | ✅ | ❌ (no separate field) |
| Text size slider | ✅ | ✅ |
| Bold / Italic | ✅ | ❌ |
| Outline (stroke) | ✅ | ✅ |
| Shadow | ✅ | ✅ |
| Alignment (L / C / R) | ✅ | ✅ |
| ALL CAPS toggle | ✅ | ❌ |

---

### 1.6 Position & Layout
| Control | Edits | Caply today |
|---|---|---|
| Drag caption to reposition on video | ✅ | ✅ |
| Top / Middle / Bottom presets | ✅ | ✅ |
| Safe-area awareness (iOS notch) | ✅ | ✅ (env() insets) |

---

### 1.7 Style Panel UX (the big UI delta)
Edits uses a **bottom drawer** with:
- Large visual preset row at top (scrollable cards)
- Grouped controls underneath: Text → Color → Animation → Effects
- Pill/tab switcher between sections (not a long scroll form)
- Color taps open a full-screen color picker with swatches + hex input
- "Apply to all" is the default; per-caption override is an option

Caply today uses a long-scroll form bottom sheet — functional but not Edits-like.

---

## Part 2 — Gap Summary (what needs to be built)

| # | Gap | Priority |
|---|---|---|
| G1 | **Karaoke word highlight render** | 🔴 High |
| G2 | **Caption entry animations** (fade, slide, pop, typewriter) | 🔴 High |
| G3 | **Visual preset cards** (thumbnail row, not text chips) | 🔴 High |
| G4 | **Highlight / active-word color** field in globalStyle | 🟠 Medium |
| G5 | **Bold / Italic** toggles | 🟠 Medium |
| G6 | **ALL CAPS** toggle | 🟠 Medium |
| G7 | **Redesigned style panel** (tabbed sections, not long form) | 🟠 Medium |
| G8 | **Full-screen color picker** (swatches + hex) replacing `<input type=color>` | 🟡 Low |
| G9 | **Per-caption style override** | 🟡 Low |

---

## Part 3 — Implementation Plan (Phased)

### Phase 1 — Karaoke Engine (G1, G4)
*This is the most impactful single change — zero UI redesign needed.*

**What to add to `globalStyle`:**
```js
karaokeEnabled: false,       // bool — turns on word-by-word highlight
highlightColor: '#FFD700',   // active word color
highlightBg: '',             // optional bg pill on active word
dimInactive: true,           // whether inactive words are dimmed
```

**Changes to `buildOverlay()` / `syncSubtitleOverlay()`:**
- When `karaokeEnabled` is true, instead of rendering the full subtitle text as one string, split it into `<span>` per word.
- Each span gets class `word-inactive` or `word-active` based on whether `currentTime` falls within that word's `[start, end]` timestamp.
- Word timestamps are already stored in `sub.words[]` array (produced by Groq & LocalAI).
- CSS: `word-active { color: var(--highlight); }` / `word-inactive { opacity: 0.45; }`
- Fallback: if no word timestamps exist (WebSpeech), treat whole caption as one "active word".

**Style panel additions:**
- Karaoke toggle switch (on/off)
- Highlight color swatch (only shown when karaoke is on)
- Dim inactive words toggle

**Estimated effort: ~150 lines of JS/CSS changes**

---

### Phase 2 — Caption Animations (G2)
*Applied via CSS animation classes injected when a caption becomes active.*

**Animations to implement (all pure CSS @keyframes):**

| Name | CSS approach |
|---|---|
| `none` | no class |
| `fade` | `opacity 0→1` over 250ms |
| `slide-up` | `translateY(12px)→0` + fade |
| `pop` | `scale(0.8)→1` + fade (quick, snappy) |
| `typewriter` | clip-path or character-by-character JS render |
| `word-pop` | each word span animates in with 60ms stagger |
| `bounce` | scale overshoot keyframe |

**Integration:**
- Add `animation: 'none'` field to `globalStyle`.
- In `buildOverlay()`, add the appropriate CSS class to `#subtitle-overlay` when caption changes.
- Re-trigger animation on every new caption by removing/re-adding the class.
- Animation selector goes in the style panel (icon grid, not a dropdown).

**Estimated effort: ~100 lines CSS + ~60 lines JS**

---

### Phase 3 — Visual Preset Cards + Redesigned Style Panel (G3, G5, G6, G7)

**Preset Cards:**
- Replace existing text chips with `<div class="preset-card">` tiles (~120×70px each).
- Each card renders a mini canvas or styled div showing: sample text "Hello" in that preset's font/color/bg/animation.
- Horizontal scroll row pinned above the style controls.
- Active preset gets a white border ring.

**Redesigned Style Panel layout:**
```
┌─────────────────────────────────────┐
│ ● Caption Styles                [×] │  ← sheet header
├─────────────────────────────────────┤
│ [Classic] [Neon] [Bold] [Karaoke]…  │  ← scrollable preset cards
├─────────────────────────────────────┤
│  [TEXT]  [COLOR]  [ANIMATE]  [MORE] │  ← pill tab row
├─────────────────────────────────────┤
│  (tab content swaps here)           │
│                                     │
│  TEXT tab:                          │
│    Font: [selector]  Size: [slider] │
│    [B]  [I]  [CAPS]                 │
│    Align: [←][≡][→]                 │
│                                     │
│  COLOR tab:                         │
│    Text ●  Background ●             │
│    Highlight ●  (if karaoke on)     │
│    Opacity: [slider]                │
│                                     │
│  ANIMATE tab:                       │
│    [none][fade][slide][pop][type]   │  ← icon grid
│    Karaoke [toggle]                 │
│                                     │
│  MORE tab:                          │
│    Shadow ● [toggle]                │
│    Outline ● [toggle]               │
│    Position: top/mid/bot            │
└─────────────────────────────────────┘
```

**New globalStyle fields:**
```js
fontWeight: 'normal',   // 'normal' | 'bold'
fontStyle:  'normal',   // 'normal' | 'italic'
textTransform: 'none',  // 'none' | 'uppercase'
animation: 'none',      // see Phase 2
```

**Estimated effort: ~300 lines HTML/CSS/JS (pure reskin, no logic changes)**

---

### Phase 4 — Polish (G8, G9) — optional / later

- **G8 Color picker:** swap native `<input type=color>` for a custom picker with hex input + 12 preset swatches. ~80 lines.
- **G9 Per-caption style:** add `style: {}` field to individual subtitle objects, with a "Customize this caption" button in the edit panel. Merges over globalStyle at render time. ~100 lines.

---

## Part 4 — What We Are NOT Changing

- All existing generation engines (Groq, LocalAI, WebSpeech) — untouched
- Timeline, undo/redo, split/merge/delete logic — untouched
- Export (MP4, SRT, VTT) — untouched
- Custom font upload — untouched
- PWA/iOS fullscreen — untouched
- Settings sheet (Groq key, etc.) — untouched
- INIT block — same 6 calls

The redesign is **additive and cosmetic** at the JS logic level. The only structural change is the style panel HTML + the overlay render function.

---

## Part 5 — Execution Order

```
Phase 1: Karaoke engine        → biggest user-visible win, lowest risk
Phase 2: Animations            → pure CSS, no logic changes
Phase 3: Visual preset cards   → HTML/CSS reskin of existing PRESETS array
Phase 3: Style panel tabs      → HTML/CSS reskin, same underlying controls
Phase 4: Color picker          → polish
Phase 4: Per-caption style     → advanced feature
```

Each phase is self-contained and can be shipped independently. Recommended to do them in order since Phase 3 wraps Phases 1 and 2 into the UI.

---

## Part 6 — Instagram Edits Visual Language (for reference)

| Element | Value |
|---|---|
| Background | `#000` or `#0a0a0a` |
| Accent / CTA | `#fff` or gradient blue-purple |
| Sheet handles | `#333` pill |
| Preset card bg | `#1a1a1a` with 1px `#2a2a2a` border |
| Active preset ring | `2px solid #fff` |
| Tab pills | `#1c1c1c` bg, active: `#fff` text on `#333` bg |
| Font in UI | SF Pro / system-ui, 13-14px |
| Color swatches | 32px circles, 4px gap, horizontal row |
| Karaoke highlight default | `#FFE500` (bright yellow) |
| Animation icons | Outline SVG icons, 24px |

Caply's existing dark theme (`#0d0d0d` bg, `#00D4FF` accent) is very close — the accent color can stay as Caply's brand differentiator.

---

*Last updated: June 2026*
