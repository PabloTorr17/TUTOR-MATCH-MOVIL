// lib/features/auth/presentation/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/auth_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _careerCtrl  = TextEditingController();
  int _semester = 1;
  bool _showPass = false;

  static const _careers = [
    'Ingenieria en Sistemas Computacionales',
    'Ingenieria Industrial',
    'Ingenieria Mecatronica',
    'Ingenieria Civil',
    'Administracion de Empresas',
    'Contaduria Publica',
    'Derecho', 'Medicina', 'Psicologia',
    'Diseno Grafico', 'Arquitectura',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _careerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      career: _careerCtrl.text,
      semester: _semester,
    );
    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.isAuthenticated) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () { ref.read(authProvider.notifier).clearError(); context.go('/login'); },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Crear cuenta', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 6),
            Text('Unete a la comunidad de aprendizaje de tu campus',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink3)),
            const SizedBox(height: 28),

            if (auth.error != null) ...[
              ErrorBanner(auth.error!),
              const SizedBox(height: 16),
            ],

            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Minimo 2 caracteres' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Correo institucional'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email invalido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: !_showPass,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Contrasena',
                    hintText: 'Min 8 chars, mayusculas y numeros',
                    suffixIcon: IconButton(
                      icon: Icon(_showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.ink3),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8) ? 'Minimo 8 caracteres' : null,
                ),
                const SizedBox(height: 14),

                // Career dropdown
                DropdownButtonFormField<String>(
                  value: _careerCtrl.text.isEmpty ? null : _careerCtrl.text,
                  decoration: const InputDecoration(labelText: 'Carrera'),
                  style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink),
                  items: _careers.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) { if (v != null) _careerCtrl.text = v; },
                  validator: (v) => v == null ? 'Selecciona tu carrera' : null,
                ),
                const SizedBox(height: 14),

                // Semester picker
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.line, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.surface,
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Semestre', style: GoogleFonts.instrumentSans(fontSize: 12, color: AppColors.ink3)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text('$_semester', style: GoogleFonts.bebasNeue(fontSize: 28, color: AppColors.ink, letterSpacing: 1)),
                      const Spacer(),
                      Row(children: [
                        _SemBtn(Icons.remove, () { if (_semester > 1) setState(() => _semester--); }),
                        const SizedBox(width: 8),
                        _SemBtn(Icons.add, () { if (_semester < 12) setState(() => _semester++); }),
                      ]),
                    ]),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.ink,
                        inactiveTrackColor: AppColors.line,
                        thumbColor: AppColors.ink,
                        overlayColor: AppColors.ink.withOpacity(0.08),
                        trackHeight: 2,
                      ),
                      child: Slider(
                        value: _semester.toDouble(),
                        min: 1, max: 12, divisions: 11,
                        onChanged: (v) => setState(() => _semester = v.round()),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Crear cuenta',
                  loading: auth.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Ya tienes cuenta? ', style: Theme.of(context).textTheme.bodySmall),
                  GestureDetector(
                    onTap: () { ref.read(authProvider.notifier).clearError(); context.go('/login'); },
                    child: Text('Iniciar sesion',
                      style: GoogleFonts.instrumentSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink, decoration: TextDecoration.underline)),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SemBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SemBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line, width: 1.5),
        borderRadius: BorderRadius.circular(6),
        color: AppColors.bg2,
      ),
      child: Icon(icon, size: 16, color: AppColors.ink),
    ),
  );
}
