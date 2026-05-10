import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/hackathon_api.dart';
import '../browse/hackathon_card_logic.dart';
import '../browse/hackathon_slug.dart';
import '../models/hackathon.dart';
import '../state/app_state.dart';
import '../widgets/hackathon_card.dart';

void pushHackathonDetail(BuildContext context, Hackathon hackathon, WishlistBinding? wishlist) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => HackathonDetailScreen(initial: hackathon, wishlist: wishlist),
    ),
  );
}

/// In-app hackathon page — parity with web `/hackathon/[slug]` (full text + open external).
class HackathonDetailScreen extends StatefulWidget {
  const HackathonDetailScreen({super.key, required this.initial, this.wishlist});

  final Hackathon initial;
  final WishlistBinding? wishlist;

  @override
  State<HackathonDetailScreen> createState() => _HackathonDetailScreenState();
}

class _HackathonDetailScreenState extends State<HackathonDetailScreen> {
  late Hackathon _h;

  @override
  void initState() {
    super.initState();
    _h = widget.initial;
  }

  Future<void> _pullRefresh() async {
    final origin = context.read<AppState>().apiOrigin;
    try {
      final slug = slugifyHackathonTitle(_h.title);
      final fresh = await HackathonApi(origin).getHackathonBySlug(slug);
      if (fresh != null && mounted) setState(() => _h = fresh);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final wl = widget.wishlist;
    final plain = normalizeHackathonPlainText(_h.description);
    final primaryUrl = hackathonPrimaryExternalUrl(_h) ?? _h.url.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(_h.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (wl != null)
            IconButton(
              tooltip: wl.contains(_h.id) ? 'Remove from wishlist' : 'Add to wishlist',
              icon: Icon(
                wl.contains(_h.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: wl.contains(_h.id) ? Colors.redAccent : null,
              ),
              onPressed: () => wl.toggle(_h.id),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _pullRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_h.imgUrl != null && _h.imgUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: _h.imgUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              _h.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('${_h.platform} · ${_h.status}', style: Theme.of(context).textTheme.titleSmall),
            if (_h.displayLocation != null && _h.displayLocation!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(_h.displayLocation!.trim(), style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (_h.organizers.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Organizers: ${_h.organizers}', style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            if (primaryUrl.isNotEmpty)
              FilledButton.icon(
                onPressed: () async {
                  final u = Uri.tryParse(primaryUrl);
                  if (u != null && await canLaunchUrl(u)) {
                    await launchUrl(u, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open hackathon site'),
              ),
            const SizedBox(height: 24),
            Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SelectableText(
              plain.isEmpty ? 'No description.' : plain,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
