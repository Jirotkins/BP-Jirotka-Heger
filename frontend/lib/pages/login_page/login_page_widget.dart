import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/role_toggle_widget.dart';
import '../../providers/auth_provider.dart';

class LoginPageWidget extends ConsumerStatefulWidget {
  const LoginPageWidget({super.key});

  @override
  ConsumerState<LoginPageWidget> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends ConsumerState<LoginPageWidget> {
  late TextEditingController _emailController;
  late FocusNode _emailFocusNode;
  late TextEditingController _passwordController;
  late FocusNode _passwordFocusNode;

  bool _isPasswordObscured = true;
  bool _isStudent = true; 
  bool _isLoading = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _emailFocusNode = FocusNode();
    _passwordController = TextEditingController();
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // --- HLAVNÍ LOGIKA PŘIHLÁŠENÍ (NYNÍ S REÁLNÝM API) ---
  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vyplňte prosím přihlašovací údaje.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Skutečné volání API přes Riverpod provider
      await ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _isStudent,
      );

      if (!mounted) return;
      
      // Pozn.: Už se nestaráme o Navigator.pushReplacementNamed, 
      // protože reaktivní widget v main.dart nás automaticky přenese do hlavní aplikace.
    } catch (e) {
      if (!mounted) return;
      // Zobrazení chybové hlášky, kterou vrátil backend nebo síťová vrstva
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()), 
          backgroundColor: Colors.red.shade700,
        )
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Pomocná metoda pro stylizaci okrajů textových polí
  OutlineInputBorder _inputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.0),
      borderSide: const BorderSide(color: Color(0xFF0056D2), width: 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA), // Světlé pozadí mimo okno
      body: SafeArea(
        // Pokud je klávesnice schovaná, je to uprostřed. Pokud vyjede, začne se to scrollovat.
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0), // Padding zaručí, že box nebude nalepený na okrajích
            child: Container(
              width: 400.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20.0, offset: Offset(0, 4))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 48.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HLAVIČKA A IKONA
                  Column(
                    children: [
                      const Icon(Icons.school_rounded, color: Color(0xFF0056D2), size: 48.0),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Přihlášení', 
                        textAlign: TextAlign.center, 
                        style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w800, color: Colors.black87)
                      ),
                    ],
                  ),
                  const SizedBox(height: 32.0),

                  // PŘEPÍNAČ ROLE
                  RoleToggleWidget(
                    initialIsStudent: _isStudent,
                    onRoleChanged: (isStudentSelected) {
                      setState(() {
                        _isStudent = isStudentSelected;
                        _emailController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 32.0),

                  // FORMULÁŘ
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // E-MAIL / KÓD
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        keyboardType: _isStudent ? TextInputType.text : TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: _isStudent ? 'Přihlašovací kód' : 'Email',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16.0),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA), // Šedé pozadí pole
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                          border: _inputBorder(),
                          enabledBorder: _inputBorder(),
                          focusedBorder: _inputBorder().copyWith(borderSide: const BorderSide(color: Color(0xFF0056D2), width: 2.5)),
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // HESLO
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: _isPasswordObscured,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Heslo',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16.0),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                          border: _inputBorder(),
                          enabledBorder: _inputBorder(),
                          focusedBorder: _inputBorder().copyWith(borderSide: const BorderSide(color: Color(0xFF0056D2), width: 2.5)),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              icon: Icon(_isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                              onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40.0),

                  // TLAČÍTKO "PŘIHLÁSIT SE"
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0056D2),
                      disabledBackgroundColor: const Color(0xFF0056D2).withOpacity(0.6),
                      minimumSize: const Size(double.infinity, 56.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Přihlásit se', style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}