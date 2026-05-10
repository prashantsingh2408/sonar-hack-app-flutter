import 'package:flutter/material.dart';

import '../browse/hackathon_sort.dart';
import '../models/filter_type.dart';

const _platformOptions = <String>[
  'Devpost',
  'Lablab',
  'Hack2skill',
  'HackerEarth',
  'MLH',
  'Hackster',
  'Unstop',
  'Vision',
];

const _statusOptions = <String>['Active', 'Upcoming', 'Past'];

const _deadlineOptions = <String>[
  'lte10',
  'lte30',
  'lte60',
  'lte90',
  'gt30',
  'gt60',
  'tba',
];

const _sortPrimaryOptions = <MapEntry<String, String>>[
  MapEntry('most_relevant', 'Most relevant'),
  MapEntry('end_asc', 'Deadline soonest'),
  MapEntry('start_asc', 'Start soonest'),
  MapEntry('prize_amount', 'Prize high → low'),
  MapEntry('recently_added', 'Recently added'),
  MapEntry('registrations_desc', 'Most participants'),
];

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.initial,
    required this.sortChain,
    required this.onApply,
  });

  final FilterType initial;
  final List<String> sortChain;
  final void Function(FilterType filters, List<String> sortChain) onApply;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late FilterType _f;
  late String _sortPrimary;

  @override
  void initState() {
    super.initState();
    _f = widget.initial.copyWith();
    final chain = widget.sortChain;
    _sortPrimary = chain.isEmpty ? hackathonSortDefault : chain.first;
    if (!isHackathonSortValue(_sortPrimary)) {
      _sortPrimary = hackathonSortDefault;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Filters & sort', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _f = FilterType.empty.copyWith();
                      _sortPrimary = hackathonSortDefault;
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Platform', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _platformOptions)
                  FilterChip(
                    label: Text(p),
                    selected: _f.platform.contains(p),
                    onSelected: (_) {
                      setState(() {
                        final next = List<String>.from(_f.platform);
                        if (next.contains(p)) {
                          next.remove(p);
                        } else {
                          next.add(p);
                        }
                        _f = _f.copyWith(platform: next);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Status', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _statusOptions)
                  FilterChip(
                    label: Text(s),
                    selected: _f.status.contains(s),
                    onSelected: (_) {
                      setState(() {
                        final next = List<String>.from(_f.status);
                        if (next.contains(s)) {
                          next.remove(s);
                        } else {
                          next.add(s);
                        }
                        _f = _f.copyWith(status: next);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Deadline bands', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in _deadlineOptions)
                  FilterChip(
                    label: Text(d),
                    selected: _f.daysRemaining.contains(d),
                    onSelected: (_) {
                      setState(() {
                        final next = List<String>.from(_f.daysRemaining);
                        if (next.contains(d)) {
                          next.remove(d);
                        } else {
                          next.add(d);
                        }
                        _f = _f.copyWith(daysRemaining: next);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Managed by Devpost'),
              value: _f.managedByDevpost,
              onChanged: (v) => setState(() => _f = _f.copyWith(managedByDevpost: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Featured catalog only'),
              value: _f.featuredOnly,
              onChanged: (v) => setState(() => _f = _f.copyWith(featuredOnly: v)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _sortPrimary,
              decoration: const InputDecoration(labelText: 'Sort'),
              items: [
                for (final e in _sortPrimaryOptions)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _sortPrimary = v ?? hackathonSortDefault),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                widget.onApply(_f, coerceHackathonSortChain([_sortPrimary]));
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
