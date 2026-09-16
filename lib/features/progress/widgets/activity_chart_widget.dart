import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/analytics_data_model.dart';

class ActivityChartWidget extends StatelessWidget {
  final List<DailyActivityPoint> dailyPoints;

  const ActivityChartWidget({
    super.key,
    required this.dailyPoints,
  });

  @override
  Widget build(BuildContext context) {
    // Pick the last 7 points if more are provided so bars fit gracefully
    final displayPoints = dailyPoints.length > 7
        ? dailyPoints.sublist(dailyPoints.length - 7)
        : dailyPoints;

    return AppCard(
      gradient: AppColors.cardGradient,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Activity',
                style: AppTypography.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Text(
                  'Habits Completed',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH24,
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: displayPoints.map((point) {
                final ratio = point.taskCompletionRatio;
                final barHeight = (ratio * 80).clamp(6.0, 80.0);
                final isToday = point == displayPoints.last;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${point.tasksCompleted}',
                          style: AppTypography.labelSmall.copyWith(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                        AppSpacing.gapH4,
                        Container(
                          height: barHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: ratio > 0
                                ? LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.6),
                                      isToday
                                          ? AppColors.primary
                                          : AppColors.secondary,
                                    ],
                                  )
                                : null,
                            color: ratio == 0
                                ? AppColors.surfaceHighlight
                                : null,
                            borderRadius: AppRadius.radiusSm,
                            boxShadow: isToday && ratio > 0
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryGlow,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        AppSpacing.gapH8,
                        Text(
                          point.dayName,
                          style: AppTypography.caption.copyWith(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textTertiary,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
