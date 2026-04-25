import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// IMPORT VŠECH POUŽÍVANÝCH STRÁNEK
import 'pages/pages.dart';

// IMPORT HLAVNÍHO UČITELSKÉHO LAYOUTU
import 'layouts/teacher_main_layout.dart';

void main() {
  // Spuštění samotné aplikace
  runApp(const BakalarkaApp());
}

class BakalarkaApp extends StatelessWidget {
  const BakalarkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quizzes',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('cs', 'CZ'), // Nastavení češtiny jako hlavního jazyka
      ],
      
      // Nastavení globálního grafického tématu
      theme: ThemeData(
        primaryColor: const Color(0xFF0056D2), // Hlavní modrá
        scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Výchozí světlé pozadí
        useMaterial3: true,
      ),

      // Kde má aplikace začít? Lomítko '/' je standardní označení pro domovskou/login obrazovku
      initialRoute: '/',

      // MAPA VŠECH CEST (ROUTES)
      routes: {
        // Výchozí obrazovka
        '/': (context) => const LoginPageWidget(),
        
        // --- UČITEL (Obaleno v TeacherMainLayout SPA rámu) ---
        '/classOverview': (context) => TeacherMainLayout(
              activePage: 'classes',
              child: const ClassOverviewWidget(), 
            ),
        '/classManager': (context) => TeacherMainLayout(
              activePage: 'classes', 
              child: const ClassManagerWidget(),
            ),
        '/bankOverview': (context) => TeacherMainLayout(
              activePage: 'banks',
              child: BankOverviewWidget(), 
            ),
        '/testEditor': (context) => TeacherMainLayout(
              activePage: 'classes', 
              child: const TestEditorWidget(),
            ),
        '/testEvaluation': (context) => TeacherMainLayout(
              activePage: 'classes', 
              child: const TestEvaluationWidget(),
            ),
        '/settingsTeacher': (context) => TeacherMainLayout(
              activePage: 'settings',
              child: const SettingsTeacherWidget(),
            ),
        '/questionsOverview': (context) => TeacherMainLayout(
              activePage: 'banks',
              child: const QuestionsOverviewWidget(),
            ),
        '/addNewQuestion': (context) => TeacherMainLayout(
              activePage: 'banks',
              child: const AddNewQuestionWidget(),
            ),
        '/multiChoiceQuestion': (context) => TeacherMainLayout(
              activePage: 'banks',
              child: const MultiChoiceQuestionWidget(),
            ),
        '/openQuestion': (context) => TeacherMainLayout(
              activePage: 'banks',
              child: const OpenQuestionWidget(),
            ),
        '/shortAnswerQuestion': (context) => TeacherMainLayout(
              activePage: 'banks',
              child: const ShortAnswerQuestionWidget(),
            ),
        '/connectQuestion': (context) => TeacherMainLayout(
              activePage: 'banks',
              child: const ConnectQuestionWidget(),
            ),
        '/orderQuestion': (context) => TeacherMainLayout(
              activePage: 'banks',
              child: const OrderQuestionWidget(),
            ),

        // --- STUDENT (Zatím bez obalu, nebo později přidáme StudentMainLayout) ---
        '/studentOverview': (context) => const StudentOverviewWidget(),
        '/subjectPage': (context) => const SubjectPageWidget(),
        '/testActive': (context) => const TestActiveWidget(),
        '/settingsStudent': (context) => const SettingsStudentWidget(),
      },
    );
  }
}