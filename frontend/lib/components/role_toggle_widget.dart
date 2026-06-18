import 'package:flutter/material.dart';

class RoleToggleWidget extends StatelessWidget {
  final bool initialIsStudent;
  final ValueChanged<bool> onRoleChanged;

  const RoleToggleWidget({
    super.key,
    required this.initialIsStudent,
    required this.onRoleChanged,
  });

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
            // TLAČÍTKO STUDENT
            Expanded(
              child: InkWell(
                onTap: () => onRoleChanged(true),
                borderRadius: BorderRadius.circular(24.0), // Zabrání tomu, aby efekt "přetekl" přes rohy
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: initialIsStudent ? primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Student',
                    style: TextStyle(
                      color: initialIsStudent ? Theme.of(context).colorScheme.onPrimary : primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ),
            // TLAČÍTKO UČITEL
            Expanded(
              child: InkWell(
                onTap: () => onRoleChanged(false),
                borderRadius: BorderRadius.circular(24.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: !initialIsStudent ? primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Učitel',
                    style: TextStyle(
                      color: !initialIsStudent ? Theme.of(context).colorScheme.onPrimary : primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}