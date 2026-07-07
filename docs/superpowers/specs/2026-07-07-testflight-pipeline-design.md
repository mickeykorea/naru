# Naru v0.1 — TestFlight Pipeline Design

Date: 2026-07-07
Status: Approved

## Goal

A real, installable Naru app on Mickey's iPhone via TestFlight, built entirely
from the CLI. Every step reproducible so the workflow can later be codified as
a skill covering dev → packaging → App Store submission.

## Decisions (interviewed and approved)

| Decision | Choice | Why |
|----------|--------|-----|
| App identity | Real Naru shell, not throwaway | Bundle ID and ASC app record are semi-permanent; nothing wasted |
| Bundle ID | `com.mickeyoh.naru` | Matches owner domain mickeyoh.com |
| Framework | SwiftUI native | Zero JS toolchain, best fit with Xcode 26 + gstack ios-* skills |
| Project definition | XcodeGen (`project.yml`) | Declarative, diff-able, no hand-edited pbxproj |
| Upload | fastlane (`pilot`) | One reproducible Fastfile lane; industry standard |
| Signing | `cert` + `sigh` (local keychain) | Simplest correct solo-dev setup; move to `match` only if CI/second machine appears |
| ASC auth | App Store Connect API key (.p8) | One-time manual creation in web UI; everything after goes through the API |

## The app (v0.1)

One SwiftUI screen: Naru wordmark, tagline, and a local-only "inbox" —
paste a link, it appears in a saved list (persisted with UserDefaults/AppStorage).
Deliberately tiny; the pipeline is the deliverable.

## Pipeline phases

1. **Tooling** — `brew install fastlane xcodegen` (Homebrew fastlane bundles its own Ruby).
2. **ASC API key** — manual, one-time, in App Store Connect web UI (2FA-gated).
   Output: Key ID, Issuer ID, `.p8` file → `~/.appstoreconnect/private_keys/`,
   referenced from `fastlane/.env` (git-ignored).
3. **Scaffold** — SwiftUI app + icon, `xcodegen generate`, verify in simulator.
4. **App record** — `fastlane produce`: registers bundle ID on the developer
   portal and creates the Naru app in App Store Connect.
5. **Signing** — `fastlane cert` (Apple Distribution certificate into login
   keychain) + `sigh` (App Store provisioning profile).
6. **Ship lane** — `fastlane ship`: auto-increment build number → `build_app`
   (archive + sign) → `upload_to_testflight`.
7. **Install** — internal tester on own team ⇒ no Beta App Review; build appears
   in the TestFlight app minutes after Apple finishes processing.

## Error handling

- Secrets never enter git (`.gitignore` covers `.env`, `*.p8`, certs, profiles).
- Simulator build must pass before any signing/upload step.
- Each fastlane action is independently re-runnable; failures stop the lane.

## Later (out of scope for v0.1, same foundation)

- `release` lane with `deliver` for App Store metadata/screenshots/submission.
- `mobile-mcp` as automated QA layer on simulator/device (pairs with gstack ios-qa).
- `match` if CI or a second dev machine is added.
- Codify the whole workflow as a reusable skill.

Explicitly skipped: vercel-labs/agent-browser — the only web-UI step is the
one-time API key creation, which is login/2FA-gated and safer done by hand.
