import 'package:flutter/material.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      body: EmptyState(
        icon: Icons.settings_rounded,
        title: 'Settings & Preferences',
        description: 'App preferences, offline sync controls, and units settings.',
      ),
    );
  }
}
