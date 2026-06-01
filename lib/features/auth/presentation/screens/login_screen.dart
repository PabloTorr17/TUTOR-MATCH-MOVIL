// lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.isAuthenticated) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              // Logotipo
              RichText(text: TextSpan(children: [
                TextSpan(
                  text: 'TUTOR',
                  style: GoogleFonts.bebasNeue(fontSize: 36, color: AppColors.ink, letterSpacing: 2),
                ),
                TextSpan(
                  text: 'MATCH',
                  style: GoogleFonts.bebasNeue(fontSize: 36, color: AppColors.green, letterSpacing: 2),
                ),
              ])),
              const SizedBox(height: 4),
              Text('Campus Connect',
                style: GoogleFonts.instrumentSans(fontSize: 11, color: AppColors.ink4, letterSpacing: 1.5)),

              const SizedBox(height: 40),
              Text('Bienvenido de vuelta', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 6),
              Text('Accede para encontrar o publicar asesorias',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink3)),

              const SizedBox(height: 32),
              if (auth.error != null) ...[
                ErrorBanner(auth.error!),
                const SizedBox(height: 16),
              ],
              Form(
                key: _formKey,
                child: Column(children: [
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Correo institucional'),
                    validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Contrasena',
                      suffixIcon: IconButton(
                        icon: Icon(_showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.ink3),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      ),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Iniciar sesion',
                    loading: auth.isLoading,
                    onPressed: _submit,
                  ),
                ]),
              ),

              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('No tienes cuenta? ', style: Theme.of(context).textTheme.bodySmall),
                GestureDetector(
                  onTap: () { ref.read(authProvider.notifier).clearError(); context.go('/register'); },
                  child: Text('Registrarse',
                    style: GoogleFonts.instrumentSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink,
                      decoration: TextDecoration.underline)),
                ),
              ]),

              const SizedBox(height: 40),
              // Stats decorativas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem('120+', 'Tutores'),
                    _Vline(),
                    _StatItem('850+', 'Estudiantes'),
                    _Vline(),
                    _StatItem('30+', 'Materias'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.bebasNeue(fontSize: 24, color: AppColors.green, letterSpacing: 1)),
    Text(label, style: GoogleFonts.instrumentSans(fontSize: 10, color: AppColors.ink4, letterSpacing: 0.5)),
  ]);
}

class _Vline extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppColors.line);
}
