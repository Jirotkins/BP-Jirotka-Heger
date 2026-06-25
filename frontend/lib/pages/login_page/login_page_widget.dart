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
          backgroundColor: Theme.of(context).colorScheme.error,
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
      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Pozadí mimo okno
      body: SafeArea(
        // Pokud je klávesnice schovaná, je to uprostřed. Pokud vyjede, začne se to scrollovat.
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0), // Padding zaručí, že box nebude nalepený na okrajích
            child: Container(
              width: 400.0,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 20.0, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 48.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HLAVIČKA A IKONA
                  Column(
                    children: [
                      Icon(Icons.school_rounded, color: Theme.of(context).colorScheme.primary, size: 48.0),
                      const SizedBox(height: 16.0),
                      Text(
                        'Přihlášení', 
                        textAlign: TextAlign.center, 
                        style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)
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
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: _isStudent ? 'Přihlašovací kód' : 'Email',
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16.0),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest, // Šedé pozadí pole
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                          border: _inputBorder(),
                          enabledBorder: _inputBorder(),
                          focusedBorder: _inputBorder().copyWith(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.5)),
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
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Heslo',
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16.0),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                          border: _inputBorder(),
                          enabledBorder: _inputBorder(),
                          focusedBorder: _inputBorder().copyWith(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.5)),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              icon: Icon(_isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Theme.of(context).colorScheme.secondary),
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      disabledBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                      minimumSize: const Size(double.infinity, 56.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2))
                      : Text('Přihlásit se', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18.0, fontWeight: FontWeight.bold)),
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