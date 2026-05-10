import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../widgets/app_icons.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _apiCtrl;
  bool _originSeeded = false;

  @override
  void initState() {
    super.initState();
    _apiCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_originSeeded) {
      _originSeeded = true;
      _apiCtrl.text = context.read<AppState>().apiOrigin;
    }
  }

  @override
  void dispose() {
    _apiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('API', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary)),
          const SizedBox(height: 8),
          TextField(
            controller: _apiCtrl,
            decoration: const InputDecoration(
              labelText: 'HackLens origin',
              hintText: 'https://hacklens.vercel.app',
              border: OutlineInputBorder(),
              helperText: 'Must match the deployed Next.js app (same /api/* as the web client).',
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await app.setApiOrigin(_apiCtrl.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API origin saved')),
                );
              }
            },
            icon: Icon(AppIcons.link),
            label: const Text('Save origin'),
          ),
          const SizedBox(height: 28),
          Text('Appearance', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary)),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_rounded)),
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_rounded)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded)),
            ],
            selected: {app.themeMode},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) app.setThemeMode(s.first);
            },
          ),
          const SizedBox(height: 28),
          Text('Web app', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary)),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(AppIcons.openInNew),
            title: const Text('Open HackLens in browser'),
            subtitle: Text(app.apiOrigin),
            onTap: () async {
              final u = Uri.parse(app.apiOrigin);
              if (await canLaunchUrl(u)) {
                await launchUrl(u, mode: LaunchMode.externalApplication);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.person_rounded),
            title: const Text('Profile & home layout'),
            subtitle: const Text('Still easiest from the web UI today.'),
            onTap: () async {
              final u = Uri.parse('${app.apiOrigin}/profile');
              if (await canLaunchUrl(u)) {
                await launchUrl(u, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}
