import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../pages/pages.dart';
import '../layouts/teacher_main_layout.dart';
import '../layouts/student_main_layout.dart';

// ----------------------------------------------------------------------
// 1. Notifier, který GoRouteru řekne, že se změnil stav přihlášení,
// a že má znovu zkontrolovat přesměrování.
// ----------------------------------------------------------------------
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }
}

// ----------------------------------------------------------------------
// 2. Samotný poskytovatel GoRouteru
// ----------------------------------------------------------------------
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/',
    redirect: (context, state) {
      // Aktuální stav přihlášení
      final authState = ref.read(authProvider);
      final isLoggingIn = state.uri.path == '/' || state.uri.path == '/login';
      
      // 1. Pokud se stav teprve načítá z paměti, přesměrujeme na /loading
      if (authState.isLoading) {
        return state.uri.path == '/loading' ? null : '/loading';
      }

      // 2. Pokud není uživatel přihlášený (a nejsme zrovna na login stránce)
      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : '/';
      }

      // 3. Pokud je přihlášený a snaží se jít na login/loading, hodíme ho na dashboard
      if (isLoggingIn || state.uri.path == '/loading') {
        return authState.role == UserRole.teacher ? '/classOverview' : '/studentHome';
      }

      // 4. Ochrana rolí (Učitel vs Student)
      final teacherRoutes = [
        '/classOverview', '/classManager', '/bankOverview', '/testEditor',
        '/testEvaluation', '/settingsTeacher', '/questionsOverview',
        '/addNewQuestion', '/multiChoiceQuestion', '/openQuestion',
        '/shortAnswerQuestion', '/connectQuestion', '/orderQuestion'
      ];
      final studentRoutes = [
        '/studentHome', '/subjectPage', '/testActive'
      ];

      if (teacherRoutes.contains(state.uri.path) && authState.role != UserRole.teacher) {
        return '/studentHome'; // Student se snaží na učitelskou
      }
      
      if (studentRoutes.contains(state.uri.path) && authState.role != UserRole.student) {
        return '/classOverview'; // Učitel se snaží na studentskou
      }

      // Žádný problém nenalezen, uživatel může pokračovat tam, kam mířil
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginPageWidget(),
      ),
      GoRoute(
        path: '/loading',
        builder: (context, state) => const Scaffold(
          backgroundColor: Color(0xFFF5F7FA),
          body: Center(child: CircularProgressIndicator(color: Color(0xFF0056D2))),
        ),
      ),

      // --- UČITELSKÉ CESTY ---
      GoRoute(
        path: '/classOverview',
        builder: (context, state) => TeacherMainLayout(
          activePage: 'classes',
          child: const ClassOverviewWidget(),
        ),
      ),
      GoRoute(
        path: '/classManager',
        builder: (context, state) => TeacherMainLayout(
          activePage: 'classes',
          child: const ClassManagerWidget(),
        ),
      ),
      GoRoute(
        path: '/bankOverview',
        builder: (context, state) => TeacherMainLayout(
          activePage: 'banks',
          child: BankOverviewWidget(),
        ),
      ),
      GoRoute(
        path: '/testEditor',
        builder: (context, state) => TeacherMainLayout(
          activePage: 'classes',
          child: const TestEditorWidget(),
        ),
      ),
      GoRoute(
        path: '/testEvaluation',
        builder: (context, state) => TeacherMainLayout(
          activePage: 'classes',
          child: const TestEvaluationWidget(),
        ),
      ),
      GoRoute(
        path: '/settingsTeacher',
        builder: (context, state) => TeacherMainLayout(
          activePage: 'settings',
          child: const SettingsTeacherWidget(),
        ),
      ),
      GoRoute(
        path: '/questionsOverview',
        builder: (context, state) => TeacherMainLayout(
          activePage: 'banks',
          child: const QuestionsOverviewWidget(),
        ),
      ),
      GoRoute(
        path: '/addNewQuestion',
        builder: (context, state) => TeacherMainLayout(
          activePage: 'banks',
          child: const AddNewQuestionWidget(),
        ),
      ),
      GoRoute(
        path: '/multiChoiceQuestion',
        builder: (context, state) => TeacherMainLayout(
          activePage: 'banks',
          child: const MultiChoiceQuestionWidget(),
        ),
      ),
      GoRoute(
        path: '/openQuestion',
        builder: (context, state) => TeacherMainLayout(
          activePage: 'banks',
          child: const OpenQuestionWidget(),
        ),
      ),
      GoRoute(
        path: '/shortAnswerQuestion',
        builder: (context, state) => TeacherMainLayout(
          activePage: 'banks',
          child: const ShortAnswerQuestionWidget(),
        ),
      ),
      GoRoute(
        path: '/connectQuestion',
        builder: (context, state) => TeacherMainLayout(
          activePage: 'banks',
          child: const ConnectQuestionWidget(),
        ),
      ),
      GoRoute(
        path: '/orderQuestion',
        builder: (context, state) => TeacherMainLayout(
          activePage: 'banks',
          child: const OrderQuestionWidget(),
        ),
      ),

      // --- STUDENTSKÉ CESTY ---
      GoRoute(
        path: '/studentHome',
        builder: (context, state) => const StudentMainLayout(),
      ),
      GoRoute(
        path: '/subjectPage',
        builder: (context, state) => const SubjectPageWidget(), // Případně doplníme předávání parametrů
      ),
      GoRoute(
        path: '/testActive',
        builder: (context, state) => const TestActiveWidget(), // Případně doplníme předávání parametrů
      ),
    ],
  );
});
