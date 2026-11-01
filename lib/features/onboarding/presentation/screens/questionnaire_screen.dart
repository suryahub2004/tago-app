import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_button.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() =>
      _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final notifier = ref.read(onboardingProvider.notifier);
    final state = ref.read(onboardingProvider);
    if (state.step < 6) {
      notifier.setStep(state.step + 1);
      await _pageController.animateToPage(
        state.step + 1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
      return;
    }
    final user = ref.read(currentUserProvider);
    final profile = HealthProfile(
      deviceType: state.deviceType ?? user?.healthProfile.deviceType,
      onboardingComplete: false,
      fitnessLevel: state.fitnessLevel,
      primaryGoal: state.primaryGoal,
      age: state.age,
    );
    await ref.read(authProvider.notifier).updateHealthProfile(profile);
    
    final profileData = {
      'age': state.age,
      'gender': state.gender,
      'height': state.heightCm, // cm
      'weight': state.weightKg, // kg
      'fitnessLevel': state.fitnessLevel,
      'fitnessGoal': state.primaryGoal,
      'workoutDays': state.activeDays,
      'sleepQuality': state.sleepQuality,
    };
    await ref.read(authProvider.notifier).saveFullHealthProfile(profileData);
    if (!mounted) return;
    context.go('/onboarding/analysis');
  }

  Future<void> _back() async {
    final state = ref.read(onboardingProvider);
    if (state.step == 0) {
      context.pop();
      return;
    }
    ref.read(onboardingProvider.notifier).setStep(state.step - 1);
    await _pageController.animateToPage(
      state.step - 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: LinearProgressIndicator(value: (state.step + 1) / 7),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _StepPersonalInfo(),
                  _StepBodyMetrics(),
                  _StepFitnessGoals(),
                  _StepActivity(),
                  _StepSleep(),
                  _StepLifestyle(),
                  _StepEmergency(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: SvButton(
                label: state.step == 6 ? 'Done' : 'Next',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xl),
        ...children,
      ],
    );
  }
}

class _StepPersonalInfo extends ConsumerWidget {
  const _StepPersonalInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    return _StepScaffold(
      title: 'Personal information',
      children: [
        TextField(
          onChanged: notifier.setFullName,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Age ${state.age}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: state.age.toDouble(),
          min: 13,
          max: 90,
          divisions: 77,
          label: '${state.age}',
          onChanged: notifier.setAge,
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final gender in [
              'Male',
              'Female',
              'Non-binary',
              'Prefer not to say',
            ])
              ChoiceChip(
                label: Text(gender),
                selected: state.gender == gender,
                onSelected: (_) => notifier.setGender(gender),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Add profile photo'),
        ),
      ],
    );
  }
}

class _StepBodyMetrics extends ConsumerWidget {
  const _StepBodyMetrics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    return _StepScaffold(
      title: 'Body metrics',
      children: [
        Text(
          'Height ${state.heightCm.round()} cm',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: state.heightCm,
          min: 120,
          max: 220,
          divisions: 100,
          onChanged: notifier.setHeight,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Weight ${state.weightKg.round()} kg',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: state.weightKg,
          min: 35,
          max: 180,
          divisions: 145,
          onChanged: notifier.setWeight,
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: 'Unknown',
          decoration: const InputDecoration(labelText: 'Blood type'),
          items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown']
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (_) {},
        ),
      ],
    );
  }
}

class _StepFitnessGoals extends ConsumerWidget {
  const _StepFitnessGoals();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    return _StepScaffold(
      title: 'Fitness level and goals',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in [
              'Beginner',
              'Intermediate',
              'Active',
              'Athlete',
            ])
              ChoiceChip(
                label: Text(level),
                selected: state.fitnessLevel == level,
                onSelected: (_) => notifier.setFitnessLevel(level),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final goal in [
              'Weight Loss',
              'Muscle Gain',
              'Endurance',
              'Better Sleep',
              'Stress Management',
              'General Wellness',
            ])
              ChoiceChip(
                label: Text(goal),
                selected: state.primaryGoal == goal,
                onSelected: (_) => notifier.setPrimaryGoal(goal),
              ),
          ],
        ),
      ],
    );
  }
}

class _StepActivity extends ConsumerWidget {
  const _StepActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    return _StepScaffold(
      title: 'Activity',
      children: [
        Center(
          child: Text(
            '${state.activeDays}',
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        Slider(
          value: state.activeDays.toDouble(),
          min: 0,
          max: 7,
          divisions: 7,
          label: '${state.activeDays}',
          onChanged: ref.read(onboardingProvider.notifier).setActiveDays,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final workout in [
              'Running',
              'Cycling',
              'Swimming',
              'Weightlifting',
              'Yoga',
              'HIIT',
              'Pilates',
              'Team sports',
            ])
              FilterChip(
                label: Text(workout),
                selected: ['Running', 'Yoga'].contains(workout),
                onSelected: (_) {},
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: '<30', label: Text('<30')),
            ButtonSegment(value: '30-60', label: Text('30-60')),
            ButtonSegment(value: '60-90', label: Text('60-90')),
            ButtonSegment(value: '90+', label: Text('90+')),
          ],
          selected: const {'30-60'},
          onSelectionChanged: (_) {},
        ),
      ],
    );
  }
}

class _StepSleep extends ConsumerWidget {
  const _StepSleep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    return _StepScaffold(
      title: 'Sleep',
      children: [
        ListTile(
          title: const Text('Usual bedtime'),
          subtitle: const Text('10:30 PM'),
          trailing: const Icon(Icons.schedule),
          onTap: () {},
        ),
        ListTile(
          title: const Text('Usual wake time'),
          subtitle: const Text('6:45 AM'),
          trailing: const Icon(Icons.wb_sunny_outlined),
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Sleep quality ${state.sleepQuality}/10',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: state.sleepQuality.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          onChanged: ref.read(onboardingProvider.notifier).setSleepQuality,
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final issue in [
              'Snoring',
              'Insomnia',
              'Late screen time',
              'Night waking',
              'None',
            ])
              FilterChip(
                label: Text(issue),
                selected: issue == 'None',
                onSelected: (_) {},
              ),
          ],
        ),
      ],
    );
  }
}

class _StepLifestyle extends StatelessWidget {
  const _StepLifestyle();

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Diet and lifestyle',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final diet in [
              'Omnivore',
              'Vegetarian',
              'Vegan',
              'Keto',
              'Paleo',
              'Other',
            ])
              ChoiceChip(
                label: Text(diet),
                selected: diet == 'Omnivore',
                onSelected: (_) {},
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Never', label: Text('Never')),
            ButtonSegment(value: 'Occasionally', label: Text('Occasionally')),
            ButtonSegment(value: 'Regularly', label: Text('Regularly')),
          ],
          selected: const {'Occasionally'},
          onSelectionChanged: (_) {},
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Daily water goal 10 glasses',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Slider(
          value: 10,
          min: 4,
          max: 16,
          divisions: 12,
          onChanged: null,
        ),
      ],
    );
  }
}

class _StepEmergency extends StatelessWidget {
  const _StepEmergency();

  @override
  Widget build(BuildContext context) {
    return const _StepScaffold(
      title: 'Health and emergency',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: Text('Hypertension'),
              selected: false,
              onSelected: null,
            ),
            FilterChip(
              label: Text('Diabetes'),
              selected: false,
              onSelected: null,
            ),
            FilterChip(
              label: Text('Asthma'),
              selected: false,
              onSelected: null,
            ),
            FilterChip(
              label: Text('Anxiety'),
              selected: false,
              onSelected: null,
            ),
            FilterChip(label: Text('None'), selected: true, onSelected: null),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        TextField(decoration: InputDecoration(labelText: 'Medications')),
        SizedBox(height: AppSpacing.md),
        TextField(
          decoration: InputDecoration(labelText: 'Emergency contact name'),
        ),
        SizedBox(height: AppSpacing.md),
        TextField(
          decoration: InputDecoration(labelText: 'Emergency contact phone'),
        ),
        SizedBox(height: AppSpacing.md),
        Text('This data is encrypted and never shared without your consent.'),
      ],
    );
  }
}
