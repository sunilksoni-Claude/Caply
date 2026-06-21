# Caply — Project Memory

## ✅ WORKING BASELINE (June 2026)

**File:** `index.html`  
**Lines:** 4128  
**Size:** ~198KB (202,468 bytes)  
**MD5:** `02e93d6fa57133042197098149200949`  
**Backup:** `index.working-baseline.html` (identical copy, do not touch)

This is the **100% working product**. Every feature below is confirmed working and verified by syntax check + function presence audit. All 10 key functions present.

**Last change:** Seamless caption drag — replaced broken `position`/`positionOffset` snap system with `posY` (0–90% from top). Drag now moves captions freely in 2D with correct direction, full range, no jumps.

---

## Architecture

Single-file HTML app — all CSS, HTML, JS inline in `index.html`. No build step, no dependencies to install.

**Key globals:** `subtitles[]`, `globalStyle{}`, `selectedIdx`, `pxPerSec`, `undoStack[]`, `redoStack[]`, `timelineLocked`, `customFonts[]`

**globalStyle positioning:** `posX` (2–98, left%), `posY` (0–90, top% — null falls back to legacy `position`/`positionOffset`)

---

## Features (all working)

### Video
- Upload video → plays in `<video id="vid">`
- Fake-fullscreen (iOS blocks real fullscreen on divs): `#video-wrap.fake-fullscreen { position:fixed; inset:0; z-index:300 }`
- Fullscreen exit: `#btn-fs-exit` is **outside** `#video-wrap` as `position:fixed; z-index:9999` — critical, iOS native video layer blocks anything inside the wrap
- Pinch-to-resize captions, drag-to-reposition captions on video (touch gestures on `#video-wrap`)
- Free 2D caption drag via `posY` (0–90% from top) + `posX` (2–98% from left) — no snapping, natural direction
- Export to MP4 via `MediaRecorder` + `canvas.captureStream()`; uses `navigator.share()` for iOS camera roll

### Captions / Subtitles
- Auto-generate via: **Groq Cloud** (`whisper-large-v3-turbo`), **On-device AI** (`generateViaLocalAI`, uses `@huggingface/transformers@3.5.2`), **Web Speech API**
- Caption overlay: `syncSubtitleOverlay()` → `buildOverlay()` via `requestAnimationFrame` loop (`startRaf()`)
- Edit text, split, delete, drag on timeline
- Export SRT / VTT
- Undo / redo (`snapshot()`, `undo()`, `redo()`)
- Clear all captions: `clearAll()` (snapshots first)

### Global Style
- Font, size, color, background, position, alignment, shadow, outline, preset
- `#style-sheet` bottom sheet modal (opened via `openStylePanel()`)
- CapCut-style presets: `const PRESETS` → `renderPresets()` → `applyPreset()`
- `renderPresets()` is called in INIT block — required

### Timeline
- `rebuildTimeline()` builds track from `subtitles[]`
- Lock button (`#btn-lock`): `toggleTimelineLock()` sets `timelineLocked`; `tlPointerDown()` returns early when locked — prevents accidental caption drags
- Auto-scroll during playback: `syncPlayhead()` scrolls `#timeline-scroll` to keep playhead visible with 25% margin

### Font Manager
- Upload custom fonts (TTF/OTF/WOFF/WOFF2) → `FontFace` API → `document.fonts.add()`
- Persist across reloads: base64 in `localStorage` key `FONT_STORE_KEY = 'caply_custom_fonts_v1'`
- Key functions: `handleFontUpload`, `restoreCustomFonts`, `saveFontsToStorage`, `addFontToSelector`, `removeFontFromSelector`, `renderFontList`, `removeCustomFont`

### Settings
- Groq API key: `saveGroqKey()`, `refreshGroqBadge()`
- `#settings-sheet` bottom sheet

### PWA / iOS Home Screen
- `<link rel="apple-touch-icon" href="data:image/png;base64,...">` — inline base64 PNG (clean bold "Caply" in #00D4FF, no glow, no white halo)
- `Caply.png` (180×180) — same icon as standalone file
- `100dvh` + `env(safe-area-inset-*)` for iPhone viewport

---

## Critical Rules (learned from bugs)

1. **Never split JS across multiple `<script>` tags with duplicate `let`/`const` declarations** — causes SyntaxError that silently kills ALL JavaScript.
2. **`#btn-fs-exit` must live OUTSIDE `#video-wrap`** — iOS native video layer blocks anything inside regardless of z-index.
3. **After any large edit, always run:** `node --check index.html` (or equivalent syntax check) + verify key functions present with `grep`.
4. **The Edit tool can silently truncate large files.** For replacements >50 lines, use Python `str.replace()` or bash heredoc. Always check `wc -l` before/after.
5. **`renderPresets()` must be in the INIT block** — it was lost in a truncation and broke presets silently.
6. **File size reduction from simpler icon (not lost features):** 184KB → 164KB = ~20KB saved from smaller base64 PNG (no clapperboard, no glow).

---

## INIT Block (bottom of JS)

```js
startRaf();
rebuildTimeline();
restoreProject();
refreshGroqBadge();
renderPresets();
restoreCustomFonts();
```

All six calls must be present.

---

## Files

| File | Purpose |
|------|---------|
| `index.html` | The entire app |
| `index.working-baseline.html` | Frozen backup of working baseline |
| `index.backup.html` | Older backup (pre-baseline) |
| `Caply.png` | 180×180 PWA icon |
| `push-to-github.ps1` | GitHub deploy script |
| `start-caply.bat` | Local dev server |
