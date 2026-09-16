import 'package:flutter/material.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      body: EmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Authentication',
        description: 'User login & authentication will be implemented in Phase 03.',
      ),
    );
  }
}
