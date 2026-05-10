import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../state/auth_state.dart';
import '../widgets/app_icons.dart';

/// Human-readable text for any sign-in error (no Dart `Bad state:` / `Exception:` clutter).
String _signInErrorForDisplay(Object error) {
  if (error is SignInFailure) return error.message;
  var s = error.toString();
  for (final prefix in <String>['Bad state: ', 'Exception: ']) {
    if (s.startsWith(prefix)) {
      s = s.substring(prefix.length);
      break;
    }
  }
  return s.trim();
}

Future<void> _showSignInFailedDialog(BuildContext context, String message) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sign-in failed'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(
            message,
            style: Theme.of(dialogContext).textTheme.bodyMedium,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: message));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Message copied')),
            );
          },
          child: const Text('Copy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final origin = context.watch<AppState>().apiOrigin;
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock_outline_rounded, size: 56, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'HackLens',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with Google for the same account as the web app (wishlist, collections, alerts).',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: auth.isSignedIn
                  ? null
                  : () async {
                      try {
                        await context.read<AuthState>().signInWithGoogle(origin);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (!context.mounted) return;
                        await _showSignInFailedDialog(context, _signInErrorForDisplay(e));
                      }
                    },
              icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final u = Uri.parse('$origin/api/auth/signin/github');
                if (await canLaunchUrl(u)) {
                  await launchUrl(u, mode: LaunchMode.externalApplication);
                }
              },
              icon: Icon(AppIcons.openInNew),
              label: const Text('Continue with GitHub (web)'),
            ),
            if (auth.isSignedIn) ...[
              const SizedBox(height: 24),
              Text('Signed in as ${auth.user!.email}', textAlign: TextAlign.center),
              TextButton(onPressed: () => auth.signOut(), child: const Text('Sign out')),
            ],
          ],
        ),
      ),
    );
  }
}
