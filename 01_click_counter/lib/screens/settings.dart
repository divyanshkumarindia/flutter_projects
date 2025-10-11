import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.settings, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text('Settings'),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Consumer<SettingsProvider>(
            builder: (context, settings, _) => ListView(
              children: [
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Dark theme'),
                  subtitle: const Text('Use dark mode for the app'),
                  value: settings.isDarkMode,
                  onChanged: (v) => settings.isDarkMode = v,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Haptics'),
                  subtitle: const Text('Enable vibration feedback'),
                  value: settings.hapticsEnabled,
                  onChanged: (v) => settings.hapticsEnabled = v,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Confirm on reset'),
                  subtitle: const Text('Ask for confirmation before resetting'),
                  value: settings.confirmReset,
                  onChanged: (v) => settings.confirmReset = v,
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Click Counter — a tiny Flutter app to track and save counts.',
                        ),
                        SizedBox(height: 6),
                        Text('Developer: Divyansh Singh'),
                        SizedBox(height: 6),
                        Text(
                          'Made with ❤️ — lightweight, simple, and persistent.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Click Counter',
                        applicationVersion: '1.0.0',
                        children: const [
                          Text('Simple counter app by Divyansh Singh.'),
                        ],
                      );
                    },
                    child: const Text('App info'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
