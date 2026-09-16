import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../data/models/user_profile_model.dart';
import '../profile/profile_provider.dart';
import '../tasks/tasks_provider.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';

class PersonalizationScreen extends ConsumerStatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  ConsumerState<PersonalizationScreen> createState() =>
      _PersonalizationScreenState();
}

class _PersonalizationScreenState extends ConsumerState<PersonalizationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 7; // Steps 0 to 6

  // Form State Values
  String _name = '';
  int _age = 24;
  double _height = 175.0; // cm
  double _weight = 70.0; // kg
  FitnessLevel _fitnessLevel = FitnessLevel.beginner;
  PrimaryGoal _primaryGoal = PrimaryGoal.getFit;
  int _dailyStepGoal = 6000;
  int _preferredWorkoutDuration = 10; // mins

  bool _isSaving = false;

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController =
      TextEditingController(text: '24');
  final TextEditingController _heightController =
      TextEditingController(text: '175');
  final TextEditingController _weightController =
      TextEditingController(text: '70');
  final TextEditingController _customStepsController = TextEditingController();

  final _nameFormKey = GlobalKey<FormState>();
  final _basicInfoFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _customStepsController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep == 0) {
      if (!_nameFormKey.currentState!.validate()) return;
      _name = _nameController.text.trim();
    } else if (_currentStep == 1) {
      if (!_basicInfoFormKey.currentState!.validate()) return;
      _age = int.tryParse(_ageController.text.trim()) ?? 24;
      _height = double.tryParse(_heightController.text.trim()) ?? 175.0;
      _weight = double.tryParse(_weightController.text.trim()) ?? 70.0;
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goToPreviousStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _completeJourney() async {
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final profile = UserProfile(
        id: 'user_${now.millisecondsSinceEpoch}',
        name: _name.isNotEmpty ? _name : 'Athlete',
        age: _age,
        height: _height,
        weight: _weight,
        fitnessLevel: _fitnessLevel,
        primaryGoal: _primaryGoal,
        dailyStepGoal: _dailyStepGoal,
        preferredWorkoutDuration: _preferredWorkoutDuration,
        createdAt: now,
        updatedAt: now,
      );

      // Save profile to local storage & Riverpod state
      await ref.read(userProfileNotifierProvider.notifier).saveProfile(profile);

      // Trigger initial daily tasks generation
      await ref.read(todayTasksNotifierProvider.notifier).loadTodayTasks();

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (Back button, Progress indicator, Step Label)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg16,
                vertical: AppSpacing.sm8,
              ),
              child: Row(
                children: [
                  if (_currentStep > 0 && _currentStep < _totalSteps - 1)
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: _goToPreviousStep,
                    )
                  else
                    const SizedBox(width: 48, height: 48),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _currentStep == _totalSteps - 1
                              ? 'Summary'
                              : 'Step ${_currentStep + 1} of ${_totalSteps - 1}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        AppSpacing.gapH8,
                        ClipRRect(
                          borderRadius: AppRadius.radiusPill,
                          child: LinearProgressIndicator(
                            value: (_currentStep + 1) / _totalSteps,
                            backgroundColor: AppColors.surfaceHighlight,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48, height: 48),
                ],
              ),
            ),

            // Page Slides
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                children: [
                  _buildNameStep(),
                  _buildBasicInfoStep(),
                  _buildFitnessLevelStep(),
                  _buildPrimaryGoalStep(),
                  _buildDailyActivityGoalStep(),
                  _buildWorkoutPreferenceStep(),
                  _buildReadyStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Name
  Widget _buildNameStep() {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Form(
        key: _nameFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.gapH16,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.gapH24,
            Text("Let's get to know you.", style: AppTypography.displaySmall),
            AppSpacing.gapH8,
            Text(
              "What should Habitude call you?",
              style: AppTypography.bodyMedium,
            ),
            AppSpacing.gapH32,
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: AppTypography.headlineMedium,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'e.g. Krishna',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.radiusLg,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.radiusLg,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.radiusLg,
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name.';
                }
                if (value.trim().length > 30) {
                  return 'Name must be 30 characters or fewer.';
                }
                return null;
              },
            ),
            AppSpacing.gapH40,
            PrimaryButton(text: 'Continue', onPressed: _goToNextStep),
          ],
        ),
      ),
    );
  }

  // STEP 2: Basic Info (Age, Height, Weight)
  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Form(
        key: _basicInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.gapH16,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.straighten_rounded,
                size: 28,
                color: AppColors.secondary,
              ),
            ),
            AppSpacing.gapH24,
            Text("Basic Information", style: AppTypography.displaySmall),
            AppSpacing.gapH8,
            Text(
              "Used to personalize your movement pace and habit loads.",
              style: AppTypography.bodyMedium,
            ),
            AppSpacing.gapH24,
            // Age
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTypography.titleLarge,
              decoration: InputDecoration(
                labelText: 'Age (Years)',
                suffixText: 'yrs',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.radiusLg,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              validator: (value) {
                final v = int.tryParse(value ?? '');
                if (v == null || v < 12 || v > 110) {
                  return 'Please enter a realistic age between 12 and 110.';
                }
                return null;
              },
            ),
            AppSpacing.gapH16,
            // Height
            TextFormField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              style: AppTypography.titleLarge,
              decoration: InputDecoration(
                labelText: 'Height',
                suffixText: 'cm',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.radiusLg,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              validator: (value) {
                final v = double.tryParse(value ?? '');
                if (v == null || v < 80 || v > 250) {
                  return 'Please enter a valid height (80 - 250 cm).';
                }
                return null;
              },
            ),
            AppSpacing.gapH16,
            // Weight
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              style: AppTypography.titleLarge,
              decoration: InputDecoration(
                labelText: 'Weight',
                suffixText: 'kg',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.radiusLg,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              validator: (value) {
                final v = double.tryParse(value ?? '');
                if (v == null || v < 30 || v > 300) {
                  return 'Please enter a valid weight (30 - 300 kg).';
                }
                return null;
              },
            ),
            AppSpacing.gapH32,
            PrimaryButton(text: 'Continue', onPressed: _goToNextStep),
          ],
        ),
      ),
    );
  }

  // STEP 3: Fitness Level
  Widget _buildFitnessLevelStep() {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.gapH16,
          Text("Where are you right now?", style: AppTypography.displaySmall),
          AppSpacing.gapH8,
          Text(
            "Select your current workout and baseline activity level.",
            style: AppTypography.bodyMedium,
          ),
          AppSpacing.gapH24,
          ...FitnessLevel.values.map((level) {
            final isSelected = _fitnessLevel == level;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md12),
              child: AppCard(
                onTap: () {
                  setState(() => _fitnessLevel = level);
                },
                borderColor: isSelected ? AppColors.primary : AppColors.border,
                backgroundColor: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surface,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.surfaceElevated,
                        borderRadius: AppRadius.radiusMd,
                      ),
                      child: Icon(
                        level.icon,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                    AppSpacing.gapW16,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level.displayName,
                            style: AppTypography.titleMedium.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          AppSpacing.gapH4,
                          Text(
                            level.description,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                  ],
                ),
              ),
            );
          }),
          AppSpacing.gapH24,
          PrimaryButton(text: 'Continue', onPressed: _goToNextStep),
        ],
      ),
    );
  }

  // STEP 4: Primary Goal
  Widget _buildPrimaryGoalStep() {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.gapH16,
          Text(
            "What are you working toward?",
            style: AppTypography.displaySmall,
          ),
          AppSpacing.gapH8,
          Text(
            "Choose your primary focus to shape your daily habits.",
            style: AppTypography.bodyMedium,
          ),
          AppSpacing.gapH20,
          ...PrimaryGoal.values.map((goal) {
            final isSelected = _primaryGoal == goal;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md12),
              child: AppCard(
                onTap: () {
                  setState(() => _primaryGoal = goal);
                },
                borderColor: isSelected ? AppColors.primary : AppColors.border,
                backgroundColor: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surface,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.surfaceElevated,
                        borderRadius: AppRadius.radiusMd,
                      ),
                      child: Icon(
                        goal.icon,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                    AppSpacing.gapW16,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.displayName,
                            style: AppTypography.titleMedium.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          AppSpacing.gapH4,
                          Text(
                            goal.description,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
          AppSpacing.gapH24,
          PrimaryButton(text: 'Continue', onPressed: _goToNextStep),
        ],
      ),
    );
  }

  // STEP 5: Daily Activity Goal (Steps)
  Widget _buildDailyActivityGoalStep() {
    const presets = [2000, 4000, 6000, 8000, 10000];

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.gapH16,
          Text("Daily Activity Goal", style: AppTypography.displaySmall),
          AppSpacing.gapH8,
          Text(
            "Select your initial target for daily walking and movement.",
            style: AppTypography.bodyMedium,
          ),
          AppSpacing.gapH24,
          ...presets.map((steps) {
            final isSelected = _dailyStepGoal == steps;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md12),
              child: AppCard(
                onTap: () {
                  setState(() => _dailyStepGoal = steps);
                },
                borderColor: isSelected ? AppColors.primary : AppColors.border,
                backgroundColor: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_walk_rounded,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                        AppSpacing.gapW16,
                        Text(
                          '$steps steps / day',
                          style: AppTypography.titleMedium.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
          AppSpacing.gapH24,
          PrimaryButton(text: 'Continue', onPressed: _goToNextStep),
        ],
      ),
    );
  }

  // STEP 6: Workout Preference (Duration)
  Widget _buildWorkoutPreferenceStep() {
    const durations = [5, 10, 20, 30, 45];

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.gapH16,
          Text("Workout Preference", style: AppTypography.displaySmall),
          AppSpacing.gapH8,
          Text(
            "How much time can you realistically invest daily?",
            style: AppTypography.bodyMedium,
          ),
          AppSpacing.gapH24,
          ...durations.map((mins) {
            final isSelected = _preferredWorkoutDuration == mins;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md12),
              child: AppCard(
                onTap: () {
                  setState(() => _preferredWorkoutDuration = mins);
                },
                borderColor: isSelected ? AppColors.primary : AppColors.border,
                backgroundColor: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                        AppSpacing.gapW16,
                        Text(
                          '$mins minutes',
                          style: AppTypography.titleMedium.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
          AppSpacing.gapH24,
          PrimaryButton(text: 'Continue', onPressed: _goToNextStep),
        ],
      ),
    );
  }

  // STEP 7: Ready Screen (Summary)
  Widget _buildReadyStep() {
    final displayName = _name.trim().isNotEmpty ? _name.trim() : 'Athlete';

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppSpacing.gapH24,
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGlow,
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
          ),
          AppSpacing.gapH24,
          Text(
            "You're all set, $displayName.",
            style: AppTypography.displaySmall,
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapH8,
          Text(
            "Your personalized Habitude journey starts today.",
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapH32,
          // Summary Card
          AppCard(
            gradient: AppColors.cardGradient,
            padding: AppSpacing.cardPadding,
            child: Column(
              children: [
                _buildSummaryRow(
                  label: 'Primary Goal',
                  value: _primaryGoal.displayName,
                  icon: _primaryGoal.icon,
                ),
                const Divider(height: 24, color: AppColors.border),
                _buildSummaryRow(
                  label: 'Fitness Level',
                  value: _fitnessLevel.displayName,
                  icon: _fitnessLevel.icon,
                ),
                const Divider(height: 24, color: AppColors.border),
                _buildSummaryRow(
                  label: 'Daily Step Goal',
                  value: '$_dailyStepGoal steps',
                  icon: Icons.directions_walk_rounded,
                ),
                const Divider(height: 24, color: AppColors.border),
                _buildSummaryRow(
                  label: 'Daily Workout',
                  value: '$_preferredWorkoutDuration mins',
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
          ),
          AppSpacing.gapH40,
          PrimaryButton(
            text: 'Start My Journey',
            icon: Icons.arrow_forward_rounded,
            isLoading: _isSaving,
            onPressed: _completeJourney,
          ),
          AppSpacing.gapH16,
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadius.radiusSm,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        AppSpacing.gapW16,
        Text(label, style: AppTypography.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}
