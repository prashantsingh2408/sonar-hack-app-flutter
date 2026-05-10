import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/hackathon_api.dart';
import '../api/me_api.dart';
import '../models/hackathon.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';
import '../widgets/app_icons.dart';
import '../widgets/hackathon_card.dart';
import 'hackathon_detail_screen.dart';

/// Wishlist parity with web `/wishlist`: ordered cards + in-app detail + wishlist toggle.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Hackathon> _items = [];
  Set<int> _wishlistIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final origin = context.read<AppState>().apiOrigin;
    final auth = context.read<AuthState>();
    if (!auth.isSignedIn || auth.accessToken == null || auth.accessToken!.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ids = await MeApi(origin, auth.accessToken).getWishlistHackathonIds();
      _wishlistIds = Set<int>.from(ids);
      if (ids.isEmpty) {
        setState(() {
          _items = [];
          _loading = false;
        });
        return;
      }
      final loaded = await HackathonApi(origin).getHackathonsByIds(ids);
      final ordered = orderHackathonsByIds(loaded, ids);
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

  WishlistBinding? _binding(AuthState auth, String origin) {
    if (!auth.isSignedIn || auth.accessToken == null || auth.accessToken!.isEmpty) return null;
    return WishlistBinding(
      contains: (id) => _wishlistIds.contains(id),
      toggle: (id) => _toggleWishlist(origin, auth.accessToken!, id),
    );
  }

  Future<void> _toggleWishlist(String origin, String token, int id) async {
    final add = !_wishlistIds.contains(id);
    try {
      await MeApi(origin, token).setWishlistHackathon(id, add);
      setState(() {
        if (add) {
          _wishlistIds = {..._wishlistIds, id};
        } else {
          _wishlistIds = {..._wishlistIds}..remove(id);
          _items = _items.where((h) => h.id != id).toList();
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final origin = context.watch<AppState>().apiOrigin;
    final auth = context.watch<AuthState>();

    if (!auth.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wishlist')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Sign in from Settings or Browse (profile icon) to sync your wishlist with ${origin.replaceAll(RegExp(r'/$'), '')}.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final wl = _binding(auth, origin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      TextButton(onPressed: _reload, child: const Text('Retry')),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: [
                          Icon(AppIcons.wishlist, size: 56, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 12),
                          Text(
                            'Your saved hackathons will appear here.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 2 : 1,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.58,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (context, i) => HackathonCard(
                          hackathon: _items[i],
                          wishlist: wl,
                          onOpenDetail: (h) => pushHackathonDetail(context, h, wl),
                        ),
                      ),
      ),
    );
  }
}
