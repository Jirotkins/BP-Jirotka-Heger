import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/page_header_widget.dart';
import '../../components/question_type_menu_widget.dart';

class AddNewQuestionPage extends StatefulWidget {
  const AddNewQuestionPage({super.key});

  @override
  State<AddNewQuestionPage> createState() => _AddNewQuestionPageState();
}

class _AddNewQuestionPageState extends State<AddNewQuestionPage> {
  @override
  Widget build(BuildContext context) {
    // ZÍSKÁNÍ DAT Z PŘEDCHOZÍ STRÁNKY 
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    
    // Získáme název banky
    final String targetName = args?['targetName'] ?? 'Nová otázka';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        // DYNAMICKÁ HLAVIČKA
        PageHeaderWidget(
          title: 'Vytvořit otázku – $targetName',
          showBackButton: true,
          actions: const [], 
        ),
        
        // VYSKAKOVACÍ MENU PRO VÝBĚR TYPU OTÁZKY
        Expanded(
          child: Center(
            child: SingleChildScrollView( 
              child: QuestionTypeMenuWidget(args: args),
            ),
          ),
        ),
        
      ],
    );
  }
}