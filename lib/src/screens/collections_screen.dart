import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/me_api.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';
import 'collection_detail_screen.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  static List<int> _parseHackathonIds(dynamic raw) {
    if (raw is! List) return [];
    final out = <int>[];
    for (final e in raw) {
      if (e is int) {
        out.add(e);
      } else if (e is num) {
        out.add(e.toInt());
      }
    }
    return out;
  }

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
              'Sign in from Browse or Settings to load collections from your HackLens account.',
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No collections yet. Create lists on the web app, then open them here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final c = rows[i];
              final name = c['name']?.toString() ?? 'Untitled';
              final desc = c['description']?.toString();
              final rawId = c['id'];
              final id = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
              final hid = _parseHackathonIds(c['hackathons']);
              final n = hid.length;
              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(desc?.trim().isNotEmpty == true ? desc! : '$n hackathons'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: id > 0
                      ? () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => CollectionDetailScreen(
                                collectionId: id,
                                name: name,
                                description: desc,
                                hackathonIds: hid,
                              ),
                            ),
                          );
                        }
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
