import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/collections_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/wishlist_screen.dart';
import 'state/app_state.dart';
import 'theme/hack_lens_theme.dart';
import 'widgets/app_icons.dart';

/// Shell matching web IA: Home browse · Wishlist · Collections · Notifications · Settings.
class HackLensApp extends StatelessWidget {
  const HackLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        return MaterialApp(
          title: 'HackLens',
          debugShowCheckedModeBanner: false,
          theme: HackLensTheme.light(),
          darkTheme: HackLensTheme.dark(),
          themeMode: app.themeMode,
          home: const RootShell(),
        );
      },
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int index = 0;

  static final _pages = <Widget>[
    const HomeScreen(),
    const WishlistScreen(),
    const CollectionsScreen(),
    const NotificationsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [
          NavigationDestination(
            icon: Icon(AppIcons.home),
            selectedIcon: Icon(AppIcons.home),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.wishlist),
            selectedIcon: Icon(AppIcons.wishlist),
            label: 'Wishlist',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.collections),
            selectedIcon: Icon(AppIcons.collections),
            label: 'Collections',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.notifications),
            selectedIcon: Icon(AppIcons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.settings),
            selectedIcon: Icon(AppIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
