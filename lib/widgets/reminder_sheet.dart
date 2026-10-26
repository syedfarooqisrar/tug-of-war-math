// 📁 FILE: lib/widgets/reminder_sheet.dart
// 📌 WHAT: Bottom sheet for the daily reminder settings (opened with the bell button)
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

/// The white sticker sheet.
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
        final enabled = _manager.looksOn;

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
