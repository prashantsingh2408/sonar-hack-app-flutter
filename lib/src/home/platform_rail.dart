import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api/hackathon_api.dart';
import '../home/platform_live_slices.dart';
import '../models/hackathon.dart';

/// Horizontal “Live on {host}” rail with slice tabs (matches web `PlatformLiveFeaturedGrids`).
class PlatformLiveRail extends StatefulWidget {
  const PlatformLiveRail({super.key, required this.platform, required this.api});

  final String platform;
  final HackathonApi api;

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
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final h = _items[i];
                  return _RailCard(hackathon: h);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({required this.hackathon});

  final Hackathon hackathon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final img = hackathon.imgUrl;
    return SizedBox(
      width: 260,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: img != null && img.isNotEmpty
                  ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, width: double.infinity)
                  : Container(
                      color: scheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(Icons.image_not_supported_outlined, color: scheme.outline),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hackathon.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hackathon.platform,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
