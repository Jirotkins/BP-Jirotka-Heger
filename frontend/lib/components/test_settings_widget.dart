import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TestSettingsWidget extends StatefulWidget {
  const TestSettingsWidget({super.key});

  @override
  State<TestSettingsWidget> createState() => _TestSettingsWidgetState();
}

class _TestSettingsWidgetState extends State<TestSettingsWidget> {
  // Lokální stavy nastavení
  String? _selectedAttempts = '1';
  bool _randomOrder = true; 
  bool _immediateFeedback = false;
  bool _canGoBack = true;
  bool _showResults = true;

  final List<String> _attemptOptions = ['1', '2', '3', '5', '10', 'Nekonečno'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 10.0,
            color: Colors.black.withOpacity(0.02),
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent), 
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF6B7280)),
          title: Text(
            'NASTAVENÍ TESTU', 
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF6B7280), letterSpacing: 1.1)
          ),
          childrenPadding: const EdgeInsets.all(20),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // POČET POKUSŮ
            _buildSettingRow(
              title: 'Počet pokusů',
              subtitle: 'Kolikrát může žák test opakovat',
              trailing: Container(
                width: 140,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAttempts,
                    items: _attemptOptions.map((String val) {
                      return DropdownMenuItem<String>(
                        value: val,
                        child: Text(val, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedAttempts = val),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
                    isExpanded: true,
                    dropdownColor: Colors.white,
                  ),
                ),
              ),
            ),

            const Divider(height: 32, color: Color(0xFFF3F4F6)),

            // NÁHODNÉ POŘADÍ OTÁZEK
            _buildSwitchRow(
              title: 'Náhodné pořadí otázek',
              subtitle: 'Každý student uvidí otázky v jiném pořadí',
              value: _randomOrder,
              onChanged: (val) => setState(() => _randomOrder = val),
            ),

            const Divider(height: 32, color: Color(0xFFF3F4F6)),

            // OKAMŽITÁ ZPĚTNÁ VAZBA
            _buildSwitchRow(
              title: 'Okamžitá zpětná vazba',
              subtitle: 'Student vidí výsledek ihned po odpovědi',
              value: _immediateFeedback,
              onChanged: (val) => setState(() => _immediateFeedback = val),
            ),

            const Divider(height: 32, color: Color(0xFFF3F4F6)),

            // MOŽNOST VRACET SE
            _buildSwitchRow(
              title: 'Možnost vracet se v otázkách',
              subtitle: 'Student se může vrátit k předešlým otázkám',
              value: _canGoBack,
              onChanged: (val) => setState(() => _canGoBack = val),
            ),

            const Divider(height: 32, color: Color(0xFFF3F4F6)),

            // ZOBRAZIT VÝSLEDKY
            _buildSwitchRow(
              title: 'Zobrazit výsledky po testu',
              subtitle: 'Student uvidí správné odpovědi na konci',
              value: _showResults,
              onChanged: (val) => setState(() => _showResults = val),
            ),
          ],
        ),
      ),
    );
  }

  // Pomocná metoda pro obecný řádek s vlastním pravým prvkem (Dropdown)
  Widget _buildSettingRow({required String title, required String subtitle, required Widget trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
            ],
          ),
        ),
        const SizedBox(width: 16),
        trailing,
      ],
    );
  }

  // Pomocná metoda přímo pro Switche
  Widget _buildSwitchRow({required String title, required String subtitle, required bool value, required Function(bool) onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          activeColor: const Color(0xFF0056D2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}