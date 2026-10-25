// 📁 FILE: lib/widgets/daily_pull_card.dart
// 📌 WHAT: "Daily Pull" card: the 7 days of this week (a gold tick for each day played) and the reminder bell
import 'package:flutter/material.dart';

import '../core/reminder/play_log.dart';
import '../core/reminder/reminder_format.dart';
import '../core/reminder/reminder_manager.dart';
import '../theme/app_theme.dart';
import 'chunky_button.dart';
import 'reminder_sheet.dart';

/// Shows how many days this week the player finished a game. There is no
/// streak to lose: when a new week starts, the row starts empty again.
class DailyPullCard extends StatelessWidget {
  const DailyPullCard({super.key});

  static const String _title = 'Daily Pull';
  static const String _bellLabel = 'Daily reminder settings';
  static const double _dotSize = 28;
  static const double _bellSize = 36;
  static const Color _buttonEdge = Color(0xFFB7C7E2);

  Widget _circle({
    required Color color,
    required Widget child,
    Color? borderColor,
    double borderWidth = 0,
  }) {
    return Container(
      width: _dotSize,
      height: _dotSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor, width: borderWidth),
      ),
      child: child,
    );
  }

  Widget _letter(int index, Color color) {
    return Text(
      ReminderFormat.weekdayLetters[index],
      style: AppText.number(size: 12, color: color),
    );
  }

  /// One day of the week: gold tick (played), ring (today), soft circle
  /// (past or future day without a game).
  Widget _dot(WeekDot dot, int index) {
    final String state;
    final Widget face;

    if (dot.played) {
      state = 'played';
      face = _circle(
        color: AppColors.gold,
        child: const Icon(
          Icons.check_rounded,
          size: 18,
          color: AppColors.onGold,
        ),
      );
    } else if (dot.isToday) {
      state = 'today, not played yet';
      face = _circle(
        color: AppColors.surface,
        borderColor: AppColors.team1,
        borderWidth: 3,
        child: _letter(index, AppColors.team1),
      );
    } else if (dot.isFuture) {
      state = 'coming up';
      face = _circle(
        color: AppColors.surface.withValues(alpha: 0.7),
        child: _letter(index, AppColors.inkFaint),
      );
    } else {
      state = 'not played';
      face = _circle(
        color: AppColors.backgroundDeep,
        child: _letter(index, AppColors.inkFaint),
      );
    }

    return Semantics(
      label: '${ReminderFormat.weekdayNames[index]}, $state',
      excludeSemantics: true,
      child: face,
    );
  }

  /// The reminder time (when on) and the round bell button.
  Widget _bell(BuildContext context, ReminderManager manager) {
    final settings = manager.settings;
    final enabled = settings.enabled;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (enabled)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              ReminderFormat.time(settings.hour, settings.minute),
              style: AppText.body(
                size: AppText.sizeCaption,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        Tooltip(
          message: _bellLabel,
          child: SizedBox(
            width: _bellSize,
            height: _bellSize,
            child: ChunkyButton(
              semanticLabel: _bellLabel,
              color: enabled ? AppColors.team1Light : AppColors.surface,
              edgeColor: _buttonEdge,
              borderColor: AppColors.border,
              radius: _bellSize / 2,
              depth: 3,
              onTap: () => showReminderSheet(context),
              child: Icon(
                enabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                size: 20,
                color: enabled ? AppColors.team1 : AppColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = ReminderManager.instance;

    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        final dots = manager.weekDots;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.45),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _title,
                            style: AppText.heading(size: AppText.sizeSmall),
                          ),
                          TextSpan(
                            text:
                                '  ${ReminderFormat.weekSummary(manager.daysPlayedThisWeek)}',
                            style: AppText.body(
                              size: AppText.sizeCaption,
                              weight: FontWeight.w600,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (manager.isSupported) _bell(context, manager),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  for (var i = 0; i < dots.length; i++)
                    Expanded(child: Center(child: _dot(dots[i], i))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}