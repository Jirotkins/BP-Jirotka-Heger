import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TestSettingsWidget extends StatefulWidget {
  final Function(Map<String, dynamic>)? onChanged;

  const TestSettingsWidget({super.key, this.onChanged});

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
  void initState() {
    super.initState();
    // Počáteční odeslání výchozích hodnot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChanges();
    });
  }

  void _notifyChanges() {
    if (widget.onChanged != null) {
      widget.onChanged!({
        'attempts': _selectedAttempts,
        'shuffle': _randomOrder,
        'immediate_feedback': _immediateFeedback,
        'can_go_back': _canGoBack,
        'show_results_after_submit': _showResults,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 10.0,
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), 
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Icon(Icons.settings_suggest_rounded, color: Theme.of(context).colorScheme.secondary),
          title: Text(
            'NASTAVENÍ TESTU', 
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.1)
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
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAttempts,
                    items: _attemptOptions.map((String val) {
                      return DropdownMenuItem<String>(
                        value: val,
                        child: Text(val, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedAttempts = val);
                      _notifyChanges();
                    },
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.secondary),
                    isExpanded: true,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            ),

            Divider(height: 32, color: Theme.of(context).colorScheme.outline),

            // NÁHODNÉ POŘADÍ OTÁZEK
            _buildSwitchRow(
              title: 'Náhodné pořadí otázek',
              subtitle: 'Každý student uvidí otázky v jiném pořadí',
              value: _randomOrder,
              onChanged: (val) {
                setState(() => _randomOrder = val);
                _notifyChanges();
              },
            ),

            Divider(height: 32, color: Theme.of(context).colorScheme.outline),

            // OKAMŽITÁ ZPĚTNÁ VAZBA
            _buildSwitchRow(
              title: 'Okamžitá zpětná vazba',
              subtitle: 'Student vidí výsledek ihned po odpovědi',
              value: _immediateFeedback,
              onChanged: (val) {
                setState(() => _immediateFeedback = val);
                _notifyChanges();
              },
            ),

            Divider(height: 32, color: Theme.of(context).colorScheme.outline),

            // MOŽNOST VRACET SE
            _buildSwitchRow(
              title: 'Možnost vracet se v otázkách',
              subtitle: 'Student se může vrátit k předešlým otázkám',
              value: _canGoBack,
              onChanged: (val) {
                setState(() => _canGoBack = val);
                _notifyChanges();
              },
            ),

            Divider(height: 32, color: Theme.of(context).colorScheme.outline),

            // ZOBRAZIT VÝSLEDKY
            _buildSwitchRow(
              title: 'Zobrazit výsledky po testu',
              subtitle: 'Student uvidí správné odpovědi na konci',
              value: _showResults,
              onChanged: (val) {
                setState(() => _showResults = val);
                _notifyChanges();
              },
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
              Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.secondary)),
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
              Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.secondary)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          activeColor: Theme.of(context).colorScheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}