import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hacklens/src/app.dart';
import 'package:hacklens/src/state/app_state.dart';
import 'package:hacklens/src/state/auth_state.dart';
import 'package:hacklens/src/state/browse_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('bootstraps with navigation destinations', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider(create: (_) => BrowseState()),
          ChangeNotifierProvider(create: (_) => AuthState()),
        ],
        child: const HackLensApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Browse'), findsWidgets);
    expect(find.text('HackLens'), findsWidgets);
  });
}
