import 'package:flutter/material.dart';

class SubjectPageWidget extends StatefulWidget {
  const SubjectPageWidget({super.key});

  @override
  State<SubjectPageWidget> createState() => _SubjectPageWidgetState();
}

class _SubjectPageWidgetState extends State<SubjectPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Ukázková data
  final List<Map<String, dynamic>> _upcomingTests = [
    {
      'title': 'Rovnice a nerovnice',
      'deadline': '28. 1. 2025',
      'questions': 15,
    },
    {
      'title': 'Funkce',
      'deadline': '5. 11. 2024',
      'questions': 12,
    }
  ];

  final List<Map<String, dynamic>> _pastTests = [
    {
      'title': 'Zlomky a procenta',
      'date': '1. 9. 2024',
      'score': '14/15',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA), // Světlé pozadí
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Matematika',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 22),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HLAVNÍ STATISTIKA (PRŮMĚR)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8.0, offset: Offset(0, 2))],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 52.0, height: 52.0,
                      decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(14.0)),
                      child: const Icon(Icons.calculate_outlined, color: Color(0xFF4A6CF7), size: 28.0),
                    ),
                    const SizedBox(width: 16.0),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Předmět', style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                          Text('Matematika', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0)),
                        ],
                      ),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('85%', style: TextStyle(color: Color(0xFF34C759), fontWeight: FontWeight.bold, fontSize: 24.0)),
                        Text('12 / 14 bodů', style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24.0),

              // NADCHÁZEJÍCÍ TESTY
              const Text('Nadcházející testy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
              const SizedBox(height: 12.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: Column(
                  children: _upcomingTests.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> test = entry.value;
                    return Column(
                      children: [
                        _buildUpcomingTestCard(test),
                        if (index != _upcomingTests.length - 1)
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8), indent: 16, endIndent: 16),
                      ],
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24.0),

              // PŘEDCHOZÍ TESTY (HISTORIE)
              const Text('Předchozí testy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
              const SizedBox(height: 12.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: Column(
                  children: _pastTests.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> test = entry.value;
                    return Column(
                      children: [
                        _buildPastTestCard(test),
                        if (index != _pastTests.length - 1)
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8), indent: 16, endIndent: 16),
                      ],
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 40.0), // Místo pro posun dole
            ],
          ),
        ),
      ),
    );
  }

  // Karta pro nadcházející test
  Widget _buildUpcomingTestCard(Map<String, dynamic> test) {
    return InkWell(
      onTap: () {
        print('Spouštím test: ${test['title']}');
        // Navigator.pushNamed(context, '/testActive');
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0)),
                  const SizedBox(height: 4),
                  Text('Termín: ${test['deadline']} • ${test['questions']} otázek', style: const TextStyle(color: Colors.grey, fontSize: 12.0)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF4A6CF7), size: 16.0),
          ],
        ),
      ),
    );
  }

  // Karta pro předchozí (dokončený) test
  Widget _buildPastTestCard(Map<String, dynamic> test) {
    return InkWell(
      onTap: () => print('Detail předchozího testu: ${test['title']}'),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('${test['date']} • Skóre: ${test['score']}', style: const TextStyle(color: Colors.grey, fontSize: 12.0)),
                ],
              ),
            ),
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 20.0),
          ],
        ),
      ),
    );
  }
}