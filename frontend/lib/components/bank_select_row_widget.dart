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
    const Color primaryBlue = Color(0xFF3D5AF1);
    const Color lightBlueBg = Color(0xFFF0F4FA);

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
            color: _isSelected ? lightBlueBg : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: _isSelected ? primaryBlue : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // IKONA BANKY
              Container(
                width: 36.0,
                height: 36.0,
                decoration: BoxDecoration(
                  color: primaryBlue,
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
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12.0,
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
                    color: Colors.black87,
                    fontWeight: _isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14.0,
                  ),
                ),
              ),

              // INDIKÁTOR VÝBĚRU (Fajfka)
              if (_isSelected)
                const Icon(Icons.check_circle_rounded, color: primaryBlue, size: 24.0)
              else
                Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey.shade300, size: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}