import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/app/app.dart';
import 'package:habitude/core/constants/app_constants.dart';
import 'package:habitude/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Habitude splash screen initial render smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const HabitudeApp(),
      ),
    );

    // Initial pump shows splash screen with app name
    expect(find.text(AppConstants.appName), findsOneWidget);
  });
}
