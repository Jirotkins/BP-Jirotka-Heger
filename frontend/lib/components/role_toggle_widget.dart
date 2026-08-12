import 'package:flutter/material.dart';

/// Komponenta pro výběr role při přihlašování (Student / Učitel).
/// 
/// Vykresluje přepínač ve stylu "pill" (kapsle) se dvěma možnostmi.
/// Kdykoliv uživatel vybere jinou roli, zavolá se callback [onRoleChanged].
class RoleToggleWidget extends StatelessWidget {
  /// Počáteční hodnota určující, zda je vybrán student (`true`) nebo učitel (`false`).
  final bool initialIsStudent;
  
  /// Callback volaný při změně role. Předává `true` pro studenta a `false` pro učitele.
  final ValueChanged<bool> onRoleChanged;

  /// Vytvoří widget pro přepínání role.
  const RoleToggleWidget({
    super.key,
    required this.initialIsStudent,
    required this.onRoleChanged,
  });

  /// Pomocná metoda pro vykreslení jednoho ze dvou tlačítek přepínače.
  /// 
  /// Zajišťuje správné barvy, animace a reakci na kliknutí v závislosti
  /// na tom, zda je tlačítko aktuálně [isSelected].
  Widget _buildRoleButton(
    BuildContext context, 
    String title, 
    bool isSelected, 
    VoidCallback onTap, 
    Color primaryColor,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.0), // Zabrání tomu, aby efekt "přetekl" přes rohy
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(24.0),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.onPrimary : primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: 52.0,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(26.0),
        border: Border.all(color: primaryColor, width: 1.5),
      ),
      // Material widget je nutný, aby InkWell správně vykresloval animace kliknutí
      child: Material(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRoleButton(
              context, 
              'Student', 
              initialIsStudent, 
              () => onRoleChanged(true), 
              primaryColor,
            ),
            _buildRoleButton(
              context, 
              'Učitel', 
              !initialIsStudent, 
              () => onRoleChanged(false), 
              primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}