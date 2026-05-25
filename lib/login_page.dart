import 'package:flutter/material.dart';
import 'admin_console.dart';
import 'audit_log_service.dart';

const _kCredentials = {
  'admin':      {'pass': 'kiogloss2026', 'role': 'Admin'},
  'vendedor':   {'pass': 'ventas2026',   'role': 'Vendedor'},
  'supervisor': {'pass': 'super2026',    'role': 'Supervisora'},
};

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _loading = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));

    final user = _userCtrl.text.trim().toLowerCase();
    final pass = _passCtrl.text;
    final cred = _kCredentials[user];

    if (cred != null && cred['pass'] == pass) {
      final role = cred['role']!;
      await AuditLogService.log(
        'login_success',
        actor: user,
        details: {'method': 'password', 'role': role},
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, anim, __) => FadeTransition(
            opacity: anim,
            child: AdminConsole(currentUser: user, currentRole: role),
          ),
        ),
      );
    } else {
      await AuditLogService.log(
        'login_failed',
        actor: user.isEmpty ? 'unknown' : user,
        details: {'reason': 'invalid_credentials'},
      );
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Usuario o contraseña incorrectos'),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F3FF),
              Color(0xFFEDE9FE),
              Color(0xFFDDD6FE),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _loginCard(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC4B5FD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withAlpha(25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withAlpha(70),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: const Icon(Icons.spa_outlined, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Kiogloss',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B4B),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Panel de Administración',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _userCtrl,
              style: const TextStyle(color: Color(0xFF1E1B4B)),
              decoration: _decoration('Usuario', Icons.person_outline),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingrese el usuario' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              style: const TextStyle(color: Color(0xFF1E1B4B)),
              decoration: _decoration('Contraseña', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF7C3AED),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingrese la contraseña' : null,
              onFieldSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Usuarios: admin · vendedor · supervisor',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF7C3AED).withAlpha(100),
                ),
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'INGRESAR',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.3,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '© 2026 Kiogloss Beauty Products',
              style: TextStyle(fontSize: 11, color: Color(0xFFB0B7C3)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
      prefixIcon: Icon(icon, color: const Color(0xFF7C3AED)),
      filled: true,
      fillColor: const Color(0xFFF5F3FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDD6FE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDD6FE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
      ),
    );
  }
}
