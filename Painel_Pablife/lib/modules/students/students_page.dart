import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../infra/middlewares/auth_guard.dart';
import '../../shared/controllers/layout_controller.dart';
import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/text_default.dart';

/// Um pedido de desconto de estudante.
class StudentRequest {
  final String id;
  final String userName;
  final String userEmail;
  final String institution;
  final String course;
  final String? documentPath;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  StudentRequest.fromMap(Map<String, dynamic> m)
    : id = m['id'] as String,
      userName = (m['tb_users']?['full_name'] as String?) ?? '—',
      userEmail = (m['tb_users']?['email'] as String?) ?? '',
      institution = m['institution'] as String? ?? '',
      course = m['course'] as String? ?? '',
      documentPath = m['document_path'] as String?,
      status = m['status'] as String? ?? 'pending',
      rejectionReason = m['rejection_reason'] as String?,
      createdAt = DateTime.parse(m['created_at'] as String).toLocal(),
      reviewedAt = m['reviewed_at'] == null
          ? null
          : DateTime.parse(m['reviewed_at'] as String).toLocal();
}

class StudentsController extends GetxController {
  final _client = Supabase.instance.client;

  String filter = 'pending';
  bool loading = true;
  String? error;
  List<StudentRequest> items = [];

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final rows = await _client
          .from('tb_student_verifications')
          .select(
            'id, institution, course, document_path, status, '
            'rejection_reason, created_at, reviewed_at, '
            'tb_users!tb_student_verifications_user_id_fkey(full_name, email)',
          )
          .eq('status', filter)
          .order('created_at', ascending: filter == 'pending');
      items = [
        for (final r in rows)
          StudentRequest.fromMap(Map<String, dynamic>.from(r)),
      ];
    } catch (e) {
      error = 'Não foi possível carregar os pedidos: $e';
      items = [];
    }
    loading = false;
    update();
  }

  void setFilter(String value) {
    if (filter == value) return;
    filter = value;
    load();
  }

  /// Abre o comprovante num link temporário (10 minutos).
  Future<void> openProof(StudentRequest r) async {
    final path = r.documentPath;
    if (path == null) {
      Get.snackbar('Sem arquivo', 'A pessoa ainda não enviou o comprovante.');
      return;
    }
    try {
      final url = await _client.storage
          .from('student-proofs')
          .createSignedUrl(path, 600);
      await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível abrir o comprovante.');
    }
  }

  Future<void> review(
    StudentRequest r, {
    required bool approve,
    String? reason,
  }) async {
    try {
      await _client.rpc(
        'review_student_verification',
        params: {'p_id': r.id, 'p_approve': approve, 'p_reason': reason},
      );
      Get.snackbar(
        approve ? 'Aprovado' : 'Recusado',
        approve
            ? '${r.userName} já tem o desconto de 10%.'
            : '${r.userName} foi avisada(o) e pode enviar outro.',
      );
      await load();
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível salvar: $e');
    }
  }
}

/// Aba "Estudantes": aprovar ou recusar comprovantes do desconto de 10%.
class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  static const route = '/estudantes';

  static GetPage get page => GetPage(
    name: route,
    page: () => const StudentsPage(),
    middlewares: [AuthGuard()],
    binding: BindingsBuilder(() => Get.lazyPut(StudentsController.new)),
  );

  Future<void> _reject(
    BuildContext context,
    StudentsController c,
    StudentRequest r,
  ) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recusar comprovante'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: reason,
            maxLength: 300,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo (a pessoa vê na notificação)',
              hintText: 'Ex.: documento sem data ou ilegível',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await c.review(r, approve: false, reason: reason.text);
    }
    reason.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Get.find<LayoutController>().updateTitle('Estudantes');
    final date = DateFormat('dd/MM/yyyy HH:mm');

    return GetBuilder<StudentsController>(
      builder: (c) => Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final (value, label) in const [
                    ('pending', 'Em análise'),
                    ('approved', 'Aprovados'),
                    ('rejected', 'Recusados'),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: c.filter == value,
                      onSelected: (_) => c.setFilter(value),
                    ),
                  IconButton(
                    tooltip: 'Atualizar',
                    onPressed: c.load,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: c.loading
                  ? const Center(child: CircularProgressIndicator())
                  : c.error != null
                  ? Center(
                      child: TextDefault(
                        text: c.error!,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : c.items.isEmpty
                  ? const Center(
                      child: TextDefault(
                        text: 'Nenhum pedido aqui.',
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: c.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final r = c.items[i];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 520,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.userName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        r.userEmail,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text('${r.course} · ${r.institution}'),
                                      Text(
                                        'Enviado em ${date.format(r.createdAt)}'
                                        '${r.reviewedAt == null ? '' : ' · revisto em ${date.format(r.reviewedAt!)}'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (r.rejectionReason != null)
                                        Text(
                                          'Motivo: ${r.rejectionReason}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => c.openProof(r),
                                      icon: const Icon(
                                        Icons.description_outlined,
                                      ),
                                      label: const Text('Ver comprovante'),
                                    ),
                                    if (r.status == 'pending') ...[
                                      FilledButton.icon(
                                        onPressed: () =>
                                            c.review(r, approve: true),
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryGreen,
                                        ),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Aprovar'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _reject(context, c, r),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        icon: const Icon(Icons.close),
                                        label: const Text('Recusar'),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
