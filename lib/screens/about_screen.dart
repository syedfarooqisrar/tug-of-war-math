// 📁 FILE: lib/screens/about_screen.dart   (NEW FILE)
// 📌 WHAT: About screen: who made the game, sound and font credits, and the open-source licenses page
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';

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
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ChunkyButton(
              semanticLabel: _licensesButton,
              color: AppColors.surface,
              edgeColor: _buttonEdge,
              borderColor: AppColors.border,
              radius: AppRadius.md,
              onTap: _openLicenses,
              child: Text(_licensesButton, style: AppText.body(size: 15)),
            ),
          ),
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
