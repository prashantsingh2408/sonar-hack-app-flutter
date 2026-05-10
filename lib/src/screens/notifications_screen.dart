import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/hackathon_api.dart';
import '../api/me_api.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';

/// Alerts parity with web `/notifications` — lists per-hackathon reminder prefs when backend returns rows.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Map<int, String> _titles = {};
  bool _requestedHackathonTitles = false;

  Future<void> _resolveTitles(String origin, List<int> ids) async {
    if (ids.isEmpty) return;
    try {
      final loaded = await HackathonApi(origin).getHackathonsByIds(ids);
      if (!mounted) return;
      setState(() {
        _titles = {for (final h in loaded) h.id: h.title};
      });
    } catch (_) {}
  }

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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No notification preferences loaded. On some deployments alerts require the user-data API — same as the web app.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final ids = <int>[];
          for (final row in items) {
            if (row is Map<String, dynamic>) {
              final hid = row['hackathon_id'];
              final id = hid is int ? hid : int.tryParse('$hid');
              if (id != null && id > 0) ids.add(id);
            }
          }
          if (ids.isNotEmpty && !_requestedHackathonTitles) {
            _requestedHackathonTitles = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _resolveTitles(origin, ids.toSet().toList());
            });
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final row = items[i];
              if (row is! Map<String, dynamic>) {
                return Card(child: ListTile(title: Text('$row')));
              }
              final hidRaw = row['hackathon_id'];
              final hid = hidRaw is int ? hidRaw : int.tryParse('$hidRaw') ?? 0;
              final title = hid > 0 ? (_titles[hid] ?? 'Hackathon #$hid') : 'Notification row';
              final start = row['start_reminder'] == true;
              final deadline = row['deadline_reminder'] == true;
              final updates = row['updates_ann'] == true;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _PrefChip(label: 'Start', on: start),
                          _PrefChip(label: 'Deadline', on: deadline),
                          _PrefChip(label: 'Updates', on: updates),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PrefChip extends StatelessWidget {
  const _PrefChip({required this.label, required this.on});

  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: on ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        '$label: ${on ? 'on' : 'off'}',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
