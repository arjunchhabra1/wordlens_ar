# WordLens AR 

An iOS assistive-reading app for people with dyslexia. Point the camera at printed or handwritten text and WordLens AR reads it aloud, suggests corrections for misspelled words, and shows a 3D model of the word in augmented reality.

## Features

| Mode | What it does |
| --- | --- |
| **Read** | Fit the scanning box over text, then tap **Speak** to hear it read aloud, or **AR** to place a 3D model of the word in the room. |
| **Write** | Scan a word you wrote. It is checked against a 740k-word dictionary: a correctly spelled word is projected in AR; a misspelled one gets ranked spelling suggestions you can hear read aloud. |
| **Analyze** | A dashboard of reading statistics. Each AR and speech read is logged per day to Firestore. |
| **Onboarding** | Narrated walkthrough of each mode, then Face ID / Touch ID to unlock the app. |

## How it works

- **Text recognition:** Apple's Vision framework (`VNRecognizeTextRequest`) reads the text inside the scanning box from the camera frame.
- **Speech:** `AVSpeechSynthesizer` reads recognized text and spelling suggestions aloud.
- **Augmented reality:** ARKit + SceneKit place the model on a detected plane. Models are hosted on [echo3D](https://www.echo3d.com) and looked up through a Firestore collection (`echo3DModels`) that maps each word to its echo3D entry ID.
- **Autocorrect:** a C/Objective-C module (`autocorrect.m`) loads `dictionary.txt` into a trie for fast exact-match lookup (`isAWord`). For unknown words, it ranks dictionary words by Levenshtein edit distance (up to 4 edits) and returns the 5 closest (`autocorrect`).
- **Data:** Firebase Firestore stores daily usage counts (`Data` collection) and the word-to-model mapping.

## Tech stack

Swift, UIKit + SwiftUI, Objective-C/C, ARKit, SceneKit, Vision, AVFoundation, LocalAuthentication, Firebase (Firestore, Analytics), echo3D, Lottie, SCLAlertView, CocoaPods.

## Project structure

```
WordLensAR/
  ViewController.swift            Read mode: scan, speak, AR placement, usage logging
  WritingViewController.swift     Write mode: handwriting scan + autocorrect
  AutoCorrectViewController.swift Spoken spelling suggestions
  AnalyzeViewController.swift     Hosts the SwiftUI statistics dashboard
  NewSwiftUI.swift                Dashboard views and charts
  OnboardingViewController.swift  Narrated onboarding + biometric sign-in
  Echo3D.swift, Entry.swift       echo3D client (model download and loading)
  autocorrect.m / autocorrect.h   Trie + edit-distance autocorrect
  dictionary.txt                  Word list used by autocorrect
```

## Getting started

**Requirements:** Xcode 14+, iOS 16.2+, a physical iPhone or iPad with ARKit support (the camera and AR features don't work in the Simulator), and CocoaPods.

1. Clone the repo and install pods:
   ```bash
   git clone https://github.com/arjunchhabra1/wordlens_ar.git
   cd wordlens_ar/WordLensAR
   mv Pod_file Podfile
   pod install
   ```
2. Create a Firebase project, add an iOS app with this bundle ID, and place its `GoogleService-Info.plist` in `WordLensAR/`. Enable Firestore.
3. Create an [echo3D](https://www.echo3d.com) project, upload your 3D models, and set your API key in `Echo3D.swift`.
4. In Firestore, add an `echo3DModels` collection with one document per word (document ID = the word) holding that word's echo3D entry ID.
5. Open `WordLensAR.xcworkspace` in Xcode, select your device, and run.

## Notes

- The Analyze dashboard currently plots sample data from `ChartMockData.swift`; usage counts are recorded in Firestore but not yet charted.
- Tapping a spelling suggestion to use it is not wired up yet (`AutoCorrectViewController.swift`); suggestions can be heard but not selected.
- AR models exist only for words mapped in `echo3DModels`.
