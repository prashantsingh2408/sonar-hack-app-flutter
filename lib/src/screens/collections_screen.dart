import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/me_api.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final origin = context.watch<AppState>().apiOrigin;
    final auth = context.watch<AuthState>();

    if (!auth.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collections')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Sign in from Home to load collections from your HackLens account.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: MeApi(origin, auth.accessToken).getCollections(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final rows = snap.data ?? [];
          if (rows.isEmpty) {
            return const Center(child: Text('No collections yet — create some on the web app.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final c = rows[i];
              final name = c['name']?.toString() ?? 'Untitled';
              final desc = c['description']?.toString();
              final n = (c['hackathons'] as List?)?.length ?? 0;
              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(desc ?? '$n hackathons'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
