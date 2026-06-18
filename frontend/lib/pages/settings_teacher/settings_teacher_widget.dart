import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/page_header_widget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsTeacherWidget extends ConsumerStatefulWidget {
  const SettingsTeacherWidget({super.key});

  @override
  ConsumerState<SettingsTeacherWidget> createState() => _SettingsTeacherWidgetState();
}

class _SettingsTeacherWidgetState extends ConsumerState<SettingsTeacherWidget> {
  // Lokální stavy pro přepínače
  bool _isEmailNotificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);
    final isDark = currentTheme == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        const PageHeaderWidget(
          title: 'Nastavení',
        ),

        // SCROLLOVACÍ ČÁST S VOLBAMI
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // SEKCE PROFIL
                _buildSectionTitle('PROFIL'),
                const SizedBox(height: 8.0),
                _buildSettingsBox([
                  _buildSettingsItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Změnit jméno',
                    onTap: () => print('Změna jména'),
                  ),
                  const Divider(height: 1, indent: 50),
                  _buildSettingsItem(
                    icon: Icons.lock_outline_rounded,
                    title: 'Změnit heslo',
                    onTap: () => print('Změna hesla'),
                  ),
                ]),

                const SizedBox(height: 32.0),

                // SEKCE OZNÁMENÍ A REŽIM
                _buildSectionTitle('OZNÁMENÍ A VZHLED'),
                const SizedBox(height: 8.0),
                _buildSettingsBox([
                  _buildSettingsItem(
                    icon: Icons.mail_outline_rounded,
                    title: 'E-mailová oznámení',
                    trailing: Switch(
                      value: _isEmailNotificationsEnabled,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) => setState(() => _isEmailNotificationsEnabled = val),
                    ),
                  ),
                  const Divider(height: 1, indent: 50),
                  _buildSettingsItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Tmavý režim',
                    trailing: Switch(
                      value: isDark,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                    ),
                  ),
                ]),

                const SizedBox(height: 32.0),

                // SEKCE APLIKACE
                _buildSectionTitle('APLIKACE'),
                const SizedBox(height: 8.0),
                _buildSettingsBox([
                  _buildSettingsItem(
                    icon: Icons.info_outline_rounded,
                    title: 'O aplikaci',
                    trailingText: 'v1.0.0',
                    onTap: () => print('O aplikaci'),
                  ),
                  const Divider(height: 1, indent: 50),
                  _buildSettingsItem(
                    icon: Icons.logout,
                    title: 'Odhlásit se',
                    titleColor: Theme.of(context).colorScheme.error,
                    iconColor: Theme.of(context).colorScheme.error,
                    showArrow: false,
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      // Redirect se provede automaticky přes RouterNotifier
                    },
                  ),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Pomocný widget pro nadpis sekce
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSettingsBox(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Color? titleColor,
    Color? iconColor,
    VoidCallback? onTap,
    Widget? trailing,
    String? trailingText,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 36.0,
              height: 36.0,
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary, size: 20.0),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14.0),
              ),
            if (trailing != null) trailing,
            if (onTap != null && showArrow && trailing == null)
              Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.secondary, size: 14.0),
          ],
        ),
      ),
    );
  }
}