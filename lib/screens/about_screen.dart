// 📁 FILE: lib/screens/about_screen.dart
// 📌 WHAT: About screen: credits, open-source licenses and the in-app privacy policy
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';

// ---------------------------------------------------------------------------
// Privacy policy text. Keep it identical to web/privacy.html.
// ---------------------------------------------------------------------------
const String _privacyTitle = 'Privacy policy';
const String _privacyUpdated = 'Last updated: 26 October 2026';
const String _privacyCloseLabel = 'Close';

const List<(String, String)> _privacySections = [
  (
    'In short',
    'MathPull does not collect, store on a server, share or sell any personal '
        'information. It has no ads, no accounts and no analytics. The Android '
        'app can show one friendly reminder a day, and it does this entirely on '
        'your phone.',
  ),
  (
    'Who we are',
    'MathPull (Android package com.farooqbuilds.mathpull) is a maths '
        'tug-of-war game for two players or one player against a computer bot. '
        'It is developed by Syed Farooq Israr (FarooqBuilds).',
  ),
  (
    'What information we collect',
    'None. MathPull does not ask you to create an account or sign in, and it '
        'does not ask for your name, email address, age, location, contacts, '
        'photos, microphone or camera. It does not use advertising, analytics, '
        'crash reporting or any other third-party tracking service.',
  ),
  (
    'Daily reminder (Android)',
    'The Android app can remind you to play with one friendly notification a '
        'day. The reminder is on by default at 5:00 PM. When you open MathPull '
        'for the first time on Android 13 or newer, Android asks whether '
        'MathPull may show notifications. If you say no, no reminders are '
        'shown.\n\n'
        'The reminder is created and shown by your phone itself. It does not '
        'use the internet, a server or an account. It is shown at most once a '
        'day, only between 8 AM and 8 PM, it is skipped on a day when you '
        'already played, and it stops by itself if you do not open the app for '
        'a week. You can turn it off at any time with the bell button on the '
        'start screen, or in your phone’s notification settings.',
  ),
  (
    'What stays on your device',
    'MathPull remembers your sound and music choices, whether the daily '
        'reminder is on and at what time, and on which days you finished a game '
        '(the days are used to show your week in the Daily Pull row and are '
        'kept for 60 days). These small settings are saved on your own device '
        '(in the Android app, in the app’s private storage; in the web '
        'version, in your browser’s local storage). They are never sent '
        'anywhere. Game scores and questions are used only while a match is '
        'running and are not saved.',
  ),
  (
    'Permissions (Android)',
    'The Android app uses the permissions that notifications need: to show '
        'them, to bring the reminder back after the phone restarts, and for the '
        'standard notification vibration. It does not ask for the internet, '
        'location, contacts, camera, microphone, photos or files.',
  ),
  (
    'Internet access',
    'The Android app works fully offline and does not request internet '
        'permission, so it cannot send data to us or anyone else. The optional '
        'web version is delivered by our hosting provider (Cloudflare). Like '
        'any website, the hosting provider may process technical data such as '
        'your IP address in order to deliver the pages. We do not receive or '
        'use that data for any other purpose. The web version does not show '
        'reminders.',
  ),
  (
    'Children',
    'MathPull is designed to be suitable for everyone, including children aged '
        '6 and over. Because the app collects no personal information from '
        'anyone, it collects none from children either. The daily reminder is '
        'gentle: one a day, never at night, with no pressure messages, and it '
        'can be turned off with one tap. The app contains no ads, no links '
        'that lead out of the app, no chat and no social features.',
  ),
  (
    'Third parties and sharing',
    'We do not share, sell or disclose any information to third parties, '
        'because we do not collect any.',
  ),
  (
    'Fonts and audio',
    'The fonts (Fredoka and Nunito) and all music and sound effects are '
        'bundled inside the app. Nothing is downloaded while you play.',
  ),
  (
    'Changes to this policy',
    'If the app ever changes in a way that affects your privacy, we will '
        'update this policy and the date above before releasing that version.',
  ),
  (
    'Contact',
    'Questions about this policy? Email farooqbuilds@gmail.com.',
  ),
];

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const String _screenTitle = 'About';
  static const String _madeBy = 'Made by FarooqBuilds';
  static const String _soundTitle = 'Sound and music';
  static const String _soundBody =
      'All sound effects and music in MathPull are original and were made '
      'for this game.';
  static const String _fontsTitle = 'Fonts';
  static const String _fontsBody =
      'Fredoka and Nunito, used under the SIL Open Font License 1.1.';
  static const String _builtTitle = 'Built with';
  static const String _builtBody = 'Flutter and the Flame game engine.';
  static const String _licensesButton = 'Open-source licenses';
  static const String _backLabel = 'Back';

  /// The license texts of the two bundled fonts (name, asset path).
  static const Map<String, String> _fontLicenses = {
    'Fredoka': 'assets/licenses/OFL-Fredoka.txt',
    'Nunito': 'assets/licenses/OFL-Nunito.txt',
  };

  static const double _maxWidth = 480;
  static const double _backSize = 46;
  static const Color _buttonEdge = Color(0xFFB7C7E2);

  static bool _licensesRegistered = false;

  @override
  void initState() {
    super.initState();
    _registerFontLicenses();
  }

  /// Adds the font licenses to Flutter's license list (once), so they show
  /// up on the "Open-source licenses" page.
  void _registerFontLicenses() {
    if (_licensesRegistered) return;
    _licensesRegistered = true;

    LicenseRegistry.addLicense(() async* {
      for (final entry in _fontLicenses.entries) {
        try {
          final text = await rootBundle.loadString(entry.value);
          yield LicenseEntryWithLineBreaks([entry.key], text);
        } catch (_) {
          // The file is missing: skip it instead of breaking the page.
        }
      }
    });
  }

  void _openLicenses() {
    showLicensePage(
      context: context,
      applicationName: AppStrings.appTitle,
      applicationLegalese: _madeBy,
    );
  }

  void _openPrivacy() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      builder: (_) => const _PrivacySheet(),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.heading(size: AppText.sizeTitle)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: AppText.body(
              size: AppText.sizeSmall,
              weight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ChunkyButton(
        semanticLabel: label,
        color: AppColors.surface,
        edgeColor: _buttonEdge,
        borderColor: AppColors.border,
        radius: AppRadius.md,
        onTap: onTap,
        child: Text(label, style: AppText.body(size: 15)),
      ),
    );
  }

  Widget _card() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          const BoxShadow(color: AppColors.border, offset: Offset(0, 5)),
          ...AppShadows.card,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              AppStrings.appTitle,
              style: AppText.heading(size: AppText.sizeDisplay + 4),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              _madeBy,
              style: AppText.body(
                size: AppText.sizeSmall,
                weight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _section(_soundTitle, _soundBody),
          _section(_fontsTitle, _fontsBody),
          _section(_builtTitle, _builtBody),
          const SizedBox(height: AppSpacing.sm),
          _linkButton(_privacyTitle, _openPrivacy),
          const SizedBox(height: AppSpacing.md),
          _linkButton(_licensesButton, _openLicenses),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FieldBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Tooltip(
                      message: _backLabel,
                      child: SizedBox(
                        width: _backSize,
                        height: _backSize,
                        child: ChunkyButton(
                          semanticLabel: _backLabel,
                          color: AppColors.surface,
                          edgeColor: _buttonEdge,
                          borderColor: AppColors.border,
                          radius: _backSize / 2,
                          depth: 3,
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 22,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _screenTitle,
                      style: AppText.heading(size: AppText.sizeTitle + 2),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _maxWidth),
                      child: _card(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet that shows the full privacy policy text.
class _PrivacySheet extends StatelessWidget {
  const _PrivacySheet();

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _privacyTitle,
                    style: AppText.heading(size: AppText.sizeTitle + 2),
                  ),
                ),
                IconButton(
                  tooltip: _privacyCloseLabel,
                  icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _privacyUpdated,
                    style: AppText.body(
                      size: AppText.sizeSmall,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final section in _privacySections)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.$1,
                            style: AppText.heading(size: AppText.sizeTitle),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            section.$2,
                            style: AppText.body(
                              size: AppText.sizeSmall,
                              weight: FontWeight.w600,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}