import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hacklens/src/app.dart';
import 'package:hacklens/src/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('bootstraps with navigation destinations', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const HackLensApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Browse'), findsWidgets);
    expect(find.text('HackLens'), findsWidgets);
  });
}
