---
name: Caply
description: Build a CapCut-like subtitle editor PWA (Progressive Web App) that runs standalone on iPhone home screen. Use this skill whenever the user wants to build a video subtitle editor, caption tool, auto-subtitle generator, or any CapCut-inspired video text overlay tool. Triggers include: "subtitle editor", "caption editor", "auto subtitles", "CapCut-like", "subtitle PWA", or any request combining video + subtitles + iPhone/mobile. Always use this skill when the user asks to build or extend this specific app — even for partial updates like adding fonts, fixing timeline, or tweaking styles.
---

# Subtitle Editor PWA — CapCut-Inspired

A standalone iPhone PWA for adding subtitles to videos. Auto-generates captions with FREE on-device Whisper AI (transformers.js, no API key) with Web Speech API fallback, supports word-level karaoke captions, CapCut-style templates, rich styling, and exports to SRT/VTT/TXT/JSON plus burned-in video export.

---

## Product Vision

**Reference app**: CapCut's caption/subtitle workflow  
**Platform**: PWA — installable on iPhone home screen via Safari "Add to Home Screen"  
**Rendering engine**: Single HTML file (HTML + CSS + JS, no framework, no build step)  
**Design tone**: Dark, cinematic, professional — like CapCut. Deep charcoal backgrounds, accent color #00D4FF (electric cyan), tight typography, subtle glows.

---

## Core Features

### 1. Video Upload & Playback
- Full-width video player at top of screen
- Subtitle overlay rendered as absolutely positioned div on top of video
- Controls: play/pause, scrub bar, current time display
- Video fits mobile screen width; maintains aspect ratio

### 2. Auto Subtitle Generation
**Primary: Whisper API**
- User enters OpenAI API key (stored in localStorage, shown as password field)
- On "Auto Generate" tap: extract audio → send to `https://api.openai.com/v1/audio/transcriptions`
- Model: `whisper-1`, response_format: `verbose_json` (returns word-level timestamps)
- Parse response into subtitle segments (array of `{id, start, end, text, style}`)
- Show loading spinner during API call

**Fallback: Web Speech API**
- Triggered if: no API key present, OR Whisper call fails
- Show user a banner: "Using Web Speech (play video to generate)"
- Use `SpeechRecognition` with `interimResults: true`
- Sync recognized text with `video.currentTime` to stamp timestamps
- Auto-segment on long pauses (>800ms silence = new subtitle)

**Fallback detection logic:**
```javascript
async function generateSubtitles() {
  if (apiKey && apiKey.length > 10) {
    try {
      await generateViaWhisper();
    } catch (err) {
      showBanner('Whisper failed, switching to Web Speech...');
      generateViaWebSpeech();
    }
  } else {
    generateViaWebSpeech();
  }
}
```

### 3. Manual Subtitle Creation
- "+" button stamps a new subtitle at current video time
- User types text inline
- Drag handles on timeline to adjust start/end
- Delete button per subtitle

### 4. Subtitle Timeline
- Horizontal scrollable timeline below video (CapCut-style)
- Each subtitle shown as a colored block proportional to duration
- Tap block to select and edit
- Selected block highlights in accent color
- Timeline syncs with video playback (playhead moves)

### 5. Subtitle Styling System

#### Global Styles (apply to all subtitles)
| Property | Options |
|---|---|
| Font family | See font list below |
| Font size | 12–48px slider |
| Font color | Color picker |
| Background color | Color picker + opacity slider |
| Background style | None / Tight box / Full-width bar / Frosted glass |
| Text alignment | Left / Center / Right |
| Vertical position | Top / Middle / Bottom (% offset slider) |
| Bold / Italic / Underline | Toggle buttons |
| Text shadow | None / Soft / Hard / Glow |
| Letter spacing | Slider |
| All caps | Toggle |
| Animation | None / Fade / Slide Up / Pop |

#### Per-Subtitle Style Override
- Each subtitle can override any global property
- "Customized" badge shown on subtitle blocks with overrides
- "Reset to global" button clears overrides

#### Built-in Fonts (load via Google Fonts)
```
Oswald, Bebas Neue, Montserrat, Poppins, Roboto Condensed,
Anton, Playfair Display, Raleway, Nunito, Space Mono,
Permanent Marker, Pacifico, Cinzel, Exo 2, Orbitron
```

#### Custom Font Upload
```javascript
async function loadCustomFont(file) {
  const url = URL.createObjectURL(file);
  const font = new FontFace(file.name.replace(/\.[^.]+$/, ''), `url(${url})`);
  await font.load();
  document.fonts.add(font);
  // Add to font picker
}
```
Accepts `.ttf`, `.otf`, `.woff`, `.woff2`

### 6. Subtitle Export
- **SRT**: Standard `.srt` format with sequential numbering
- **VTT**: WebVTT format for web use
- Download triggered via Blob URL
- Export button in top toolbar

```javascript
function toSRT(subtitles) {
  return subtitles.map((s, i) => 
    `${i+1}\n${formatSRTTime(s.start)} --> ${formatSRTTime(s.end)}\n${s.text}\n`
  ).join('\n');
}
```

---

## Data Model

```javascript
// Single subtitle entry
{
  id: 'sub_001',
  start: 4.2,        // seconds
  end: 7.8,          // seconds
  text: 'Hello world',
  style: {           // null = use global, value = override
    fontFamily: null,
    fontSize: null,
    color: '#FFFFFF',
    bgColor: null,
    bgOpacity: null,
    bold: null,
    italic: null,
    animation: 'fade',
    // ... etc
  }
}

// Global style (defaults)
{
  fontFamily: 'Oswald',
  fontSize: 20,
  color: '#FFFFFF',
  bgColor: '#000000',
  bgOpacity: 0.6,
  bgStyle: 'tight',
  alignment: 'center',
  position: 'bottom',
  positionOffset: 10,
  bold: false,
  italic: false,
  underline: false,
  shadow: 'soft',
  letterSpacing: 0,
  allCaps: false,
  animation: 'fade'
}
```

---

## UI Layout (Mobile-First)

```
┌─────────────────────────────┐
│  [≡ Menu]   Caply  [⬇] │  ← Top bar (export button)
├─────────────────────────────┤
│                             │
│        VIDEO PLAYER         │  ← Full width, 16:9
│   [subtitle overlay here]   │
│                             │
├─────────────────────────────┤
│  ◀◀  ▶/⏸  ▶▶   0:04 / 1:32 │  ← Playback controls
├─────────────────────────────┤
│ ──────[████]────────────── │  ← Timeline (scrollable)
│    sub1    sub2    sub3     │
├─────────────────────────────┤
│ [✦ Auto Generate]  [+ Add]  │  ← Action buttons
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ 0:04 → 0:07             │ │  ← Selected subtitle editor
│ │ [Hello world          ] │ │
│ │ [Style ▼] [Delete 🗑] │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ [🎨 Global Style]           │  ← Collapsible style panel
│  Font: [Oswald ▼]  Size: 20 │
│  Color: ■  BG: ■  Opacity:▓ │
│  Bold  Italic  Underline    │
│  Anim: [Fade ▼]             │
└─────────────────────────────┘
```

---

## Design System

```css
:root {
  --bg-primary: #0A0A0A;
  --bg-secondary: #141414;
  --bg-card: #1C1C1C;
  --bg-elevated: #242424;
  --accent: #00D4FF;
  --accent-dim: rgba(0, 212, 255, 0.15);
  --accent-glow: 0 0 20px rgba(0, 212, 255, 0.4);
  --text-primary: #F0F0F0;
  --text-secondary: #888888;
  --text-muted: #444444;
  --border: #2A2A2A;
  --danger: #FF4757;
  --success: #2ED573;
  --radius-sm: 6px;
  --radius-md: 12px;
  --radius-lg: 20px;
  --font-ui: 'Inter', system-ui, sans-serif;
  --transition: 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}
```

**Key UI components:**
- Buttons: pill-shaped, accent border/fill, subtle glow on active
- Cards: `--bg-card` with `--border` border, `--radius-md`
- Timeline blocks: rounded, accent color for selected, dim white for others
- Inputs: dark background, accent focus ring
- Sliders: custom styled, accent thumb
- Bottom panels: slide-up sheets with dark overlay

---

## PWA Configuration

Include in `<head>`:
```html
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="SubtitleAI">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<link rel="apple-touch-icon" href="data:image/svg+xml,..."> <!-- inline SVG icon -->
```

Use `env(safe-area-inset-bottom)` for iPhone notch/home bar padding.

---

## Animation System

```javascript
// Apply animation to subtitle overlay based on style.animation
function applySubtitleAnimation(el, animation) {
  el.style.animation = 'none';
  el.offsetHeight; // reflow
  switch(animation) {
    case 'fade':    el.style.animation = 'subtitleFade 0.3s ease'; break;
    case 'slideUp': el.style.animation = 'subtitleSlideUp 0.3s ease'; break;
    case 'pop':     el.style.animation = 'subtitlePop 0.25s cubic-bezier(0.34,1.56,0.64,1)'; break;
  }
}
```

CSS keyframes for all animations defined in `<style>`.

---

## Build Instructions

1. **Single HTML file** — all CSS and JS inline, no external dependencies except Google Fonts CDN
2. **No build step** — open directly in Safari, works immediately
3. **localStorage** for API key persistence (never log or expose)
4. **requestAnimationFrame loop** for subtitle sync during playback (not setInterval)
5. **Touch events** — use `touchstart`/`touchmove` for timeline scrubbing on iPhone
6. **File input** — use `accept="video/*"` for video upload, `accept=".ttf,.otf,.woff,.woff2"` for fonts
7. **Audio extraction** for Whisper: use Web Audio API to decode, then re-encode as WAV blob

---

## Extension Points (future)

- Multiple video clips / trim editor
- Music/audio track overlay  
- Text animations beyond subtitles
- Burn-in subtitles (FFmpeg.wasm render)
- Cloud save via Google Drive MCP
- Speaker diarization (separate subtitle tracks per speaker)


---

## v2 — CapCut Feature Set (implemented)

- **Auto captions, free**: on-device Whisper (transformers.js `onnx-community/whisper-{tiny,base,small}`, q8, WebGPU→WASM fallback), `return_timestamps:'word'`, audio resampled to mono 16 kHz via OfflineAudioContext. No API key ever. Web Speech remains as mic-based fallback.
- **Word-level cues**: smart grouping (max words/line setting, 38-char cap, 0.7 s gap break, sentence-punctuation break, tail padding clamped to next cue).
- **Karaoke styles**: highlight / fill / box / bounce on the active word, custom karaoke color; works in live overlay AND burned-in export.
- **12 caption templates** (CapCut-style preset chips): Classic, Beast, Hormozi, Karaoke, Pop Word, Box Word, Neon, News Bar, Comic, Elegant, Typewriter, Retro.
- **Text outline** (-webkit-text-stroke / canvas strokeText), extra animations: bounce, zoom, shake, typewriter.
- **Timeline v2**: zoom (20–300 px/s), time ruler, pointer-based drag-move + edge-resize handles, tap-to-seek, tap block to select+seek.
- **Editing tools**: split at playhead (word-accurate), merge with next, word chips (tap to seek), per-sub overrides incl. font size, undo/redo (60 steps, Cmd/Ctrl+Z/Y), find & replace, shift all timings, import SRT/VTT.
- **Playback**: prev/next caption skip, speed cycle, loop selected caption, space/arrow shortcuts.
- **Project autosave** to localStorage (captions + global style), restored on relaunch.
- **Export**: SRT, VTT, TXT, JSON, and **video with burned-in captions** (canvas.captureStream + MediaRecorder, mp4 on Safari / webm elsewhere, audio routed via MediaElementSource, 1280px cap, progress + cancel).
