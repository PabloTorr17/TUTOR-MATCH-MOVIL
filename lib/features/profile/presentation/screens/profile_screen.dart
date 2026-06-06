// lib/features/profile/presentation/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../auth/data/auth_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _bioCtrl = TextEditingController();
  final _subjectsCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _bioCtrl.text = user?.profile?.bio ?? '';
    _subjectsCtrl.text = user?.profile?.subjects.join(', ') ?? '';
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _subjectsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = {
        'bio': _bioCtrl.text,
        'subjects': _subjectsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      };
      await ApiClient().patch('/users/me', data: payload);
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Perfil actualizado'),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {} finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _becomeTutor() async {
    await ref.read(authProvider.notifier).addRole('tutor');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Ahora eres tutor. Puedes publicar asesorias.'),
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _editing = !_editing),
            child: Text(_editing ? 'Cancelar' : 'Editar',
              style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Profile header
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              AppAvatar(imageUrl: user.avatarUrl, name: user.fullName, size: 64),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text('${user.career} · ${user.semester}° Sem.',
                  style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
                const SizedBox(height: 6),
                Wrap(spacing: 5, children: user.roles.map((r) => AppTag(r,
                  color: r == 'tutor' ? TagColor.green : r == 'admin' ? TagColor.amber : TagColor.defaultTag,
                )).toList()),
              ])),
            ]),
            const SizedBox(height: 14),
            const Divider(color: AppColors.line, thickness: 1),
            const SizedBox(height: 14),

            if (!_editing) ...[
              if (user.profile?.bio.isNotEmpty == true)
                Text(user.profile!.bio, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6))
              else
                Text('Sin descripcion. Toca Editar para agregar una.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
              if (user.profile?.subjects.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                const SectionLabel('Materias'),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: user.profile!.subjects.map((s) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.line)),
                    child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
                  )
                ).toList()),
              ],
            ] else ...[
              TextFormField(controller: _bioCtrl, maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripcion'),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _subjectsCtrl,
                decoration: const InputDecoration(labelText: 'Materias (separadas por coma)'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Guardar cambios', loading: _saving, onPressed: _save),
            ],
          ])),

          const SizedBox(height: 12),

          // Stats
          if (user.profile != null)
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Estadisticas', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              Row(children: [
                _StatTile(user.profile!.rating > 0 ? user.profile!.rating.toStringAsFixed(1) : 'N/A', 'Rating'),
                const SizedBox(width: 10),
                _StatTile('${user.profile!.totalSessions}', 'Asesorias'),
                const SizedBox(width: 10),
                _StatTile('${user.profile!.attendanceRate.toInt()}%', 'Asistencia'),
              ]),
            ])),

          const SizedBox(height: 12),

          // Despues del card de estadisticas en profile_screen.dart
          AppCard(
            onTap: () => context.push('/my-sessions'),
            child: Row(children: [
              const Icon(Icons.history_rounded, size: 18, color: AppColors.ink3),
              const SizedBox(width: 12),
              const Expanded(child: Text('Mis asesorias', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
              const Icon(Icons.chevron_right_rounded, color: AppColors.ink4),
            ]),
          ),

          // Account info
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cuenta', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _InfoRow('Email', user.email),
            _InfoRow('Roles', user.roles.join(', ')),
          ])),

          const SizedBox(height: 12),

          // Become tutor CTA
          if (!user.isTutor) ...[
            AppCard(
              backgroundColor: AppColors.greenDim,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Convertirte en tutor', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('Comparte tu conocimiento, ayuda a otros estudiantes y construye tu reputacion academica.',
                  style: TextStyle(fontSize: 13, color: AppColors.ink3, height: 1.5)),
                const SizedBox(height: 14),
                GreenButton(label: 'Activar rol de tutor', onPressed: _becomeTutor),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Logout
          AppOutlineButton(
            label: 'Cerrar sesion',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!mounted) return;
              context.go('/login');
            },
          ),

          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile(this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line)),
      child: Column(children: [
        Text(value, style: GoogleFonts.bebasNeue(fontSize: 26, color: AppColors.ink, letterSpacing: 1)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.ink4, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.ink4, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.ink2))),
    ]),
  );
}
