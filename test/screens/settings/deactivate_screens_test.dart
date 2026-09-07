import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dak/screens/settings/deactivate_intro_screen.dart';
import 'package:dak/screens/settings/deactivate_confirm_screen.dart';
import 'package:dak/screens/settings/deactivate_status_screen.dart';
import 'package:dak/services/database_service.dart';
import 'package:dak/services/auth_service.dart';
import 'package:dak/services/general_settings_provider.dart';

// Since this is a UI-heavy set of screens, we will do a basic widget test
// to ensure the screens can render without crashing.

class FakeDatabaseService extends ChangeNotifier implements DatabaseService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  get myProfile => null;
}

class FakeAuthService extends ChangeNotifier implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  get currentUser => null;
}

class FakeGeneralSettingsProvider extends ChangeNotifier implements GeneralSettingsProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  List<Map<String, String>> get activeSessions => [];
}

void main() {
  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DatabaseService>(create: (_) => FakeDatabaseService()),
        ChangeNotifierProvider<AuthService>(create: (_) => FakeAuthService()),
        ChangeNotifierProvider<GeneralSettingsProvider>(create: (_) => FakeGeneralSettingsProvider()),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('DeactivateIntroScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const DeactivateIntroScreen()));
    expect(find.text('Deactivate Account'), findsWidgets);
    expect(find.text('This will deactivate your account'), findsOneWidget);
  });



  testWidgets('DeactivateConfirmScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const DeactivateConfirmScreen(username: 'testuser')));
    expect(find.text('Confirm Deletion'), findsWidgets);
    expect(find.text('Confirm your password'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('DeactivateStatusScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const DeactivateStatusScreen(username: 'testuser')));
    expect(find.text('Your account has been deactivated'), findsOneWidget);
    expect(find.text('30-DAY SAFE HARBOR'), findsOneWidget);
    expect(find.text('Permanent Server Wipe'), findsOneWidget);
  });
}
