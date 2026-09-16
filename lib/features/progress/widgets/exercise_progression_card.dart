import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/analytics_data_model.dart';

class ExerciseProgressionCard extends StatelessWidget {
  final List<ExerciseProgressionSummary> progressions;

  const ExerciseProgressionCard({
    super.key,
    required this.progressions,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              AppSpacing.gapW8,
              Text(
                'Adaptive Target Progression',
                style: AppTypography.titleMedium,
              ),
            ],
          ),
          AppSpacing.gapH4,
          Text(
            'Target growth adjusted based on your real performance.',
            style: AppTypography.bodySmall,
          ),
          AppSpacing.gapH16,
          ...progressions.map((prog) {
            final historyStr = prog.targetHistory.join(' → ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prog.exerciseName,
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppSpacing.gapH4,
                          Text(
                            '$historyStr ${prog.unit}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (prog.growth > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: AppRadius.radiusPill,
                        ),
                        child: Text(
                          '+${prog.growth} ${prog.unit}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
