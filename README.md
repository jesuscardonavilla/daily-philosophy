# Daily Philosophy

A personal iPhone app: one idea a day, a map of 158 thinkers that fills in as you learn, a deeper read on each, and a conversation with any of them.

It is a SwiftUI shell around a bundled web app (`DailyPhilosophy/Resources/index.html`). Your progress is stored on the phone. Only the chat needs internet.

## Open it

1. Open `DailyPhilosophy.xcodeproj` in Xcode 15 or later.
2. Select the **DailyPhilosophy** target, then **Signing & Capabilities**. Choose your Apple ID under **Team** and change the bundle identifier if Xcode asks for a unique one.
3. On the iPhone: **Settings > Privacy & Security > Developer Mode** on, then restart.
4. Plug the phone in, pick it as the run destination, press Run. The first time, trust your developer profile in **Settings > General > VPN & Device Management**.

## Talk to the thinkers

Open the app, go to **Settings** (button at the bottom of Today), paste an Anthropic API key. It is saved in the iOS Keychain on this phone only. Then open any thinker and tap **Talk with...**.

- The replies are an AI imitation grounded in each thinker's ideas and books. They are not real quotations.
- Living thinkers get a third-person guide, not an impersonation.
- Each message costs a small amount on your API account.

## Updating without Xcode

The app checks GitHub each time it opens and shows **New version ready. Tap to update** when `version.json` has a newer number. You can also tap **Update app** on Today (or in Settings). It downloads the newest `index.html` from this repo's `main` branch, so content changes need no rebuild. GitHub can take a few minutes to serve a fresh push. **Settings > Go back to the built-in version** removes the downloaded copy. Changes to the Swift code still need an Xcode run.

## Updating the content

The app lives in the web file. After editing it, run `./sync_web.sh path/to/index.html` and rebuild. If you add or remove Swift files, run `python3 tools/gen_pbxproj.py` (or use `project.yml` with XcodeGen).

## Notes

- The app uses the system Helvetica Neue, so it works offline.
- The model is set in `ClaudeClient.swift` (`model`).
