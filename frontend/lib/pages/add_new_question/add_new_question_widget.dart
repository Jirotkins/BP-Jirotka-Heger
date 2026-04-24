import 'package:flutter/material.dart';
import '../../components/page_header_widget.dart';
import '../../components/question_type_menu_widget.dart';

class AddNewQuestionWidget extends StatefulWidget {
  const AddNewQuestionWidget({super.key});

  @override
  State<AddNewQuestionWidget> createState() => _AddNewQuestionWidgetState();
}

class _AddNewQuestionWidgetState extends State<AddNewQuestionWidget> {
  @override
  Widget build(BuildContext context) {
    // ZÍSKÁNÍ DAT Z PŘEDCHOZÍ STRÁNKY 
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    // Získáme název banky
    final String targetName = args?['targetName'] ?? 'Nová otázka';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        // DYNAMICKÁ HLAVIČKA
        PageHeaderWidget(
          title: 'Vytvořit otázku — $targetName',
          actions: const [], 
        ),
        
        // VYSKAKOVACÍ MENU PRO VÝBĚR TYPU OTÁZKY
        const Expanded(
          child: Center(
            child: SingleChildScrollView( 
              child: QuestionTypeMenuWidget(),
            ),
          ),
        ),
        
      ],
    );
  }
}