import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/page_header_widget.dart';
import '../../components/add_new_bank_popup_widget.dart';
import '../../components/bank_card_widget.dart';
import '../../services/api_client.dart';

class BankOverviewWidget extends ConsumerStatefulWidget {
  const BankOverviewWidget({super.key});

  @override
  ConsumerState<BankOverviewWidget> createState() => _BankOverviewWidgetState();
}

class _BankOverviewWidgetState extends ConsumerState<BankOverviewWidget> {
  List<Map<String, dynamic>> _banksData = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<IconData> _availableIcons = [
    Icons.menu_book_outlined,
    Icons.calculate_outlined,
    Icons.science_outlined,
    Icons.history_edu_outlined,
    Icons.public_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _fetchBanks();
  }

  Future<void> _fetchBanks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.get('/banks');
      
      if (mounted) {
        final banks = data['banks'] as List;
        setState(() {
          _banksData = banks.map((b) {
            String subject = 'Neznámý předmět';
            int iconIndex = 0;
            try {
              final desc = json.decode(b['description'] ?? '{}');
              subject = desc['subject'] ?? 'Neznámý předmět';
              iconIndex = desc['iconIndex'] ?? 0;
            } catch (_) {
              subject = b['description'] ?? 'Neznámý předmět';
            }
            
            // Ošetření indexu ikony
            if (iconIndex < 0 || iconIndex >= _availableIcons.length) {
              iconIndex = 0;
            }

            return {
              'id': b['bank_id'],
              'title': b['name'] ?? 'Neznámý název',
              'subject': subject,
              'icon': _availableIcons[iconIndex],
              'questionCount': 0, // Backend zatím nevrací počet otázek přímo v /banks
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Chyba při načítání bank: $e';
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
        // --- HLAVIČKA ---
        PageHeaderWidget(
          title: 'Banky otázek',
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black54,
                  builder: (_) => Dialog(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: AddNewBankPopupWidget(
                      onSuccess: () => _fetchBanks(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline, size: 18.0),
              label: Text(
                'Přidat novou banku',
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
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                  : _banksData.isEmpty
                      ? Center(
                          child: Text(
                            'Zatím nemáte vytvořené žádné banky otázek.',
                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              double cardWidth;
                              if (constraints.maxWidth >= 1200) {
                                cardWidth = (constraints.maxWidth - (2 * 24.0)) / 3;
                              } else if (constraints.maxWidth >= 700) {
                                cardWidth = (constraints.maxWidth - 24.0) / 2;
                              } else {
                                cardWidth = constraints.maxWidth;
                              }

                              return Wrap(
                                spacing: 24.0,
                                runSpacing: 24.0,
                                children: List.generate(_banksData.length, (index) {
                                  final bankData = _banksData[index];
                                  return SizedBox(
                                    width: cardWidth,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16.0),
                                      onTap: () {
                                        context.push(
                                          '/questionsOverview',
                                          extra: {
                                            'bankId': bankData['id'],
                                            'bankName': bankData['title'],
                                          },
                                        );
                                      },
                                      child: BankCardWidget(
                                        title: bankData['title'] as String,
                                        subject: bankData['subject'] as String,
                                        questionCount: bankData['questionCount'] as int,
                                        icon: Icon(bankData['icon'] as IconData, color: Colors.white),
                                      ),
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