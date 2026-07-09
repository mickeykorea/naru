fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios status

```sh
[bundle exec] fastlane ios status
```

Latest build processing state (PROCESSING → VALID means live in TestFlight)

### ios invite

```sh
[bundle exec] fastlane ios invite
```

One-time: internal-tester group with access to all builds + add tester

### ios external

```sh
[bundle exec] fastlane ios external
```

Invite an external tester and distribute the latest build (first build needs Beta App Review)

### ios debug_loc

```sh
[bundle exec] fastlane ios debug_loc
```

Debug: dump beta app localizations

### ios bootstrap

```sh
[bundle exec] fastlane ios bootstrap
```

One-time: register bundle ID and create the app in App Store Connect

### ios signing

```sh
[bundle exec] fastlane ios signing
```

One-time per machine: distribution certificate + App Store profiles

### ios ship

```sh
[bundle exec] fastlane ios ship
```

Build, sign, and upload to TestFlight

### ios bootstrap_share

```sh
[bundle exec] fastlane ios bootstrap_share
```

One-time: register share-extension bundle ID (app group itself is web-UI-only)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
