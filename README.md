# MathPull

**Solve fast. Pull the rope.**

MathPull is a maths tug-of-war game for everyone: school kids and adults.
Two teams (or you against a bot) answer maths questions, and every right answer
pulls the rope toward your side.

- Android: built and tested (Play Store release in preparation)
- Web: builds with Flutter; live deploy planned
- iOS: planned (needs a Mac)

Package name: `mathpull` · Android application ID: `com.farooqbuilds.mathpull`

## How to play

1. Pick the players (2 Players or vs Bot), the operation, the game mode and the difficulty.
2. Answer questions on your calculator. Each right answer pulls the rope one step toward you.
3. Three right answers in a row make you "on fire": your next right answer pulls double.
4. Win by pulling the rope far enough (6, 8 or 12 pulls ahead), or by having more points when the time runs out.

### Modes

| Mode | What happens |
|------|--------------|
| **Classic** | Each team has its own question and answers at its own pace |
| **Speed Race** | One shared question; the first right answer scores |

### Options

- **Players:** 2 Players on one screen, or vs Bot (Easy, Medium, Hard)
- **Operations:** addition, subtraction, multiplication, division, or mixed
- **Difficulty:** Easy, Medium, Hard (the size of the numbers and tables)
- **Round length:** 45, 60 or 90 seconds
- **Pulls to win instantly:** 6, 8 or 12

On a tall screen two players sit face to face (the top calculator is upside down).
With a bot there is one calculator at the bottom. In landscape the calculators sit on the two sides.

## Built with

- [Flutter](https://flutter.dev) 3.47 (Dart 3.13) and the [Flame](https://flame-engine.org) game engine for the arena
- `audioplayers` for sound and music, `shared_preferences` to remember the music and sound switches
- Fonts: Fredoka and Nunito, bundled in `assets/google_fonts` (no downloads at run time)
- All sound effects and music are original (see below)

## Project structure

```
lib/
├── main.dart
├── core/
│   ├── constants/app_constants.dart   # game rules, layout sizes, texts
│   ├── layout/adaptive_layout.dart    # scales the UI to any screen
│   └── services/                      # sound_service, music_service, audio_settings
├── game/
│   ├── game_controller.dart           # all rules of one round (and the bot)
│   ├── tug_of_war_game.dart           # Flame game
│   └── rope_component.dart            # the arena, rope and characters
├── models/                            # game_settings, question generator
├── screens/                           # start_screen, game_screen, about_screen
├── theme/app_theme.dart               # colors, text styles, spacing, background
└── widgets/                           # panels, numpad, overlays, buttons, confetti
test/                                  # unit tests (rules, questions, bot)
assets/
├── audio/                             # sfx (.wav) and music (.ogg)
├── google_fonts/                      # Fredoka and Nunito
└── licenses/                          # font license texts
tools/make_audio.py                    # generates the audio
```

## Set up and run

```powershell
flutter doctor
flutter pub get
flutter run                 # a connected phone or emulator
flutter run -d chrome       # web
flutter run --release       # test the real speed on a phone
```

## Tests and checks

```powershell
flutter analyze
flutter test
```

The tests cover the question generator, the game rules (streak and double pull,
match point, instant win, Speed Race, timer, pause) and the bot.

## Build for release

```powershell
flutter build appbundle     # Android (Play Store)
flutter build apk           # Android (installable file)
flutter build web           # web (output in build/web)
```

The upload keystore (`key.properties` and the `.jks` file) is never committed. Keep a backup of it.

## Audio

All sound effects and both music loops are original and are made by code, not
by recording or sampling. To regenerate them (needs Python 3, `numpy` and `ffmpeg`):

```powershell
pip install numpy
python tools/make_audio.py
```

This rewrites `assets/audio/sfx/*.wav` and `assets/audio/music/*.ogg`.

## Credits and licenses

See [CREDITS.md](CREDITS.md). The open-source licenses are also shown inside the app
(start screen, "About & licenses").

## Copyright

© 2026 FarooqBuilds. All rights reserved.