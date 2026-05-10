import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/hackathon.dart';

class HackathonTableView extends StatelessWidget {
  const HackathonTableView({super.key, required this.items});

  final List<Hackathon> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(scheme.surfaceContainerHighest),
              columns: const [
                DataColumn(label: Text('Title')),
                DataColumn(label: Text('Platform')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Start')),
                DataColumn(label: Text('Deadline')),
                DataColumn(label: Text('Prize')),
              ],
              rows: [
                for (final h in items)
                  DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(h.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(Text(h.platform)),
                      DataCell(Text(h.status)),
                      DataCell(Text(_fmt(h.startDate))),
                      DataCell(Text(h.endDate != null ? _fmt(h.endDate!) : '—')),
                      DataCell(Text(_stripHtml(h.prizeAmount ?? '—'))),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _fmt(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat.yMMMd().format(d.toLocal());
    } catch (_) {
      return iso;
    }
  }

  static String _stripHtml(String raw) {
    return raw.replaceAll(RegExp(r'<[^>]+>'), '').trim();
  }
}
