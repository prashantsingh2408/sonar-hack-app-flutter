import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/me_api.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';
import '../widgets/app_icons.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

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
              'Sign in from Home (profile icon) to sync your wishlist with ${origin.replaceAll(RegExp(r'/$'), '')}.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: FutureBuilder<List<int>>(
        future: MeApi(origin, auth.accessToken).getWishlistHackathonIds(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final ids = snap.data ?? [];
          if (ids.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.wishlist, size: 56, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  const Text('Your saved hackathons will appear here.'),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ids.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => ListTile(
              leading: Icon(AppIcons.collections),
              title: Text('Hackathon #${ids[i]}'),
              subtitle: const Text('Open on web for full cards & reorder'),
            ),
          );
        },
      ),
    );
  }
}
