import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/hackathon_api.dart';
import '../api/me_api.dart';
import '../browse/display_mode.dart';
import '../browse/filter_sheet.dart';
import '../browse/hackathon_schedule_view.dart';
import '../browse/hackathon_table_view.dart';
import '../browse/query_params.dart';
import '../home/hackathon_home_sections.dart';
import '../home/best_match_rail.dart';
import '../home/platform_live_slices.dart';
import '../home/platform_rail.dart';
import '../models/hackathon.dart';
import 'hackathon_detail_screen.dart';
import 'login_screen.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';
import '../state/browse_state.dart';
import '../widgets/app_icons.dart';
import '../widgets/hackathon_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  List<Hackathon> _items = [];
  List<MapEntry<HomeRelevanceTier, List<Hackathon>>> _heroGroups = [];
  Set<int> _wishlistIds = {};
  String? _error;
  bool _loading = false;
  bool _heroLoading = false;
  AuthState? _authListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final b = context.read<BrowseState>();
      _search.text = b.searchTerm;
      final auth = context.read<AuthState>();
      _authListener = auth;
      auth.addListener(_onAuthChanged);
      await _reloadAll();
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    _syncWishlistIfNeeded();
  }

  @override
  void dispose() {
    _authListener?.removeListener(_onAuthChanged);
    _search.dispose();
    super.dispose();
  }

  bool _showCurated(BrowseState b) {
    return shouldShowCuratedHomeSections(
          filters: b.filters,
          search: _search.text,
          sortChain: b.sortChain,
        ) &&
        b.displayMode == HackathonListDisplayMode.grid;
  }

  Future<void> _loadCatalog() async {
    final app = context.read<AppState>();
    final browse = context.read<BrowseState>();
    final api = HackathonApi(app.apiOrigin);
    setState(() {
      _loading = true;
      _error = null;
    });
    browse.setSearchTerm(_search.text.trim());
    try {
      final res = await api.listHackathons(
        BuildHackathonListParamsInput(
          filters: browse.filters,
          searchTerm: _search.text.trim(),
          sortChain: browse.sortChain,
          page: 1,
          pageSize: 20,
        ),
      );
      setState(() {
        _items = res.items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _items = [];
        _loading = false;
      });
    }
  }

  Future<void> _loadHeroIfNeeded() async {
    final browse = context.read<BrowseState>();
    if (!_showCurated(browse)) {
      setState(() => _heroGroups = []);
      return;
    }
    final app = context.read<AppState>();
    final api = HackathonApi(app.apiOrigin);
    setState(() => _heroLoading = true);
    try {
      final res = await api.listHackathonsQuery({
        'page': '1',
        'page_size': '80',
        'sort': 'most_relevant',
      });
      setState(() {
        _heroGroups = groupHackathonsByHomeTier(res.items);
        _heroLoading = false;
      });
    } catch (_) {
      setState(() {
        _heroGroups = [];
        _heroLoading = false;
      });
    }
  }

  Future<void> _reloadAll() async {
    await _loadCatalog();
    await _loadHeroIfNeeded();
    await _syncWishlistIfNeeded();
  }

  Future<void> _syncWishlistIfNeeded() async {
    final auth = context.read<AuthState>();
    if (!auth.isSignedIn || auth.accessToken == null || auth.accessToken!.isEmpty) {
      if (_wishlistIds.isNotEmpty) setState(() => _wishlistIds = {});
      return;
    }
    try {
      final ids =
          await MeApi(context.read<AppState>().apiOrigin, auth.accessToken).getWishlistHackathonIds();
      setState(() => _wishlistIds = Set<int>.from(ids));
    } catch (_) {}
  }

  Future<void> _toggleWishlist(int id) async {
    final auth = context.read<AuthState>();
    final origin = context.read<AppState>().apiOrigin;
    if (!auth.isSignedIn || auth.accessToken == null || auth.accessToken!.isEmpty) return;
    final api = MeApi(origin, auth.accessToken);
    final add = !_wishlistIds.contains(id);
    try {
      await api.setWishlistHackathon(id, add);
      setState(() {
        if (add) {
          _wishlistIds = {..._wishlistIds, id};
        } else {
          final next = {..._wishlistIds}..remove(id);
          _wishlistIds = next;
        }
      });
    } catch (_) {}
  }

  WishlistBinding? _wishlistFor(AuthState auth) {
    if (!auth.isSignedIn || auth.accessToken == null || auth.accessToken!.isEmpty) return null;
    return WishlistBinding(
      contains: (id) => _wishlistIds.contains(id),
      toggle: _toggleWishlist,
    );
  }

  void _openHackathon(Hackathon h) {
    final wl = _wishlistFor(context.read<AuthState>());
    pushHackathonDetail(context, h, wl);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final browse = context.watch<BrowseState>();
    final auth = context.watch<AuthState>();
    final wl = _wishlistFor(auth);
    final showRails = _showCurated(browse);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'H',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HackLens',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Focus · filter · compare',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: auth.isSignedIn ? auth.user!.email : 'Sign in',
            icon: Icon(auth.isSignedIn ? Icons.person_rounded : Icons.login_rounded),
            onPressed: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
          PopupMenuButton<HackathonListDisplayMode>(
            tooltip: 'Layout',
            icon: Icon(
              browse.displayMode == HackathonListDisplayMode.grid
                  ? Icons.grid_view_rounded
                  : browse.displayMode == HackathonListDisplayMode.table
                      ? Icons.table_rows_rounded
                      : Icons.calendar_month_rounded,
            ),
            onSelected: (mode) {
              context.read<BrowseState>().setDisplayMode(mode);
              _reloadAll();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: HackathonListDisplayMode.grid, child: Text('Grid')),
              PopupMenuItem(value: HackathonListDisplayMode.table, child: Text('Table')),
              PopupMenuItem(value: HackathonListDisplayMode.schedule, child: Text('Schedule')),
            ],
          ),
          IconButton(
            icon: Icon(AppIcons.refresh),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _reloadAll,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBar(
              controller: _search,
              hintText: 'Search hackathons…',
              leading: Icon(AppIcons.search),
              trailing: [
                IconButton(
                  icon: Icon(AppIcons.filter),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (ctx) => FilterSheet(
                        initial: browse.filters,
                        sortChain: browse.sortChain,
                        onApply: (f, chain) {
                          browse.setFilters(f);
                          browse.setSortChain(chain);
                          _reloadAll();
                        },
                      ),
                    );
                  },
                ),
              ],
              onSubmitted: (_) {
                context.read<BrowseState>().setSearchTerm(_search.text.trim());
                _reloadAll();
              },
            ),
          ),
          if (_error != null)
            MaterialBanner(
              content: Text(_error!, maxLines: 4),
              actions: [TextButton(onPressed: _reloadAll, child: const Text('Retry'))],
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reloadAll,
              child: _loading && _items.isEmpty && !showRails
                  ? const Center(child: CircularProgressIndicator())
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (showRails && _heroLoading)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: LinearProgressIndicator(minHeight: 3),
                            ),
                          ),
                        if (showRails && !_heroLoading && _heroGroups.isNotEmpty)
                          for (final entry in _heroGroups)
                            if (!homeTierRedundantWithPlatformLiveRail(entry.key))
                              SliverToBoxAdapter(
                                child: _TierRail(
                                  title: tierLabels[entry.key]!,
                                  items: entry.value,
                                  wishlist: wl,
                                  onOpenDetail: _openHackathon,
                                ),
                              ),
                        if (showRails && auth.isSignedIn)
                          SliverToBoxAdapter(
                            child: BestMatchRail(
                              origin: context.read<AppState>().apiOrigin,
                              token: auth.accessToken,
                              wishlist: wl,
                              onOpenDetail: _openHackathon,
                            ),
                          ),
                        if (showRails)
                          for (final host in platformLiveHosts)
                            SliverToBoxAdapter(
                              child: PlatformLiveRail(
                                platform: host,
                                api: HackathonApi(context.read<AppState>().apiOrigin),
                                wishlist: wl,
                                onOpenDetail: _openHackathon,
                              ),
                            ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Browse',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        if (browse.displayMode == HackathonListDisplayMode.grid)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 2 : 1,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.58,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  if (_items.isEmpty) {
                                    return const Center(child: Text('No results'));
                                  }
                                  return HackathonCard(
                                    hackathon: _items[i],
                                    wishlist: wl,
                                    onOpenDetail: _openHackathon,
                                  );
                                },
                                childCount: _items.isEmpty ? 1 : _items.length,
                              ),
                            ),
                          )
                        else if (browse.displayMode == HackathonListDisplayMode.table)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: HackathonTableView(items: _items, onHackathonTap: _openHackathon),
                            ),
                          )
                        else
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.55,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: HackathonScheduleView(items: _items, onHackathonTap: _openHackathon),
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierRail extends StatelessWidget {
  const _TierRail({
    required this.title,
    required this.items,
    this.wishlist,
    this.onOpenDetail,
  });

  final String title;
  final List<Hackathon> items;
  final WishlistBinding? wishlist;
  final ValueChanged<Hackathon>? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
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
                  wishlist: wishlist,
                  onOpenDetail: onOpenDetail,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
