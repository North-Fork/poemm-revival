# Xcode Setup — The Hours Have It Wrong

## 1. Create the Xcode project

- **Template:** iOS → App
- **Interface:** SwiftUI
- **Language:** Swift
- **Bundle ID:** `net.poemm.thehourshaveitwrong`
- **Minimum deployment:** iOS 16.0

## 2. Add SpriteKit

In the project target → General → Frameworks, Libraries, and Embedded Content:
- Add `SpriteKit.framework`

## 3. Add source files

Drag all `.swift` files from this folder into the Xcode project navigator,
preserving folder groups (Model/, Scene/, SwiftUI/).
When prompted, choose **"Create groups"** (not folder references).

Replace the auto-generated `ContentView.swift` and App entry file with these versions.

## 4. Add resources

Drag `Resources/poem.txt` and `Resources/CircadianProperties.plist` into the project.
Confirm they appear in **Build Phases → Copy Bundle Resources**.

## 5. Delete the auto-generated SpriteKit game scene

Xcode's Game template adds `GameScene.swift` / `GameScene.sks` — delete these if present.

## 6. Build and run

Run on iPhone simulator. Words will appear drifting in today's active time phase.

## 7. Test each phase

**Settings → General → Date & Time → Set Automatically OFF**
Set the clock to each phase boundary to verify transitions:

| Time to set | Expected phase |
|---|---|
| 3:00 AM | Night — dim blue-grey, tight center cluster |
| 4:45 AM | Night→Dawn blend (75% through transition window) |
| 6:00 AM | Dawn — gold words, upward drift |
| 9:00 AM | Morning — white words, energetic full-screen scatter |
| 2:00 PM | Afternoon — amber tones, heavy downward drift |
| 7:00 PM | Dusk — purple-pink, edge-biased scatter |
| 9:00 PM | Evening — cool grey, retreating inward |
| 11:50 PM → 12:10 AM | Night continuous across midnight — no visual glitch |

## 8. Test multi-touch

In the iPhone simulator: **I/O → Input → Send Simultaneous Touches**.
Two-finger drag should create two independent attractor points pulling nearby words.

## 9. Performance

Toggle `skView.showsFPS = true` in `PoemSceneView.makeUIView` during development.
Target is stable 60 fps with all ~140 word nodes.

## Development notes

- `##phase` headers in `poem.txt` must match `TimePhase.rawValue` exactly
  (night, dawn, morning, afternoon, dusk, evening)
- Lewis can revise poem text freely; only the `##phase` structure matters
- `*word` prefix in `poem.txt` sets `isFocus: true` — reserved for future highlight color
- To override phase for testing without changing system clock, call
  `phaseManager.evaluate(date:)` with a constructed `Date`
