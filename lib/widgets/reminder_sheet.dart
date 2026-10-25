// 📁 FILE: lib/widgets/reminder_sheet.dart
// 📌 WHAT: Bottom sheets for the daily reminder: the settings sheet (bell button) and the friendly question after a game
import 'package:flutter/material.dart';

import '../core/reminder/reminder_format.dart';
import '../core/reminder/reminder_logic.dart';
import '../core/reminder/reminder_manager.dart';
import '../theme/app_theme.dart';
import 'chunky_button.dart';

const double _sheetMaxWidth = 480;
const Color _chipEdge = Color(0xFFB7C7E2);

/// Opens the reminder settings (on/off, time, "Send a test").
Future<void> showReminderSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: _sheetMaxWidth),
    builder: (_) => const _ReminderSheet(),
  );
}

/// Opens the friendly "Want a daily reminder?" question.
Future<void> showReminderAskSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: _sheetMaxWidth),
    builder: (_) => const _ReminderAskSheet(),
  );
}

/// The white sticker sheet that both screens sit in.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: child,
        ),
      ),
    );
  }
}

Widget _fieldLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppText.body(
          size: AppText.sizeSmall,
          color: AppColors.inkMuted,
        ),
      ),
    ),
  );
}

/// One selectable chip, the same look as the chips on the start screen.
Widget _chip({
  required String label,
  required bool selected,
  required VoidCallback? onTap,
  String? semanticLabel,
}) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        height: 52,
        child: ChunkyButton(
          semanticLabel: semanticLabel ?? label,
          selected: selected,
          color: selected ? AppColors.team1 : AppColors.surface,
          edgeColor: selected ? AppColors.team1Dark : _chipEdge,
          borderColor: selected ? null : AppColors.border,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: AppText.number(
                size: 14,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Settings sheet
// ---------------------------------------------------------------------------

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet();

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  static const String _title = 'Daily reminder';
  static const String _intro =
      'A friendly nudge to play a quick round. It stays on this phone.';
  static const String _onOffLabel = 'Remind me every day';
  static const String _timeLabel = 'Time';
  static const String _testLabel = 'Send a test';
  static const String _doneLabel = 'Done';
  static const String _closeLabel = 'Close';
  static const String _note =
      'No account needed. You can turn the reminder off any time.';
  static const String _testSent = 'Test sent! Look in your notifications.';
  static const String _blocked =
      "Notifications are blocked for MathPull. Allow them in your phone's "
      'Settings, then try again.';

  final ReminderManager _manager = ReminderManager.instance;
  bool _busy = false;
  String? _message;

  Future<void> _setEnabled(bool on) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });

    String? message;
    if (on) {
      final allowed = await _manager.enable();
      if (!allowed) message = _blocked;
    } else {
      await _manager.disable();
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = message;
    });
  }

  Future<void> _pickHour(int hour) async {
    if (_busy) return;
    await _manager.setTime(hour, 0);
  }

  Future<void> _sendTest() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });

    final shown = await _manager.sendTest();

    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = shown ? _testSent : _blocked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        final settings = _manager.settings;
        final enabled = settings.enabled;

        return _SheetFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _title,
                      style: AppText.heading(size: AppText.sizeDisplay - 6),
                    ),
                  ),
                  IconButton(
                    tooltip: _closeLabel,
                    icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                _intro,
                style: AppText.body(
                  size: AppText.sizeSmall,
                  weight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _fieldLabel(_onOffLabel),
              Row(
                children: [
                  _chip(
                    label: 'Off',
                    selected: !enabled,
                    onTap: _busy ? null : () => _setEnabled(false),
                  ),
                  _chip(
                    label: 'On',
                    selected: enabled,
                    onTap: _busy ? null : () => _setEnabled(true),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _fieldLabel(_timeLabel),
              Row(
                children: [
                  for (final hour in ReminderConfig.hourChoices)
                    _chip(
                      label: ReminderFormat.time(hour, 0),
                      selected: enabled && settings.hour == hour,
                      onTap: enabled && !_busy ? () => _pickHour(hour) : null,
                    ),
                ],
              ),
              if (_message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _message!,
                  style: AppText.body(
                    size: AppText.sizeSmall,
                    weight: FontWeight.w600,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ChunkyButton(
                        semanticLabel: _testLabel,
                        color: AppColors.surface,
                        edgeColor: _chipEdge,
                        borderColor: AppColors.border,
                        radius: AppRadius.md,
                        onTap: enabled && !_busy ? _sendTest : null,
                        child: Text(_testLabel, style: AppText.body(size: 15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ChunkyButton(
                        semanticLabel: _doneLabel,
                        color: AppColors.gold,
                        edgeColor: AppColors.goldDark,
                        radius: AppRadius.md,
                        depth: 5,
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          _doneLabel,
                          style: AppText.heading(
                            size: AppText.sizeTitle,
                            color: AppColors.onGold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _note,
                style: AppText.body(
                  size: AppText.sizeCaption,
                  weight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// The friendly question
// ---------------------------------------------------------------------------

class _ReminderAskSheet extends StatefulWidget {
  const _ReminderAskSheet();

  @override
  State<_ReminderAskSheet> createState() => _ReminderAskSheetState();
}

class _ReminderAskSheetState extends State<_ReminderAskSheet> {
  static const String _title = 'Want a daily reminder?';
  static const String _yesLabel = 'Yes, remind me';
  static const String _notNowLabel = 'Not now';
  static const String _declinedHint =
      'No problem! You can turn the reminder on from the bell on the start '
      'screen.';
  static const double _badgeSize = 64;

  final ReminderManager _manager = ReminderManager.instance;
  bool _busy = false;

  Future<void> _yes() async {
    if (_busy) return;
    setState(() => _busy = true);

    // Taken before the awaits, because the sheet may be gone afterwards.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    final allowed = await _manager.enable();
    if (!allowed) await _manager.declineAsk();

    if (mounted) navigator.pop();
    if (!allowed) {
      messenger?.showSnackBar(const SnackBar(content: Text(_declinedHint)));
    }
  }

  Future<void> _notNow() async {
    if (_busy) return;
    setState(() => _busy = true);

    final navigator = Navigator.of(context);
    await _manager.declineAsk();
    if (mounted) navigator.pop();
  }

  Widget _badge() {
    return Container(
      width: _badgeSize,
      height: _badgeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold.withValues(alpha: 0.18),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.55),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.notifications_active_rounded,
        size: _badgeSize * 0.52,
        color: AppColors.gold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _manager.settings;
    final time = ReminderFormat.time(settings.hour, settings.minute);

    return _SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _badge(),
          const SizedBox(height: AppSpacing.md),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: AppText.heading(size: AppText.sizeDisplay - 4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'One friendly nudge a day at $time. It stays on this phone, and '
            'you can turn it off any time.',
            textAlign: TextAlign.center,
            style: AppText.body(
              size: AppText.sizeSmall,
              weight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 62,
            child: ChunkyButton(
              semanticLabel: _yesLabel,
              color: AppColors.gold,
              edgeColor: AppColors.goldDark,
              radius: AppRadius.md,
              depth: 5,
              onTap: _busy ? null : _yes,
              child: Text(
                _yesLabel,
                style: AppText.heading(
                  size: AppText.sizeTitle,
                  color: AppColors.onGold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ChunkyButton(
              semanticLabel: _notNowLabel,
              color: AppColors.surface,
              edgeColor: _chipEdge,
              borderColor: AppColors.border,
              radius: AppRadius.md,
              onTap: _busy ? null : _notNow,
              child: Text(_notNowLabel, style: AppText.body(size: 15)),
            ),
          ),
        ],
      ),
    );
  }
}