import 'package:flutter/material.dart';

class SettingsStudentWidget extends StatefulWidget {
  const SettingsStudentWidget({super.key});

  @override
  State<SettingsStudentWidget> createState() => _SettingsStudentWidgetState();
}

class _SettingsStudentWidgetState extends State<SettingsStudentWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Lokální stavy pro přepínače
  bool _isEmailNotificationsEnabled = false;
  bool _isDarkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 1,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jakub Novák',
              style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Nastavení',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SEKCE PROFIL
              _buildSectionTitle('PROFIL'),
              const SizedBox(height: 8.0),
              _buildSettingsBox([
                _buildSettingsItem(
                  icon: Icons.person_outline_rounded,
                  iconColor: const Color(0xFF3D5AF1),
                  title: 'Změnit jméno',
                  subtitle: 'petr.novak@email.cz', 
                  onTap: () => print('Změna jména'),
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingsItem(
                  icon: Icons.lock_outline_rounded,
                  iconColor: const Color(0xFF3D5AF1),
                  title: 'Změnit heslo',
                  onTap: () => print('Změna hesla'),
                ),
              ]),

              const SizedBox(height: 24.0),

              // SEKCE APLIKACE
              _buildSectionTitle('APLIKACE'),
              const SizedBox(height: 8.0),
              _buildSettingsBox([
                _buildSettingsItem(
                  icon: Icons.dark_mode_outlined,
                  iconColor: const Color(0xFF8E8EF5),
                  title: 'Tmavý režim',
                  trailing: Switch(
                    value: _isDarkModeEnabled,
                    activeColor: const Color(0xFF3D5AF1),
                    onChanged: (val) => setState(() => _isDarkModeEnabled = val),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingsItem(
                  icon: Icons.mail_outline_rounded,
                  iconColor: const Color(0xFF34C759),
                  title: 'E-mailová oznámení',
                  trailing: Switch(
                    value: _isEmailNotificationsEnabled,
                    activeColor: const Color(0xFF3D5AF1),
                    onChanged: (val) => setState(() => _isEmailNotificationsEnabled = val),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingsItem(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF8E8EF5),
                  title: 'O aplikaci',
                  trailingText: 'v1.0.0',
                  onTap: () => print('O aplikaci'),
                ),
              ]),

              const SizedBox(height: 24.0),

              // SEKCE OZNÁMENÍ A ODHLÁŠENÍ
              _buildSectionTitle('OZNÁMENÍ'),
              const SizedBox(height: 8.0),
              _buildSettingsBox([
                _buildSettingsItem(
                  icon: Icons.logout,
                  iconColor: const Color(0xFFFF3B30),
                  title: 'Odhlásit se',
                  titleColor: const Color(0xFFFF3B30),
                  showArrow: false,
                  onTap: () {
                    print('Odhlášení studenta');
                  },
                ),
              ]),
              
              const SizedBox(height: 40.0),
            ],
          ),
        ),
      ),
    );
  }

  // Pomocný widget pro nadpis sekce
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  // Pomocný widget pro bílý zaoblený box kolem skupiny nastavení
  Widget _buildSettingsBox(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8.0, offset: Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  // Pomocný widget pro jeden řádek nastavení
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color titleColor = Colors.black87,
    required Color iconColor,
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
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(icon, color: iconColor, size: 18.0),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                    ),
                ],
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: const TextStyle(color: Colors.grey, fontSize: 13.0),
              ),
            if (trailing != null) trailing,
            if (onTap != null && showArrow && trailing == null)
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14.0),
          ],
        ),
      ),
    );
  }
}