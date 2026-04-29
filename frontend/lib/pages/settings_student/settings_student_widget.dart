import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Obrazovka nastavení studentského účtu a aplikace.
// Umožňuje správu profilu, notifikací, vzhledu a odhlášení.
class SettingsStudentWidget extends StatefulWidget {
  const SettingsStudentWidget({super.key});

  @override
  State<SettingsStudentWidget> createState() => _SettingsStudentWidgetState();
}

class _SettingsStudentWidgetState extends State<SettingsStudentWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isEmailNotificationsEnabled = false;
  bool _isDarkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA), 
      
      // --- HLAVIČKA APLIKACE (AppBar) ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0, 
        automaticallyImplyLeading: false,
        elevation: 0, 
        toolbarHeight: 80, // Sjednocená výška napříč celým SPA
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jakub Novák',
              style: GoogleFonts.inter(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'Nastavení',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      
      // --- TĚLO STRÁNKY ---
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              // 1. SEKCE: PROFIL
              _buildSectionTitle('PROFIL'),
              const SizedBox(height: 8.0),
              _buildSettingsBox([
                // ZMĚNA JMÉNA / EMAILU
                _buildSettingsItem(
                  icon: Icons.person_outline_rounded,
                  iconColor: const Color(0xFF3D5AF1),
                  title: 'Změnit jméno',
                  subtitle: 'petr.novak@email.cz', 
                  onTap: () {
                    print('Změna jména');
                  },
                ),
                const Divider(height: 1, indent: 56),
                // ZMĚNA HESLA
                _buildSettingsItem(
                  icon: Icons.lock_outline_rounded,
                  iconColor: const Color(0xFF3D5AF1),
                  title: 'Změnit heslo',
                  onTap: () {
                    print('Změna hesla');
                  },
                ),
              ]),

              const SizedBox(height: 24.0),

              // 2. SEKCE: APLIKACE (Lokální/Globální nastavení)
              _buildSectionTitle('APLIKACE'),
              const SizedBox(height: 8.0),
              _buildSettingsBox([
                // TMAVÝ REŽIM
                _buildSettingsItem(
                  icon: Icons.dark_mode_outlined,
                  iconColor: const Color(0xFF8E8EF5),
                  title: 'Tmavý režim',
                  trailing: Switch(
                    value: _isDarkModeEnabled,
                    activeColor: const Color(0xFF3D5AF1),
                    onChanged: (val) {
                      setState(() => _isDarkModeEnabled = val);
                    },
                  ),
                ),
                const Divider(height: 1, indent: 56),
                // E-MAILOVÁ OZNÁMENÍ
                _buildSettingsItem(
                  icon: Icons.mail_outline_rounded,
                  iconColor: const Color(0xFF34C759),
                  title: 'E-mailová oznámení',
                  trailing: Switch(
                    value: _isEmailNotificationsEnabled,
                    activeColor: const Color(0xFF3D5AF1),
                    onChanged: (val) {
                      setState(() => _isEmailNotificationsEnabled = val);
                    },
                  ),
                ),
                const Divider(height: 1, indent: 56),
                // O APLIKACI
                _buildSettingsItem(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF8E8EF5),
                  title: 'O aplikaci',
                  trailingText: 'v1.0.0',
                  onTap: () => print('O aplikaci'),
                ),
              ]),

              const SizedBox(height: 24.0),

              // 3. SEKCE: ÚČET (Odhlášení)
              _buildSectionTitle('ÚČET'),
              const SizedBox(height: 8.0),
              _buildSettingsBox([
                _buildSettingsItem(
                  icon: Icons.logout,
                  iconColor: const Color(0xFFFF3B30),
                  title: 'Odhlásit se',
                  titleColor: const Color(0xFFFF3B30),
                  showArrow: false,
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/');
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

  // ============================================================================
  // POMOCNÉ WIDGETY
  // ============================================================================

  // Drobný šedý text pro nadpis sekce (např. "PROFIL")
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  // Bílý kontejner seskupující související nastavení dohromady
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

  // Jednotlivý řádek s možností nastavení (ikona, text, a volitelně Switch / šipka)
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color titleColor = Colors.black87,
    required Color iconColor,
    VoidCallback? onTap,
    Widget? trailing, // Pro vložení Switche
    String? trailingText, // Pro vložení verze
    bool showArrow = true, // Zda ukázat šipku doprava
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            // Levá ikona s barevným pozadím
            Container(
              width: 36.0, height: 36.0,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(icon, color: iconColor, size: 18.0),
            ),
            const SizedBox(width: 14.0),
            
            // Název a podtitulek
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 15.0, fontWeight: FontWeight.w600, color: titleColor)),
                  if (subtitle != null)
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 12.0, color: Colors.grey.shade600)),
                ],
              ),
            ),
            
            // Pravá část (verze, switch, nebo šipka)
            if (trailingText != null)
              Text(trailingText, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13.0)),
            if (trailing != null) trailing,
            if (onTap != null && showArrow && trailing == null)
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 14.0),
          ],
        ),
      ),
    );
  }
}