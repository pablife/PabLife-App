import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../infra/middlewares/auth_guard.dart';
import '../../shared/controllers/layout_controller.dart';
import '../../shared/themes/app_colors.dart';
import '../../widgets/design_system/text_default.dart';

class Verse {
  final String id;
  final String reference;
  final String text;
  final String? translation;
  final bool active;

  Verse.fromMap(Map<String, dynamic> m)
    : id = m['id'] as String,
      reference = m['reference'] as String,
      text = m['text'] as String,
      translation = m['translation'] as String?,
      active = m['active'] as bool? ?? true;
}

class VersesController extends GetxController {
  final _client = Supabase.instance.client;

  bool loading = true;
  String? error;
  List<Verse> items = [];
  String? todayReference;

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
          .from('tb_daily_verses')
          .select('id, reference, text, translation, active')
          .order('created_at')
          .order('id');
      items = [for (final r in rows) Verse.fromMap(Map.from(r))];
      final today = await _client.rpc('verse_of_the_day') as List;
      todayReference = today.isEmpty
          ? null
          : (today.first as Map)['reference'] as String?;
    } catch (e) {
      error = 'Não foi possível carregar os versículos: $e';
    }
    loading = false;
    update();
  }

  Future<void> save({
    String? id,
    required String reference,
    required String text,
    String? translation,
  }) async {
    final data = {
      'reference': reference.trim(),
      'text': text.trim(),
      'translation': (translation?.trim().isEmpty ?? true)
          ? null
          : translation!.trim(),
    };
    try {
      if (id == null) {
        await _client.from('tb_daily_verses').insert({
          ...data,
          'created_by': _client.auth.currentUser?.id,
        });
      } else {
        await _client.from('tb_daily_verses').update(data).eq('id', id);
      }
      await load();
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível salvar: $e');
    }
  }

  Future<void> setActive(Verse v, bool active) async {
    try {
      await _client
          .from('tb_daily_verses')
          .update({'active': active})
          .eq('id', v.id);
      await load();
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível salvar: $e');
    }
  }
}

/// Aba "Versículos": a lista do card "Versículo do dia" do app. O app
/// mostra um por dia, na ordem da lista, e recomeça quando acaba.
class VersesPage extends StatelessWidget {
  const VersesPage({super.key});

  static const route = '/versiculos';

  static GetPage get page => GetPage(
    name: route,
    page: () => const VersesPage(),
    middlewares: [AuthGuard()],
    binding: BindingsBuilder(() => Get.lazyPut(VersesController.new)),
  );

  Future<void> _edit(
    BuildContext context,
    VersesController c, [
    Verse? v,
  ]) async {
    final reference = TextEditingController(text: v?.reference);
    final text = TextEditingController(text: v?.text);
    final translation = TextEditingController(text: v?.translation);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(v == null ? 'Novo versículo' : 'Editar versículo'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: text,
                maxLines: 4,
                maxLength: 600,
                decoration: const InputDecoration(
                  labelText: 'Texto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reference,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Referência',
                  hintText: 'Ex.: Salmos 23:1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: translation,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Tradução (opcional)',
                  hintText: 'Use uma tradução que vocês podem publicar',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok == true &&
        reference.text.trim().length >= 3 &&
        text.text.trim().length >= 5) {
      await c.save(
        id: v?.id,
        reference: reference.text,
        text: text.text,
        translation: translation.text,
      );
    } else if (ok == true) {
      Get.snackbar('Faltou preencher', 'Escreva o texto e a referência.');
    }
    reference.dispose();
    text.dispose();
    translation.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Get.find<LayoutController>().updateTitle('Versículos');
    return GetBuilder<VersesController>(
      builder: (c) => Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          onPressed: () => _edit(context, c),
          icon: const Icon(Icons.add),
          label: const Text('Novo versículo'),
        ),
        body: c.loading
            ? const Center(child: CircularProgressIndicator())
            : c.error != null
            ? Center(
                child: TextDefault(
                  text: c.error!,
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  TextDefault(
                    text: c.todayReference == null
                        ? 'Nenhum versículo ativo: o card fica escondido no app.'
                        : 'Hoje o app mostra: ${c.todayReference}. Um por dia, '
                              'na ordem desta lista.',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  for (final v in c.items)
                    Card(
                      child: ListTile(
                        title: Text(
                          '“${v.text}”',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: v.active ? null : AppColors.textSecondary,
                          ),
                        ),
                        subtitle: Text(
                          [
                            v.reference,
                            if (v.translation != null) v.translation!,
                            if (!v.active) 'desativado',
                          ].join(' · '),
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Switch(
                              value: v.active,
                              onChanged: (on) => c.setActive(v, on),
                            ),
                            IconButton(
                              tooltip: 'Editar',
                              onPressed: () => _edit(context, c, v),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
