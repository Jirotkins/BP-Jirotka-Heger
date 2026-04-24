import 'package:flutter/material.dart';
import 'question_type_menu_widget.dart'; 

class NextQuestionButtonWidget extends StatelessWidget {
  const NextQuestionButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        await showDialog(
          barrierColor: const Color(0x65000000),
          context: context,
          builder: (dialogContext) {
            return const Dialog(
              elevation: 0,
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              child: QuestionTypeMenuWidget(),
            );
          },
        );
      },
      icon: const Icon(
        Icons.add_circle_outline,
        size: 15.0,
        color: Colors.white,
      ),
      label: const Text(
        'Uložit a přidat další otázku',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14.0, 
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3D5AF1), 
        elevation: 0.0,
        padding: const EdgeInsets.all(16.0),
        minimumSize: const Size(0, 44.0), 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22.0),
        ),
      ),
    );
  }
}