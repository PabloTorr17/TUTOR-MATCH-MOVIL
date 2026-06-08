// lib/features/auth/presentation/screens/login_screen.dart
// ACTUALIZADO: Login con Google + soporte landscape
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _showPass    = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ref.read(authProvider).isAuthenticated) context.go('/dashboard');
  }

  // ── Login con Google ───────────────────────────────────────
  Future<void> _loginWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      // Supabase maneja el OAuth con Google
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.tutormatch://login-callback',
      );
      // El resultado llega via deep link en app_router.dart
      // Ver seccion de configuracion al final de este archivo
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error con Google: $e'),
        backgroundColor: AppColors.red,
      ));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ya no se pasa auth como parametro
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return _buildLandscape();
          }
          return _buildPortrait();
        },
      ),
    );
  }

  // Quitar AuthState del parametro
  Widget _buildPortrait() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 32),
          _Logo(),
          const SizedBox(height: 40),
          _Title(),
          const SizedBox(height: 32),
          _buildForm(),
          const SizedBox(height: 24),
          _Divider(),
          const SizedBox(height: 16),
          _GoogleButton(loading: _googleLoading, onTap: _loginWithGoogle),
          const SizedBox(height: 20),
          _RegisterLink(),
          const SizedBox(height: 40),
          _StatsCard(),
        ]),
      ),
    );
  }

  // Quitar AuthState del parametro
  Widget _buildLandscape() {
    return SafeArea(
      child: Row(children: [
        Expanded(
          flex: 4,
          child: Container(
            color: AppColors.ink,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(text: TextSpan(children: [
                  TextSpan(text: 'TUTOR',
                    style: GoogleFonts.bebasNeue(fontSize: 48, color: AppColors.surface, letterSpacing: 2)),
                  TextSpan(text: 'MATCH',
                    style: GoogleFonts.bebasNeue(fontSize: 48, color: AppColors.green, letterSpacing: 2)),
                ])),
                const SizedBox(height: 8),
                Text('Campus Connect',
                  style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.surface.withOpacity(0.5), letterSpacing: 1.5)),
                const SizedBox(height: 40),
                _LandscapeStat('120+', 'Tutores'),
                const SizedBox(height: 12),
                _LandscapeStat('850+', 'Estudiantes'),
                const SizedBox(height: 12),
                _LandscapeStat('30+', 'Materias'),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Bienvenido de vuelta',
                  style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('Accede a tu cuenta de TutorMatch',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink3)),
                const SizedBox(height: 24),
                _buildForm(),
                const SizedBox(height: 16),
                _Divider(),
                const SizedBox(height: 12),
                _GoogleButton(loading: _googleLoading, onTap: _loginWithGoogle),
                const SizedBox(height: 16),
                _RegisterLink(),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // Quitar AuthState del parametro, leer auth desde ref directamente
  Widget _buildForm() {
    final auth = ref.watch(authProvider);
    return Form(
      key: _formKey,
      child: Column(children: [
        if (auth.error != null) ...[
          ErrorBanner(auth.error!),
          const SizedBox(height: 14),
        ],
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
              icon: Icon(
                _showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18, color: AppColors.ink3),
              onPressed: () => setState(() => _showPass = !_showPass),
            ),
          ),
          validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Iniciar sesion',
          loading: auth.isLoading,
          onPressed: _submit,
        ),
      ]),
    );
  }
}

// ── SUBWIDGETS ────────────────────────────────────────────────
class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(children: [
      TextSpan(text: 'TUTOR',
        style: GoogleFonts.bebasNeue(fontSize: 36, color: AppColors.ink, letterSpacing: 2)),
      TextSpan(text: 'MATCH',
        style: GoogleFonts.bebasNeue(fontSize: 36, color: AppColors.green, letterSpacing: 2)),
    ]),
  );
}

class _Title extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Bienvenido de vuelta',
        style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 6),
      Text('Accede para encontrar o publicar asesorias',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink3)),
    ],
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    const Expanded(child: Divider(color: AppColors.line, thickness: 1.5)),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text('o', style: GoogleFonts.instrumentSans(fontSize: 12, color: AppColors.ink4)),
    ),
    const Expanded(child: Divider(color: AppColors.line, thickness: 1.5)),
  ]);
}

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton(
      onPressed: loading ? null : onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.line, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: AppColors.surface,
      ),
      child: loading
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Logo de Google con colores
              _GoogleLogo(),
              const SizedBox(width: 10),
              Text('Continuar con Google',
                style: GoogleFonts.instrumentSans(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ]),
    ),
  );
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 20, height: 20,
    child: CustomPaint(painter: _GoogleLogoPainter()),
  );
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Simplificado: circulo con G
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -1.57, 3.14, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        1.57, 1.57, true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        3.14, 0.79, true, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        3.93, 0.79, true, paint);

    // Centro blanco
    paint.color = AppColors.surface;
    canvas.drawCircle(center, radius * 0.55, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _RegisterLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('No tienes cuenta? ',
        style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink3)),
      GestureDetector(
        onTap: () => context.go('/register'),
        child: Text('Registrarse',
          style: GoogleFonts.instrumentSans(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink,
            decoration: TextDecoration.underline)),
      ),
    ],
  );
}

class _StatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.line, width: 1.5),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _StatItem('120+', 'Tutores'),
      _VLine(),
      _StatItem('850+', 'Estudiantes'),
      _VLine(),
      _StatItem('30+', 'Materias'),
    ]),
  );
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

class _VLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppColors.line);
}

class _LandscapeStat extends StatelessWidget {
  final String value;
  final String label;
  const _LandscapeStat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(value, style: GoogleFonts.bebasNeue(fontSize: 28, color: AppColors.green, letterSpacing: 1)),
    const SizedBox(width: 8),
    Text(label, style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.surface.withOpacity(0.6))),
  ]);
}
