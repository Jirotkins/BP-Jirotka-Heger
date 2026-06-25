import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';
import '../../components/page_header_widget.dart';
import '../../components/question_select_row_widget.dart';
import '../../components/test_settings_widget.dart';
import '../../components/time_settings_widget.dart';
import '../../theme/app_themes.dart';

class TestEditorWidget extends ConsumerStatefulWidget {
  const TestEditorWidget({super.key});

  @override
  ConsumerState<TestEditorWidget> createState() => _TestEditorWidgetState();
}

class _TestEditorWidgetState extends ConsumerState<TestEditorWidget> {
  late TextEditingController _testNameController;
  late FocusNode _testNameFocusNode;

  bool _isLoadingBanks = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _banks = [];
  
  // Cache for questions: bank_id -> list of questions
  final Map<int, List<Map<String, dynamic>>> _bankQuestionsCache = {};
  final Map<int, bool> _bankQuestionsLoading = {};

  final Set<int> _selectedQuestionIds = {};

  Map<String, dynamic> _testSettings = {};
  Map<String, dynamic> _timeSettings = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _testNameController = TextEditingController();
    _testNameFocusNode = FocusNode();
    _fetchBanks();
  }

  @override
  void dispose() {
    _testNameController.dispose();
    _testNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchBanks() async {
    setState(() {
      _isLoadingBanks = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.get('/banks');
      
      if (mounted) {
        final banksList = data['banks'] as List? ?? [];
        setState(() {
          _banks = banksList.map((b) => {
            'id': b['bank_id'],
            'name': b['name'] ?? 'Neznámá banka',
          }).toList();
          _isLoadingBanks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Chyba při načítání bank: $e';
          _isLoadingBanks = false;
        });
      }
    }
  }

  Future<void> _fetchQuestionsForBank(int bankId) async {
    if (_bankQuestionsCache.containsKey(bankId) || _bankQuestionsLoading[bankId] == true) return;

    setState(() {
      _bankQuestionsLoading[bankId] = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.get('/banks/$bankId/questions');
      
      if (mounted) {
        final questionsList = data['questions'] as List? ?? [];
        setState(() {
          _bankQuestionsCache[bankId] = questionsList.map((q) => {
            'id': q['question_id'],
            'question': q['text'] ?? 'Prázdná otázka',
            'type': q['type'] ?? 'Neznámý typ',
          }).toList();
          _bankQuestionsLoading[bankId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bankQuestionsLoading[bankId] = false;
        });
      }
    }
  }

  Future<void> _submitTest(int groupId) async {
    if (_testNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zadejte název testu.')));
      return;
    }
    if (_selectedQuestionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vyberte alespoň jednu otázku do testu.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      
      List<Map<String, dynamic>> questionsPayload = [];
      int pos = 1;
      for (int qId in _selectedQuestionIds) {
        questionsPayload.add({
          "question_id": qId,
          "position": pos++,
          "points_custom": null 
        });
      }

      final templateData = {
        "name": _testNameController.text.trim(),
        "description": "",
        "difficulty": "MEDIUM",
        "estimated_duration_minutes": _timeSettings['durationMinutes'] ?? 45,
        "is_active": true,
        "settings": _testSettings,
        "questions": questionsPayload
      };

      final templateResponse = await apiClient.post('/test-templates', templateData);
      final templateId = templateResponse['template_id'];

      String? activateFromStr;
      String? activateToStr;

      if (_timeSettings['isInstant'] == true) {
        final now = DateTime.now().toUtc();
        activateFromStr = "${now.toIso8601String().split('.')[0]}Z";
        
        final durationMinutes = _timeSettings['durationMinutes'] as int? ?? 45;
        final end = now.add(Duration(minutes: durationMinutes));
        activateToStr = "${end.toIso8601String().split('.')[0]}Z";
      } else {
         if (_timeSettings['startDate'] != null && _timeSettings['startTime'] != null) {
             final d = DateTime.parse(_timeSettings['startDate']);
             final parts = (_timeSettings['startTime'] as String).split(':');
             final h = int.parse(parts[0]);
             final m = int.parse(parts[1]);
             final combined = DateTime(d.year, d.month, d.day, h, m).toUtc();
             activateFromStr = "${combined.toIso8601String().split('.')[0]}Z";
         }
         if (_timeSettings['endDate'] != null && _timeSettings['endTime'] != null) {
             final d = DateTime.parse(_timeSettings['endDate']);
             final parts = (_timeSettings['endTime'] as String).split(':');
             final h = int.parse(parts[0]);
             final m = int.parse(parts[1]);
             final combined = DateTime(d.year, d.month, d.day, h, m).toUtc();
             activateToStr = "${combined.toIso8601String().split('.')[0]}Z";
         }
      }

      final assignData = {
        "template_id": templateId,
        "activate_from": activateFromStr,
        "activate_to": activateToStr,
        "time_limit_minutes": _timeSettings['durationMinutes'] ?? 45,
        "access_password": null
      };

      await apiClient.post('/groups/$groupId/exam-assignments', assignData);

      if (mounted) {
        final customColors = Theme.of(context).extension<CustomColors>();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Test byl úspěšně zadán!'), backgroundColor: customColors?.greenBg ?? Colors.green));
        context.pop(true);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chyba při zadávání testu: $e'), backgroundColor: Theme.of(context).colorScheme.error));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String targetClass = args?['targetName'] ?? 'Neznámá třída';
    final int groupId = args?['groupId'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeaderWidget(
          title: 'Nový test — $targetClass',
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Vybráno: ${_selectedQuestionIds.length}',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        Expanded(
          child: _isLoadingBanks 
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
            : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTestNameInput(),
                      const SizedBox(height: 24.0),

                      Text('VÝBĚR OTÁZEK Z BANEK', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.1)),
                      const SizedBox(height: 8.0),
                      ..._banks.map((bank) => _buildBankExpansionTile(bank)).toList(),
                      if (_banks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('Zatím nemáte vytvořené žádné banky.', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                        ),

                      const SizedBox(height: 24.0),
                      TestSettingsWidget(onChanged: (settings) => _testSettings = settings),
                      const SizedBox(height: 24.0),
                      TimeSettingsWidget(onChanged: (settings) => _timeSettings = settings),
                      const SizedBox(height: 48.0),

                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting || groupId == 0 ? null : () => _submitTest(groupId),
                          icon: _isSubmitting 
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, size: 20),
                          label: Text('Zadat test', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.surface,
                            minimumSize: const Size(240, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBankExpansionTile(Map<String, dynamic> bank) {
    int bankId = bank['id'];
    bool isLoading = _bankQuestionsLoading[bankId] == true;
    List<Map<String, dynamic>>? questions = _bankQuestionsCache[bankId];

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Icon(Icons.folder_open_rounded, color: Theme.of(context).colorScheme.primary),
          title: Text(bank['name'], style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          onExpansionChanged: (expanded) {
            if (expanded) {
              _fetchQuestionsForBank(bankId);
            }
          },
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            if (isLoading)
              const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
            else if (questions == null || questions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0), 
                child: Text('Tato banka neobsahuje žádné otázky.', style: TextStyle(color: Theme.of(context).colorScheme.secondary))
              )
            else
              ...questions.map((q) {
                int qId = q['id'];
                bool isSelected = _selectedQuestionIds.contains(qId);
                return QuestionSelectRowWidget(
                  question: q['question'],
                  type: q['type'],
                  isSelected: isSelected,
                  onToggle: () {
                    setState(() {
                      if (isSelected) {
                        _selectedQuestionIds.remove(qId);
                      } else {
                        _selectedQuestionIds.add(qId);
                      }
                    });
                  },
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
      ),
      child: TextFormField(
        controller: _testNameController,
        focusNode: _testNameFocusNode,
        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Zadejte název testu...',
          hintStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        ),
      ),
    );
  }
}