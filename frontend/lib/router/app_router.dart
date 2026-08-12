import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../pages/pages.dart';
import '../layouts/teacher_main_layout.dart';
import '../layouts/student_main_layout.dart';

/// [RouterNotifier] slouží k upozornění GoRouteru na změnu stavu přihlášení.
/// Pokud se například uživatel odhlásí nebo přihlásí (změní se [AuthState]), 
/// vyvolá `notifyListeners()`, čímž se znovu přepočítá logika přesměrování (redirect).
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
}

/// Globální provider pro [GoRouter].
/// Obsahuje konfiguraci všech cest v aplikaci a zabezpečení přístupu 
/// pomocí metody `redirect` závislé na [authProvider].
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
        return authState.role == UserRole.teacher
            ? '/classOverview'
            : '/studentHome';
      }

      // 4. Ochrana rolí (Učitel vs Student)
      // Definice cest, které smí vidět pouze učitel.
      final teacherRoutes = [
        '/classOverview',
        '/classManager',
        '/bankOverview',
        '/testEditor',
        '/settingsTeacher',
        '/questionsOverview',
        '/addNewQuestion',
        '/multiChoiceQuestion',
        '/openQuestion',
        '/shortAnswerQuestion',
        '/connectQuestion',
        '/orderQuestion',
      ];
      
      // Definice cest, které smí vidět pouze student.
      final studentRoutes = ['/studentHome', '/subjectPage', '/testActive'];

      // Zablokování přístupu studenta do učitelské sekce.
      if (teacherRoutes.contains(state.uri.path) &&
          authState.role != UserRole.teacher) {
        return '/studentHome';
      }

      // Zablokování přístupu učitele do studentské sekce.
      if (studentRoutes.contains(state.uri.path) &&
          authState.role != UserRole.student) {
        return '/classOverview';
      }

      // Žádný problém nenalezen, uživatel může pokračovat na původní URL.
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/loading',
        builder: (context, state) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),

      // --- UČITELSKÉ CESTY (SPA Layout) ---
      // Všechny tyto cesty jsou zabaleny do [TeacherMainLayout],
      // který zajišťuje trvalé zobrazení levého (nebo spodního) menu.
      ShellRoute(
        builder: (context, state, child) {
          // Logika pro určení aktivní záložky v navigačním menu.
          String activePage = 'classes';
          if (state.uri.path.contains('bank') ||
              state.uri.path.toLowerCase().contains('question')) {
            activePage = 'banks';
          } else if (state.uri.path.contains('settingsTeacher')) {
            activePage = 'settings';
          }

          return TeacherMainLayout(activePage: activePage, child: child);
        },
        routes: [
          GoRoute(
            path: '/classOverview',
            builder: (context, state) => const ClassOverviewPage(),
          ),
          GoRoute(
            path: '/classManager',
            builder: (context, state) => const ClassManagerPage(),
          ),
          GoRoute(
            path: '/bankOverview',
            builder: (context, state) => BankOverviewPage(),
          ),
          GoRoute(
            path: '/testEditor',
            builder: (context, state) => const TestEditorWidget(),
          ),
          GoRoute(
            path: '/testAttempts',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return TestAttemptsPage(
                assignmentId: extra['assignmentId'] as int? ?? 999,
                testTitle: extra['testTitle'] as String? ?? 'Seznam odevzdání',
              );
            },
          ),
          GoRoute(
            path: '/testEvaluation',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return TestEvaluationPage(
                assignmentId: extra['assignmentId'] as int?,
                attemptId: extra['attemptId'] as int?,
                isStudent: extra['isStudent'] as bool? ?? false,
              );
            },
          ),
          GoRoute(
            path: '/settingsTeacher',
            builder: (context, state) => const SettingsTeacherPage(),
          ),
          GoRoute(
            path: '/questionsOverview',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return QuestionsOverviewPage(
                bankId: extra['bankId'] as int? ?? 0,
                bankName: extra['bankName'] as String? ?? 'Neznámá banka',
              );
            },
          ),
          GoRoute(
            path: '/addNewQuestion',
            builder: (context, state) => const AddNewQuestionPage(),
          ),
          GoRoute(
            path: '/multiChoiceQuestion',
            builder: (context, state) => const MultiChoiceQuestionPage(),
          ),
          GoRoute(
            path: '/openQuestion',
            builder: (context, state) => const OpenQuestionPage(),
          ),
          GoRoute(
            path: '/shortAnswerQuestion',
            builder: (context, state) => const ShortAnswerQuestionPage(),
          ),
          GoRoute(
            path: '/connectQuestion',
            builder: (context, state) => const ConnectQuestionPage(),
          ),
          GoRoute(
            path: '/orderQuestion',
            builder: (context, state) => const OrderQuestionPage(),
          ),
        ],
      ),

      // --- STUDENTSKÉ CESTY ---
      GoRoute(
        path: '/studentHome',
        builder: (context, state) => const StudentMainLayout(),
      ),
      GoRoute(
        path: '/subjectPage',
        builder: (context, state) =>
            const SubjectPage(), // Případně doplníme předávání parametrů
      ),
      GoRoute(
        path: '/testActive',
        builder: (context, state) =>
            const TestActiveWidget(), 
      ),
      GoRoute(
        path: '/studentTestEvaluation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return TestEvaluationPage(
            assignmentId: extra['assignmentId'] as int?,
            attemptId: extra['attemptId'] as int?,
            isStudent: extra['isStudent'] as bool? ?? true,
          );
        },
      ),
    ],
  );
});
