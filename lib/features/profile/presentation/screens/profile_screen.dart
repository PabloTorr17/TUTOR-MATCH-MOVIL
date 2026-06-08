// lib/features/profile/presentation/screens/profile_screen.dart — ACTUALIZADO
// Agrega subida de avatar, materias de interes y soporte landscape

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../auth/data/auth_repository.dart';

const _allSubjects = [
  'Calculo Diferencial', 'Calculo Integral', 'Algebra Lineal',
  'Probabilidad y Estadistica', 'Programacion Orientada a Objetos',
  'Estructuras de Datos', 'Bases de Datos', 'Algoritmos y Complejidad',
  'Redes de Computadoras', 'Sistemas Operativos', 'Desarrollo Web',
  'Inteligencia Artificial', 'Fisica I', 'Fisica II',
  'Quimica General', 'Ingles Tecnico', 'Etica Profesional',
  'Administracion de Proyectos',
];

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _bioCtrl      = TextEditingController();
  final _subjectsCtrl = TextEditingController();
  bool _editing       = false;
  bool _saving        = false;
  bool _uploadingAvatar = false;
  List<String> _interests = [];
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _subjectsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiClient().get('/users/me');
      final data = response.data['data'] as Map<String, dynamic>;
      setState(() {
        _profile = data;
        _bioCtrl.text = data['profile']?['bio'] ?? '';
        _subjectsCtrl.text = (data['profile']?['subjects'] as List? ?? []).join(', ');
        _interests = List<String>.from(data['profile']?['interests'] ?? []);
      });
    } catch (_) {}
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
      _showSuccess('Perfil actualizado');
    } catch (_) {
      _showError('Error guardando perfil');
    } finally {
      setState(() => _saving = false);
    }
  }

  // ── Subir avatar ─────────────────────────────────────────
  Future<void> _pickAvatar(ImageSource source) async {
    setState(() => _uploadingAvatar = true);
    try {
      final url = await UploadService().pickAndUploadAvatar(source: source);
      if (url != null) {
        setState(() {
          if (_profile != null) _profile!['avatar_url'] = url;
        });
        _showSuccess('Foto de perfil actualizada');
      }
    } catch (e) {
      _showError('Error subiendo imagen');
    } finally {
      setState(() => _uploadingAvatar = false);
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Galeria'),
            onTap: () { Navigator.pop(context); _pickAvatar(ImageSource.gallery); },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Camara'),
            onTap: () { Navigator.pop(context); _pickAvatar(ImageSource.camera); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Materias de interes ──────────────────────────────────
  Future<void> _saveInterests() async {
    try {
      await ApiClient().dio.put('/notifications/interests', data: {'interests': _interests});
      _showSuccess('Intereses actualizados');
    } catch (_) {
      _showError('Error actualizando intereses');
    }
  }

  void _showInterestsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) => Column(children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Text('Materias de interes', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () { Navigator.pop(ctx); _saveInterests(); },
                  child: Text('Guardar', style: GoogleFonts.instrumentSans(
                    fontWeight: FontWeight.w700, color: AppColors.ink)),
                ),
              ]),
            ),
            Expanded(
              child: ListView(controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _allSubjects.map((subject) {
                  final selected = _interests.contains(subject);
                  return CheckboxListTile(
                    value: selected,
                    title: Text(subject, style: const TextStyle(fontSize: 13)),
                    activeColor: AppColors.ink,
                    checkColor: AppColors.surface,
                    dense: true,
                    onChanged: (v) {
                      setModal(() {
                        if (v == true) {
                          _interests = [..._interests, subject];
                        } else {
                          _interests = _interests.where((s) => s != subject).toList();
                        }
                      });
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: AppColors.red,
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
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return _buildLandscape(user);
          }
          return _buildPortrait(user);
        },
      ),
    );
  }

  Widget _buildPortrait(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildProfileCard(user),
        const SizedBox(height: 12),
        _buildInterestsCard(),
        const SizedBox(height: 12),
        _buildStatsCard(),
        const SizedBox(height: 12),
        _buildAccountCard(user),
        const SizedBox(height: 12),
        _buildBecomeTutorCard(user),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => context.push('/my-sessions'),
          child: Row(children: [
            const Icon(Icons.history_rounded, size: 18, color: AppColors.ink3),
            const SizedBox(width: 12),
            const Expanded(child: Text('Mis asesorias',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.ink4),
          ]),
        ),
        const SizedBox(height: 12),
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
    );
  }

  Widget _buildLandscape(user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel izquierdo — avatar y stats
        SizedBox(
          width: 240,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _buildAvatarSection(user),
              const SizedBox(height: 12),
              _buildStatsCard(),
              const SizedBox(height: 12),
              _buildAccountCard(user),
            ]),
          ),
        ),
        const VerticalDivider(width: 1, color: AppColors.line),
        // Panel derecho — edicion y opciones
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _buildEditSection(),
              const SizedBox(height: 12),
              _buildInterestsCard(),
              const SizedBox(height: 12),
              _buildBecomeTutorCard(user),
              const SizedBox(height: 12),
              AppCard(
                onTap: () => context.push('/my-sessions'),
                child: Row(children: [
                  const Icon(Icons.history_rounded, size: 18, color: AppColors.ink3),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Mis asesorias',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.ink4),
                ]),
              ),
              const SizedBox(height: 12),
              AppOutlineButton(
                label: 'Cerrar sesion',
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (!mounted) return;
                  context.go('/login');
                },
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(user) {
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildAvatarSection(user),
      const SizedBox(height: 14),
      const Divider(color: AppColors.line),
      const SizedBox(height: 14),
      _buildEditSection(),
    ]));
  }

  Widget _buildAvatarSection(user) {
    return Row(children: [
      Stack(children: [
        AppAvatar(
          imageUrl: _profile?['avatar_url'] ?? user.avatarUrl,
          name: user.fullName,
          size: 64,
        ),
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: _showAvatarOptions,
            child: Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(
                color: AppColors.ink, shape: BoxShape.circle),
              child: _uploadingAvatar
                  ? const Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.surface))
                  : const Icon(Icons.camera_alt_rounded, size: 13, color: AppColors.surface),
            ),
          ),
        ),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 2),
        Text('${user.career} · ${user.semester}° Sem.',
          style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
        const SizedBox(height: 6),
        Wrap(spacing: 5, children: user.roles.map<Widget>((r) => AppTag(r as String,
          color: (r as String) == 'tutor' ? TagColor.green
               : r == 'admin' ? TagColor.amber
               : TagColor.defaultTag,
        )).toList()),
      ])),
    ]);
  }

  Widget _buildEditSection() {
    if (!_editing) {
      final bio = _profile?['profile']?['bio'] ?? '';
      final subjects = List<String>.from(_profile?['profile']?['subjects'] ?? []);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (bio.isNotEmpty)
          Text(bio, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6))
        else
          Text('Sin descripcion. Toca Editar para agregar una.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
        if (subjects.isNotEmpty) ...[
          const SizedBox(height: 12),
          const SectionLabel('Materias'),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: subjects.map((s) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.line)),
              child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
            )
          ).toList()),
        ],
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(controller: _bioCtrl, maxLines: 3,
        decoration: const InputDecoration(labelText: 'Descripcion')),
      const SizedBox(height: 12),
      TextFormField(controller: _subjectsCtrl,
        decoration: const InputDecoration(labelText: 'Materias que dominas (separadas por coma)')),
      const SizedBox(height: 16),
      PrimaryButton(label: 'Guardar cambios', loading: _saving, onPressed: _save),
    ]);
  }

  Widget _buildInterestsCard() {
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Materias de interes',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          SizedBox(height: 2),
          Text('Recibe notificaciones de nuevas asesorias',
            style: TextStyle(fontSize: 11, color: AppColors.ink3)),
        ])),
        GestureDetector(
          onTap: _showInterestsSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bg2, borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.line, width: 1.5)),
            child: Text('Editar',
              style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
      if (_interests.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 4, children: _interests.map((s) =>
          AppTag(s, color: TagColor.blue)
        ).toList()),
      ] else ...[
        const SizedBox(height: 8),
        const Text('Sin materias de interes configuradas',
          style: TextStyle(fontSize: 12, color: AppColors.ink4, fontStyle: FontStyle.italic)),
      ],
    ]));
  }

  Widget _buildStatsCard() {
    final profile = _profile?['profile'];
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Estadisticas', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
      Row(children: [
        _StatTile(profile?['rating'] > 0 ? (profile?['rating'] as num).toStringAsFixed(1) : 'N/A', 'Rating'),
        const SizedBox(width: 10),
        _StatTile('${profile?['total_sessions'] ?? 0}', 'Asesorias'),
        const SizedBox(width: 10),
        _StatTile('${(profile?['attendance_rate'] ?? 100).toInt()}%', 'Asistencia'),
      ]),
    ]));
  }

  Widget _buildAccountCard(user) {
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Cuenta', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      _InfoRow('Email', user.email),
      _InfoRow('Roles', user.roles.join(', ')),
    ]));
  }

  Widget _buildBecomeTutorCard(user) {
    if (user.isTutor) return const SizedBox.shrink();
    return AppCard(
      backgroundColor: AppColors.greenDim,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Convertirte en tutor', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('Comparte tu conocimiento y construye tu reputacion academica.',
          style: TextStyle(fontSize: 13, color: AppColors.ink3, height: 1.5)),
        const SizedBox(height: 14),
        GreenButton(
          label: 'Activar rol de tutor',
          onPressed: () async {
            await ref.read(authProvider.notifier).addRole('tutor');
            _showSuccess('Ahora eres tutor');
          },
        ),
      ]),
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
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line)),
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
      SizedBox(width: 70, child: Text(label,
        style: const TextStyle(fontSize: 12, color: AppColors.ink4, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.ink2))),
    ]),
  );
}
