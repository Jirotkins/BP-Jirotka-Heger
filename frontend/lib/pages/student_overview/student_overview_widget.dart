import 'package:flutter/material.dart';

class StudentOverviewWidget extends StatefulWidget {
  const StudentOverviewWidget({super.key});

  @override
  State<StudentOverviewWidget> createState() => _StudentOverviewWidgetState();
}

class _StudentOverviewWidgetState extends State<StudentOverviewWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Ukázková data pro testy a předměty
  final List<Map<String, dynamic>> _activeTests = [
    {
      'title': 'Matematika – Funkce',
      'deadline': 'Dnes 23:59',
      'expiresIn': '45 min',
    }
  ];

  final List<Map<String, dynamic>> _mySubjects = [
    {'code': 'MA', 'name': 'Matematika', 'teacher': 'Ing. Petr Svoboda', 'color': Color(0xFF4285F4)},
    {'code': 'CH', 'name': 'Chemie', 'teacher': 'Mgr. Tomáš Blažek', 'color': Color(0xFFAB47DB)},
    {'code': 'FY', 'name': 'Fyzika', 'teacher': 'doc. Jana Horáková', 'color': Color(0xFF34A853)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 1,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jakub Novák',
              style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Přehled studia',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SEKCE: AKTIVNÍ TESTY
              _buildSectionHeader('Aktivní testy', _activeTests.length, Colors.red),
              const SizedBox(height: 12),
              ..._activeTests.map((test) => _buildActiveTestCard(test)).toList(),

              const SizedBox(height: 32),

              // SEKCE: MOJE PŘEDMĚTY
              _buildSectionHeader('Moje předměty', null, null),
              const SizedBox(height: 12),
              ..._mySubjects.map((sub) => _buildSubjectCard(sub)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  // Pomocný widget pro nadpis sekce s volitelným počtem v kroužku
  Widget _buildSectionHeader(String title, int? count, Color? countColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: countColor, shape: BoxShape.circle),
            child: Text(
              count.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  // Pomocný widget pro kartu aktivního testu
  Widget _buildActiveTestCard(Map<String, dynamic> test) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: Colors.red.shade300, width: 1.5),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.quiz_outlined, color: Colors.red, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Probíhá', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(test['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Dostupný do: ${test['deadline']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Text(test['expiresIn'], style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => print('Spouštím test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(80, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Spustit', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Pomocný widget pro kartu předmětu
  Widget _buildSubjectCard(Map<String, dynamic> sub) {
    return InkWell(
      onTap: () => print('Otevírám předmět: ${sub['name']}'),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: sub['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(sub['code'], style: TextStyle(color: sub['color'], fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(sub['teacher'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}