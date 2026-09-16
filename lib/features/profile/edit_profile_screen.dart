import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../data/models/user_profile_model.dart';
import 'profile_provider.dart';
import '../tasks/tasks_provider.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/primary_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  late FitnessLevel _fitnessLevel;
  late PrimaryGoal _primaryGoal;
  late int _dailyStepGoal;
  late int _preferredWorkoutDuration;

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final profile = ref.read(userProfileNotifierProvider).valueOrNull;
      _nameController = TextEditingController(text: profile?.name ?? '');
      _ageController = TextEditingController(text: '${profile?.age ?? 25}');
      _heightController =
          TextEditingController(text: '${profile?.height.toInt() ?? 175}');
      _weightController =
          TextEditingController(text: '${profile?.weight.toInt() ?? 70}');

      _fitnessLevel = profile?.fitnessLevel ?? FitnessLevel.beginner;
      _primaryGoal = profile?.primaryGoal ?? PrimaryGoal.getFit;
      _dailyStepGoal = profile?.dailyStepGoal ?? 6000;
      _preferredWorkoutDuration = profile?.preferredWorkoutDuration ?? 10;

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final currentProfile =
          ref.read(userProfileNotifierProvider).valueOrNull;
      final now = DateTime.now();

      final updatedProfile = (currentProfile ??
              UserProfile(
                id: 'user_${now.millisecondsSinceEpoch}',
                name: _nameController.text.trim(),
                age: int.parse(_ageController.text.trim()),
                height: double.parse(_heightController.text.trim()),
                weight: double.parse(_weightController.text.trim()),
                fitnessLevel: _fitnessLevel,
                primaryGoal: _primaryGoal,
                dailyStepGoal: _dailyStepGoal,
                preferredWorkoutDuration: _preferredWorkoutDuration,
                createdAt: now,
                updatedAt: now,
              ))
          .copyWith(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        height: double.parse(_heightController.text.trim()),
        weight: double.parse(_weightController.text.trim()),
        fitnessLevel: _fitnessLevel,
        primaryGoal: _primaryGoal,
        dailyStepGoal: _dailyStepGoal,
        preferredWorkoutDuration: _preferredWorkoutDuration,
        updatedAt: now,
      );

      await ref
          .read(userProfileNotifierProvider.notifier)
          .saveProfile(updatedProfile);

      // Refresh today's tasks if step goal changed
      await ref.read(todayTasksNotifierProvider.notifier).loadTodayTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personal Details', style: AppTypography.headlineMedium),
              AppSpacing.gapH16,
              // Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: AppTypography.titleMedium,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: AppRadius.radiusLg),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              AppSpacing.gapH16,
              // Age, Height, Weight Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        suffixText: 'yrs',
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.radiusLg,
                        ),
                      ),
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val < 12 || val > 110) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,1}'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Height',
                        suffixText: 'cm',
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.radiusLg,
                        ),
                      ),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val < 80 || val > 250) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,1}'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Weight',
                        suffixText: 'kg',
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.radiusLg,
                        ),
                      ),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val < 30 || val > 300) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH24,
              Text('Fitness Level', style: AppTypography.headlineMedium),
              AppSpacing.gapH12,
              ...FitnessLevel.values.map((lvl) {
                final isSelected = _fitnessLevel == lvl;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm8),
                  child: AppCard(
                    onTap: () => setState(() => _fitnessLevel = lvl),
                    borderColor:
                        isSelected ? AppColors.primary : AppColors.border,
                    backgroundColor: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surface,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          lvl.icon,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        AppSpacing.gapW12,
                        Text(
                          lvl.displayName,
                          style: AppTypography.titleMedium.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              AppSpacing.gapH24,
              Text('Primary Goal', style: AppTypography.headlineMedium),
              AppSpacing.gapH12,
              ...PrimaryGoal.values.map((g) {
                final isSelected = _primaryGoal == g;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm8),
                  child: AppCard(
                    onTap: () => setState(() => _primaryGoal = g),
                    borderColor:
                        isSelected ? AppColors.primary : AppColors.border,
                    backgroundColor: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surface,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          g.icon,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        AppSpacing.gapW12,
                        Text(
                          g.displayName,
                          style: AppTypography.titleMedium.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              AppSpacing.gapH24,
              Text('Daily Step Target', style: AppTypography.headlineMedium),
              AppSpacing.gapH12,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [2000, 4000, 6000, 8000, 10000].map((steps) {
                  final isSelected = _dailyStepGoal == steps;
                  return ChoiceChip(
                    label: Text('$steps steps'),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.background
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _dailyStepGoal = steps);
                    },
                  );
                }).toList(),
              ),
              AppSpacing.gapH24,
              Text(
                'Preferred Daily Workout',
                style: AppTypography.headlineMedium,
              ),
              AppSpacing.gapH12,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [5, 10, 20, 30, 45].map((mins) {
                  final isSelected = _preferredWorkoutDuration == mins;
                  return ChoiceChip(
                    label: Text('$mins mins'),
                    selected: isSelected,
                    selectedColor: AppColors.secondary,
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.background
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _preferredWorkoutDuration = mins);
                      }
                    },
                  );
                }).toList(),
              ),
              AppSpacing.gapH40,
              PrimaryButton(
                text: 'Save Changes',
                isLoading: _isSaving,
                onPressed: _saveChanges,
              ),
              AppSpacing.gapH32,
            ],
          ),
        ),
      ),
    );
  }
}
