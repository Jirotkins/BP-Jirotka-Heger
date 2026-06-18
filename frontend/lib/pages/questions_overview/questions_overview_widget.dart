import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/page_header_widget.dart';
import '../../components/question_row_widget.dart';
import '../../services/api_client.dart';

class QuestionsOverviewWidget extends ConsumerStatefulWidget {
  final int bankId;
  final String bankName;

  const QuestionsOverviewWidget({
    super.key,
    this.bankId = 0,
    this.bankName = 'Neznámá banka',
  });

  @override
  ConsumerState<QuestionsOverviewWidget> createState() => _QuestionsOverviewWidgetState();
}

class _QuestionsOverviewWidgetState extends ConsumerState<QuestionsOverviewWidget> {
  List<Map<String, dynamic>> _questionsData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    if (widget.bankId == 0) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.get('/banks/${widget.bankId}/questions');
      
      if (mounted) {
        final questions = data['questions'] as List? ?? [];
        setState(() {
          _questionsData = questions.map((q) {
            return {
              'id': q['question_id'],
              'question': q['text'] ?? 'Prázdná otázka',
              'type': q['type'] ?? 'Neznámý typ',
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Chyba při načítání otázek: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- DYNAMICKÁ HLAVIČKA ---
        PageHeaderWidget(
          title: widget.bankName, 
          actions: [
            // TLAČÍTKO: Přidat novou otázku 
            ElevatedButton.icon(
              onPressed: () {
                // Přesměrování na tvorbu otázky s předáním názvu banky
                context.push('/addNewQuestion', extra: {
                  'targetName': widget.bankName, 
                  'bankId': widget.bankId,
                });
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(
                'Přidat novou otázku',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0056D2),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ],
        ),

        // --- HLAVNÍ PLOCHA (SEZNAM OTÁZEK) ---
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10.0,
                    color: Colors.black.withOpacity(0.02),
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                      : _questionsData.isEmpty
                          ? Center(
                              child: Text(
                                'Zatím nemáte v této bance žádné otázky.',
                                style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(24.0),
                              itemCount: _questionsData.length,
                              separatorBuilder: (context, index) => const Divider(
                                height: 32.0, // Mezera kolem čáry
                                thickness: 1.0,
                                color: Color(0xFFF3F4F6), 
                              ),
                              itemBuilder: (context, index) {
                                final questionData = _questionsData[index];
                                return QuestionRowWidget(
                                  id: questionData['id'],
                                  question: questionData['question'],
                                  type: questionData['type'],
                                );
                              },
                            ),
            ),
          ),
        ),
      ],
    );
  }
}