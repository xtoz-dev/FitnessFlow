# FitnessFlow

Native SwiftUI app for strength training, cardio, nutrition and an on-device fitness coach.

## Build an IPA

1. Copy this folder to a Mac with Xcode 15 or newer.
2. In Terminal, run `chmod +x scripts/build-unsigned-ipa.sh && ./scripts/build-unsigned-ipa.sh` from the project folder.
3. The script compiles the real iPhone app, creates `build-output/Payload/FitnessFlow.app`, and packages it as `build-output/FitnessFlow-unsigned.ipa`.
4. Install that IPA with Sideloadly, AltStore or SideStore. These tools sign it with your Apple ID; free Apple-ID signing normally expires after seven days.

Alternatively, open `FitnessFlow.xcodeproj` in Xcode, select a signing team, and export an archive using **Product → Archive**.

### Build without a Mac using GitHub Actions

Push the **contents** of this project folder to a GitHub repository, then open **Actions → Build unsigned iPhone IPA → Run workflow**. The workflow runs on a macOS runner and exposes an artifact named `FitnessFlow-unsigned-ipa`. Download that artifact and pass its included `FitnessFlow-unsigned.ipa` (not the source-project ZIP) to your sideload tool.

An IPA is valid only when its archive root contains `Payload/FitnessFlow.app/`. The source download intentionally does not contain that directory, because it has not yet been compiled for iPhone.

The app stores its demo data locally in `UserDefaults`; no data is uploaded. The barcode scanner only reads the code. A production nutrition database/API can be connected in `NutritionView`.

## Features included

- 3 / 4 / 5 day hypertrophy plans with muscle-group focus
- Live workout logging, rest timer, session duration, volume and calorie estimate
- Cardio entries and calorie estimates
- Food and macro diary, natural language food parsing, manual adjustment and barcode scanning
- Exercise library by muscle group
- Progress overview and local AI-style plan / training assistant
- System Light/Dark appearance
