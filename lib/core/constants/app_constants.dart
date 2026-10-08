/// Game rules and tuning values. Change a number here and it updates
/// everywhere in the app.
class GameConfig {
  GameConfig._();

  // Defaults shown on the start screen
  static const int defaultMaxTable = 10;
  static const int defaultRoundSeconds = 60;
  static const int defaultWinPulls = 8;

  // Choices offered on the start screen
  static const List<int> tableOptions = [5, 10, 12];
  static const List<int> roundSecondOptions = [45, 60, 90];
  static const List<int> winPullOptions = [6, 8, 12];

  // Question rules
  static const int maxMultiplier = 10;

  // Input rules
  static const int maxAnswerDigits = 3;

  // Timer
  static const int urgentSecondsThreshold = 10;
  
  // Countdown shown before every round (3, 2, 1, GO!)
  static const int countdownSeconds = 3;
}

/// Sizes used by the game board layout.
class LayoutConstants {
  LayoutConstants._();

  // Game board (design units; the whole UI is scaled to fit the screen)
  static const double boardMaxWidth = 900;
  static const double boardMaxHeight = 460;
  static const double panelGap = 12;
  static const double cardRadius = 24;
  static const double startCardWidth = 420;

  // The title is hidden when there is less height than this
  static const double titleMinHeight = 520;

  // Adaptive scaling: the UI is designed at a reference size and then
  // scaled up or down to fit the real screen.
  static const double landscapeRefWidth = 940;
  static const double landscapeRefHeight = 580;
  static const double portraitRefWidth = 420;
  static const double portraitRefHeight = 820;
  static const double minUiScale = 0.85;
  static const double maxUiScale = 4.0;
}

/// Every text shown to the player. Later we will replace these with
/// proper translations (English, Urdu, Turkish).
class AppStrings {
  AppStrings._();

  static const String appTitle = 'Tug of War: Mathematics';
  static const String tagline = 'Two teams race to solve tables and pull the rope!';

  static const String timesTables = 'Times tables';
  static const String roundLength = 'Round length';
  static const String pullsToWin = 'Pulls to win instantly';
  static const String startGame = 'Start Game';

  static const String team1 = 'Team 1';
  static const String team2 = 'Team 2';

  static const String tieTitle = "It's a Tie!";
  static const String tieSubtitle = 'Evenly matched — run it back!';
  static const String winSubtitle = 'Great tug-of-war battle!';
  static const String backToMenu = 'Back to menu';
  static const String getReady = 'Get ready!';
  static const String go = 'GO!';
  static const String paused = 'Paused';
  static const String resume = 'Resume';
  static const String quitGame = 'Quit game';
}

/// Sound files, relative to the assets/ folder.
class SoundAssets {
  SoundAssets._();

  static const String correct = 'sounds/correct.wav';
  static const String wrong = 'sounds/wrong.wav';
  static const String tick = 'sounds/tick.wav';
  static const String go = 'sounds/go.wav';
  static const String win = 'sounds/win.wav';
}