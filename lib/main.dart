import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/state/app_state.dart';
import 'src/state/auth_state.dart';
import 'src/state/browse_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..loadPrefs()),
        ChangeNotifierProvider(create: (_) => BrowseState()),
        ChangeNotifierProvider(create: (_) => AuthState()..restoreSession()),
      ],
      child: const HackLensApp(),
    ),
  );
}
