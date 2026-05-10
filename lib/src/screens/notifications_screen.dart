import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/me_api.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final origin = context.watch<AppState>().apiOrigin;
    final auth = context.watch<AuthState>();

    if (!auth.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alerts')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Sign in to load hackathon notification preferences synced with the backend.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: FutureBuilder<List<dynamic>>(
        future: MeApi(origin, auth.accessToken).getHackathonNotificationItems(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No notification rows — preferences may be local-only on this deployment.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final row = items[i];
              return Card(
                child: ListTile(
                  title: Text(row is Map ? row.toString() : '$row'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
