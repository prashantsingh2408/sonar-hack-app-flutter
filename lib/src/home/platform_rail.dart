import 'package:flutter/material.dart';

import '../api/hackathon_api.dart';
import '../home/platform_live_slices.dart';
import '../models/hackathon.dart';
import '../widgets/hackathon_card.dart';

/// Horizontal “Live on {host}” rail with slice tabs (matches web `PlatformLiveFeaturedGrids`).
class PlatformLiveRail extends StatefulWidget {
  const PlatformLiveRail({
    super.key,
    required this.platform,
    required this.api,
    this.wishlist,
    this.onOpenDetail,
  });

  final String platform;
  final HackathonApi api;
  final WishlistBinding? wishlist;
  final ValueChanged<Hackathon>? onOpenDetail;

  @override
  State<PlatformLiveRail> createState() => _PlatformLiveRailState();
}

class _PlatformLiveRailState extends State<PlatformLiveRail> {
  String _sliceId = 'featured';
  List<Hackathon> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = buildPlatformLiveSliceParams(widget.platform, _sliceId);
      final res = await widget.api.listHackathonsQuery(q);
      setState(() {
        _items = res.items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _items = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chips = defaultPlatformLiveSliceTabIds.take(10).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Live on ${widget.platform}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final id = chips[i];
                final sel = id == _sliceId;
                final label = platformLiveSliceLabels[id] ?? id;
                return ChoiceChip(
                  label: Text(label, style: const TextStyle(fontSize: 13)),
                  selected: sel,
                  onSelected: (_) {
                    if (_sliceId == id) return;
                    setState(() => _sliceId = id);
                    _load();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          if (_error != null)
            Text(_error!, style: TextStyle(color: scheme.error))
          else if (_loading)
            const LinearProgressIndicator(minHeight: 3)
          else
            SizedBox(
              height: 560,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => SizedBox(
                  width: 300,
                  child: HackathonCard(
                    hackathon: _items[i],
                    wishlist: widget.wishlist,
                    onOpenDetail: widget.onOpenDetail,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
