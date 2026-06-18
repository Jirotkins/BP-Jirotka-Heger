import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';
import '../../components/page_header_widget.dart';
import '../../components/add_new_class_popup_widget.dart';
import '../../components/class_card_widget.dart';

class ClassOverviewWidget extends ConsumerStatefulWidget {
  const ClassOverviewWidget({super.key});

  @override
  ConsumerState<ClassOverviewWidget> createState() => _ClassOverviewWidgetState();
}

class _ClassOverviewWidgetState extends ConsumerState<ClassOverviewWidget> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _groups = [];

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final apiClient = ref.read(apiClientProvider);
        final response = await apiClient.get('/groups');
        setState(() {
          _groups = response['groups'] ?? [];
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        // --- HLAVIČKA ---
        PageHeaderWidget(
          title: 'Moje třídy',
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black54,
                  builder: (dialogContext) => Dialog(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: AddNewClassPopupWidget(
                      onSuccess: () {
                        _fetchGroups();
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline, size: 18.0),
              label: Text(
                'Přidat novou třídu',
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

        // --- SEKCE S KARTAMI ---
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0056D2)))
              : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : _groups.isEmpty
                      ? Center(
                          child: Text(
                            'Zatím nemáte žádné třídy.',
                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              
                              // Výpočet přesné šířky karty
                              double cardWidth;
                              if (constraints.maxWidth >= 1200) {
                                // Velké monitory: 3 karty vedle sebe (2 mezery po 24px)
                                cardWidth = (constraints.maxWidth - (2 * 24.0)) / 3;
                              } else if (constraints.maxWidth >= 700) {
                                // Střední monitory/tablety: 2 karty vedle sebe
                                cardWidth = (constraints.maxWidth - 24.0) / 2;
                              } else {
                                // Mobily: 1 karta na plnou šířku
                                cardWidth = constraints.maxWidth;
                              }

                              return Wrap(
                                spacing: 24.0, // Horizontální mezera
                                runSpacing: 24.0, // Vertikální mezera
                                children: List.generate(_groups.length, (index) {
                                  final group = _groups[index];
                                  
                                  // Parsování JSON popisku
                                  String parsedSubject = 'Předmět neuveden';
                                  IconData parsedIcon = Icons.school_outlined;
                                  
                                  try {
                                    final descStr = group['description']?.toString() ?? '';
                                    if (descStr.startsWith('{')) {
                                      final descMap = jsonDecode(descStr) as Map<String, dynamic>;
                                      parsedSubject = descMap['subject'] ?? 'Předmět neuveden';
                                      if (descMap['icon'] != null) {
                                        parsedIcon = IconData(int.parse(descMap['icon']), fontFamily: 'MaterialIcons');
                                      }
                                    } else if (descStr.isNotEmpty) {
                                      parsedSubject = descStr;
                                    }
                                  } catch (_) {
                                    // Pokud to není JSON, použije se výchozí nastavení nebo původní string (který je už ošetřen výše)
                                    final descStr = group['description']?.toString() ?? '';
                                    if (descStr.isNotEmpty && !descStr.startsWith('{')) {
                                      parsedSubject = descStr;
                                    }
                                  }

                                  return SizedBox(
                                    width: cardWidth,
                                    child: ClassCardWidget(
                                      groupId: group['group_id'] as int,
                                      title: group['name'] as String,
                                      subject: parsedSubject,
                                      studentCount: group['student_count'] as int,
                                      activeTestCount: group['active_assignment_count'] as int,
                                      testsToControl: group['pending_grade_count'] as int,
                                      icon: Icon(parsedIcon, color: Colors.white),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}