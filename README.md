# Between

*in between moments*

A menu bar app for short breathwork between meetings. Click the wheel icon in the menu bar, pick a sequence, and a full-screen ambient scene takes over and moves with your breath. The timer sits bottom right. Esc ends, Space pauses.

## Install

1. Download **[Between.zip](https://github.com/NealCG/between/releases/latest/download/Between.zip)** (latest version).
2. Double-click it, then drag **Between** into your Applications folder.
3. Open it. The first time, macOS says it can't check the app for malicious software, because it isn't signed with an Apple developer account yet. Click **Done**, go to **System Settings → Privacy & Security**, scroll down, and click **Open Anyway**. You only do this once.
4. Look for the wheel icon in your menu bar. Tick **Open at login** in its menu if you want it there every day.

Works on macOS 13 or later, on Apple Silicon and Intel Macs.

## Build it yourself

Needs Apple's command line tools (`xcode-select --install`; full Xcode also works).

```bash
./build.sh          # builds Between.app and Between.zip for this Mac
open Between.app
```

`UNIVERSAL=1 ./build.sh` builds for both Apple Silicon and Intel (needs full Xcode). To work in Xcode instead, open this folder (Xcode reads `Package.swift`) and run the `Between` scheme.

## Releasing a new version

Every push to `main` builds the app on GitHub and publishes it as the release named in the `VERSION` file, so the download link above always has the latest build. To start a new numbered release, change `VERSION` (for example to `0.2`) and push.

## The sequences

| Name | Pattern | Length | For |
|---|---|---|---|
| Reset | Deep inhale 4s, sip in more 2s, slow sigh out 9s | 1:30 | Between back-to-backs |
| Focus | Box 5-5-5-5 | 3:00 | Before deep work or a meeting |
| Wind Down | 5 in, 7 hold, 9 out | 3:09 | End of the day |

Each session opens on a dark screen: the between logo, then "COME BACK ... TO CENTER" across the middle of the screen (`Assets/ComeBackToCenter.svg`, drawn by `IntroCard.swift`). Then the scene fades up and a 3-2-1 countdown leads into the first breath. It ends on a closing quote that rotates each time. Lengths round to whole breath cycles so a session never cuts off mid-breath.

## Where things live

- `Sequences.swift` — the three sequences. Add or edit one here: a list of phases (label, seconds, how full the breath gets) and which scene it uses.
- `Scenes.swift` — the three ambient scenes (meadow in motion, tide, dusk) and how each one moves with the breath.
- `AmbientView.swift` — draws the current scene full screen, softens it with a blur and adds a light film grain.
- `SessionView.swift` — the full-screen layout: cue text, timer, controls, finish screen. All text is Helvetica Neue Regular (`helvetica()` in `BetweenApp.swift`), with tracking set by `textTracking` (currently -0.5pt).
- `SessionPresenter.swift` — opens and closes the session window, Esc / Space keys.
- `SessionClock.swift` — timing, pause, the optional tone, and the daily count.
- `MenuView.swift` — the drop-down from the menu bar.
- `MenuIcon.swift` — the spoked-wheel menu bar icon. The matching app icon is `Assets/AppIcon.icns` (preview: `Assets/AppIcon.png`).
- `Quotes.swift` — the closing quotes. Add your own to the list.
- `Logo.swift` — the between wordmark, converted from `Assets/BetweenLogo.svg` into a native shape so it stays sharp at any size.

## Settings in the menu

- **Go full screen on start** — off gives a floating 960×640 window instead.
- **Soft tone on each phase** — a low, soft tone that swells in and fades out when the phase changes (`SoftTone.swift`).
- **Open at login** — registers the app as a login item (works once it's built as `Between.app`).
