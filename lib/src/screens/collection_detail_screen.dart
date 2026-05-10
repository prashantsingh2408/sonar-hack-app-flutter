import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/hackathon_api.dart';
import '../api/me_api.dart';
import '../models/hackathon.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';
import '../widgets/hackathon_card.dart';
import 'hackathon_detail_screen.dart';

/// Saved collections — same hackathon cards + detail + wishlist as web `/collections`.
class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
    required this.name,
    this.description,
    required this.hackathonIds,
  });

  final int collectionId;
  final String name;
  final String? description;
  final List<int> hackathonIds;

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  List<Hackathon> _items = [];
  Set<int> _wishlistIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _syncWishlist();
    });
  }

  Future<void> _syncWishlist() async {
    final auth = context.read<AuthState>();
    final app = context.read<AppState>();
    if (!auth.isSignedIn || auth.accessToken == null || auth.accessToken!.isEmpty) return;
    try {
      final ids = await MeApi(app.apiOrigin, auth.accessToken).getWishlistHackathonIds();
      if (mounted) setState(() => _wishlistIds = Set<int>.from(ids));
    } catch (_) {}
  }

  Future<void> _toggleWishlist(int id) async {
    final auth = context.read<AuthState>();
    final app = context.read<AppState>();
    if (!auth.isSignedIn || auth.accessToken == null || auth.accessToken!.isEmpty) return;
    final add = !_wishlistIds.contains(id);
    try {
      await MeApi(app.apiOrigin, auth.accessToken).setWishlistHackathon(id, add);
      setState(() {
        if (add) {
          _wishlistIds = {..._wishlistIds, id};
        } else {
          _wishlistIds = {..._wishlistIds}..remove(id);
        }
      });
    } catch (_) {}
  }

  WishlistBinding? _wishlistBinding(AuthState auth) {
    if (!auth.isSignedIn || auth.accessToken == null || auth.accessToken!.isEmpty) return null;
    return WishlistBinding(
      contains: (id) => _wishlistIds.contains(id),
      toggle: _toggleWishlist,
    );
  }

  Future<void> _load() async {
    final origin = context.read<AppState>().apiOrigin;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.hackathonIds.isEmpty) {
        setState(() {
          _items = [];
          _loading = false;
        });
        return;
      }
      final loaded = await HackathonApi(origin).getHackathonsByIds(widget.hackathonIds);
      final ordered = orderHackathonsByIds(loaded, widget.hackathonIds);
      setState(() {
        _items = ordered;
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

  Future<void> _refresh() async {
    await Future.wait<void>([
      _load(),
      _syncWishlist(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final wl = _wishlistBinding(auth);

    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      TextButton(onPressed: _refresh, child: const Text('Retry')),
                    ],
                  )
                : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (widget.description != null && widget.description!.trim().isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(widget.description!, style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        ),
                      if (_items.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('No hackathons in this collection.')),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 2 : 1,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.58,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => HackathonCard(
                                hackathon: _items[i],
                                wishlist: wl,
                                onOpenDetail: (h) => pushHackathonDetail(context, h, wl),
                              ),
                              childCount: _items.length,
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
