# Tug of War: Mathematics (Flutter + Flame)

A 2-team multiplication tug-of-war game. One Flutter codebase, three platforms:
Android, iOS, and Web.

## How this project is organized

```
lib/
├── main.dart                 # App entry point
├── screens/
│   ├── start_screen.dart     # Settings: tables, round length, win threshold
│   └── game_screen.dart      # Main game loop, timer, win/lose logic
├── game/
│   ├── tug_of_war_game.dart  # Flame game class (hosts the rope component)
│   └── rope_component.dart   # Draws the track + moving rope knot
├── models/
│   └── question.dart         # Generates random multiplication questions
└── widgets/
    ├── team_panel.dart       # One team's score/question/input/numpad
    └── numpad.dart           # Reusable 0-9 + clear + submit keypad
```

## Setup

1. Make sure Flutter is installed and working:
   ```
   flutter doctor
   ```
2. Get this folder onto your machine (copy it, or `git init` it as your own repo).
3. Install dependencies:
   ```
   flutter pub get
   ```

## Run it

```
flutter run -d chrome     # Web
flutter run                # Whatever device/emulator is connected
```

## Build for release

```
flutter build apk          # Android
flutter build ios          # iOS (needs Xcode on a Mac)
flutter build web          # Web (output in build/web, deploy to Firebase Hosting, etc.)
```

## Where to extend next

- **Sound effects**: add the `audioplayers` package and play a sound in `_submit()`
  in `game_screen.dart` on correct/incorrect answers.
- **More operations** (+, -, ÷): add an `operation` field to `Question` and branch
  in `Question.random()`.
- **Difficulty levels / AI-adaptive questions**: this is a good place to call an
  AI API (e.g. Groq) to generate or select questions based on how a player is doing.
- **State management**: once you add more screens/features, consider moving from
  `setState` to `Provider` or `Riverpod` for cleaner state handling.
- **Multiplayer over network**: would need a backend (e.g. Firebase Realtime
  Database or Firestore) to sync scores between two devices instead of one shared screen.
