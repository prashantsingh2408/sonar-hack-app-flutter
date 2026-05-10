import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/hackathon.dart';

class HackathonScheduleView extends StatelessWidget {
  const HackathonScheduleView({super.key, required this.items});

  final List<Hackathon> items;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Hackathon>>{};
    for (final h in items) {
      final key = h.endDate?.trim().isNotEmpty == true ? h.endDate!.trim() : h.startDate.trim();
      groups.putIfAbsent(key, () => []).add(h);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) {
        try {
          return DateTime.parse(a).compareTo(DateTime.parse(b));
        } catch (_) {
          return a.compareTo(b);
        }
      });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final k = keys[i];
        final list = groups[k]!;
        DateTime? dk;
        try {
          dk = DateTime.parse(k);
        } catch (_) {}
        final header = dk != null ? DateFormat.yMMMEd().format(dk.toLocal()) : k;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(
                header,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            for (final h in list)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(h.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${h.platform} · ${h.status}'),
                  trailing: Text(
                    h.endDate != null ? 'Ends ${_short(h.endDate!)}' : 'Starts ${_short(h.startDate)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _short(String iso) {
    try {
      return DateFormat.MMMd().format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}
