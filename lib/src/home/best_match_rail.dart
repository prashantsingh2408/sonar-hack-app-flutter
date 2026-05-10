import 'package:flutter/material.dart';

import '../api/me_api.dart';
import '../models/hackathon.dart';
import '../widgets/hackathon_card.dart';

/// “For you” rail from `/api/me/best-match-hackathons` (wishlist + history signals).
class BestMatchRail extends StatefulWidget {
  const BestMatchRail({
    super.key,
    required this.origin,
    required this.token,
    this.wishlist,
    this.onOpenDetail,
  });

  final String origin;
  final String? token;
  final WishlistBinding? wishlist;
  final ValueChanged<Hackathon>? onOpenDetail;

  @override
  State<BestMatchRail> createState() => _BestMatchRailState();
}

class _BestMatchRailState extends State<BestMatchRail> {
  late Future<List<Hackathon>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void didUpdateWidget(BestMatchRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.origin != widget.origin || oldWidget.token != widget.token) {
      _future = _fetch();
    }
  }

  Future<List<Hackathon>> _fetch() {
    if (widget.token == null || widget.token!.isEmpty) {
      return Future.value([]);
    }
    return MeApi(widget.origin, widget.token).postBestMatchHackathons();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token == null || widget.token!.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<List<Hackathon>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(minHeight: 3),
          );
        }
        final items = snap.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Recommended for you',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ),
              SizedBox(
                height: 560,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => SizedBox(
                    width: 300,
                    child: HackathonCard(
                      hackathon: items[i],
                      wishlist: widget.wishlist,
                      onOpenDetail: widget.onOpenDetail,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
