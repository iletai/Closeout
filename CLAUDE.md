# CLAUDE.md

## What this app is

Closeout is an offline job-report app for solo tradespeople: per-job photos, OCR-prefilled receipts, manual mileage, and a one-page PDF report to share. Free tier caps 4 photos per job; Closeout Pro (StoreKit 2: `pro.yearly`, `pro.lifetime`) unlocks unlimited photos, branding, custom mileage rate and CSV export. SwiftData, no backend, no third-party dependencies. Design tokens: `App/Theme/Theme.swift`.

## Architecture

- `App/` — SwiftUI app target, grouped per feature: `Jobs/`, `Evidence/`, `Receipts/`, `Mileage/`, `Report/`, `Settings/`, `Models/`, `StoreKit/`, `Theme/`.
- `Packages/` — local Swift packages (add to `project.yml` `packages:` + target `dependencies:`).
- Own libraries (navigation, update prompt, StoreKit): see skill `iletai-libs`.

## Conventions

- iOS 26+, Swift 6 strict concurrency.
- `project.yml` is the source of truth; run `xcodegen generate` after editing it (`*.xcodeproj` is not committed).
- Environments Dev / Staging / Prod (Staging uses the Prod backend): schemes `Closeout-Dev`, `Closeout-Staging`, `Closeout`; configs `{Debug,Release}-{Dev,Staging,Prod}`; per-env values only in `Config/{Dev,Staging,Prod}.xcconfig` (+ `Backend-Prod.xcconfig`). Read the env via `AppConfiguration.environment`. Never add schemes/configs outside this set.
- Secrets only in `.env` (gitignored); non-secret fastlane values in `fastlane/.env.default` + `fastlane/.env.{dev,staging,prod}`.
- Build-time values: xcconfig variable → `project.yml` `info.properties` → `AppConfiguration`. Never `INFOPLIST_KEY_<custom>` (Xcode drops it).
- Log with `Log.<area>` (os.Logger), not `print`.
- Heavy builds/screenshots run on GitHub Actions, not locally.

## Release

Git Flow: `feature/*` → `develop` → `release/x.y.z` → `main` + tag `x.y.z`; `hotfix/x.y.z` from `main`. Lanes come from `iletai/ios-shared` (`--env dev|staging|prod`). Workflows: `ci.yml`, `deploy-{dev,staging,prod}.yml`.
Release steps: skill `app-store-release`. Signing: skill `ios-cicd-signing`.
