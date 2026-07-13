import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dak/screens/auth/auth_screen.dart';
import 'package:dak/services/auth_service.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class MockAuthService extends ChangeNotifier implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;
}

class MockSupabaseClient implements sb.SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final getIt = GetIt.instance;

  setUp(() {
    getIt.reset();
    getIt.registerSingleton<sb.SupabaseClient>(MockSupabaseClient());
  });

  testWidgets('AuthScreen shows LoginForm and triggers validation snackbar on empty submission', (WidgetTester tester) async {
    // Set large physical size and devicePixelRatio = 1.0 to guarantee enough logical width and avoid layout overflows
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuthService = MockAuthService();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>.value(
        value: mockAuthService,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(0.7)),
            child: AuthScreen(
              onLoginSuccess: () {},
            ),
          ),
        ),
      ),
    );

    // Verify AuthScreen and title is rendered
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    // Tap on Action Button (Login)
    final signInButtonFinder = find.text('Login');
    await tester.tap(signInButtonFinder);
    
    // Pump frames individually instead of pumpAndSettle due to infinite animations in AuthScreen
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify validation snackbar is triggered
    expect(find.text('Please enter your email and password'), findsOneWidget);
  });
}
