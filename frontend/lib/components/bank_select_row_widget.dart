import 'package:flutter/material.dart';

class BankSelectRowWidget extends StatefulWidget {
  final String bank;
  final Widget icon;
  final int questions;

  const BankSelectRowWidget({
    super.key,
    required this.bank,
    required this.icon,
    required this.questions,
  });

  @override
  State<BankSelectRowWidget> createState() => _BankSelectRowWidgetState();
}

class _BankSelectRowWidgetState extends State<BankSelectRowWidget> {
  // Lokální stav pro výběr banky
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = Theme.of(context).colorScheme.primary;
    final Color lightBlueBg = Theme.of(context).colorScheme.primaryContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _isSelected = !_isSelected;
          });
        },
        borderRadius: BorderRadius.circular(16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isSelected ? lightBlueBg : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: _isSelected ? primaryBlue : Theme.of(context).colorScheme.outline,
              width: _isSelected ? 2.0 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // IKONA BANKY
              Container(
                width: 42.0,
                height: 42.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.center,
                child: widget.icon,
              ),
              const SizedBox(width: 16.0),

              // POČET OTÁZEK
              SizedBox(
                width: 80.0,
                child: Text(
                  '${widget.questions} otázek',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // NÁZEV BANKY
              Expanded(
                child: Text(
                  widget.bank,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: _isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14.0,
                  ),
                ),
              ),

              // INDIKÁTOR VÝBĚRU (Fajfka)
              if (_isSelected)
                Icon(Icons.check_circle_rounded, color: primaryBlue, size: 24.0)
              else
                Icon(Icons.radio_button_unchecked_rounded, color: Theme.of(context).colorScheme.outline, size: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}