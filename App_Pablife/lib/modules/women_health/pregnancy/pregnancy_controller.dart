import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../infra/repositories/pregnancy_repository.dart';
import '../../../infra/services/auth_service.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../women_health_controller.dart';
import '../women_health_data.dart';
import 'pregnancy_models.dart';

/// Estado da trilha Gestação: a gestação ativa (semana vinda do banco), o
/// conteúdo semana a semana e os registros.
class PregnancyController extends GetxController {
  static PregnancyController get to => Get.isRegistered<PregnancyController>()
      ? Get.find<PregnancyController>()
      : Get.put(PregnancyController(), permanent: true);

  final PregnancyRepository _repository;

  PregnancyController({PregnancyRepository? repository})
    : _repository = repository ?? PregnancyRepository();

  Pregnancy? pregnancy;
  List<PregnancyWeek> weeks = [];
  List<PregnancyRecord> records = [];
  bool loading = false;
  bool loaded = false;

  String? get _userId => AuthService.instance.currentUser?.id;

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Carrega (e cria, na primeira vez) a gestação a partir da data da
  /// última menstruação da trilha. Se a data mudou, atualiza.
  Future<void> load() async {
    final userId = _userId;
    if (userId == null || loading) return;
    loading = true;
    update();
    try {
      final women = Get.isRegistered<WomenHealthController>()
          ? WomenHealthController.to
          : null;
      final dum = women?.trail == WomenTrail.pregnancy
          ? women?.lastPeriod
          : null;

      var current = await _repository.current();
      if (current == null && dum != null) {
        await _repository.start(userId, dayKey(dum));
        current = await _repository.current();
      } else if (current != null &&
          dum != null &&
          current['dum'] != dayKey(dum)) {
        await _repository.updateDum(current['id'] as String, dayKey(dum));
        current = await _repository.current();
      }
      pregnancy = current == null ? null : Pregnancy.fromMap(current);

      if (weeks.isEmpty) {
        weeks = [
          for (final w in await _repository.weeks()) PregnancyWeek.fromMap(w),
        ];
      }
      records = pregnancy == null
          ? []
          : [
              for (final r in await _repository.records(pregnancy!.id))
                PregnancyRecord.fromMap(r),
            ];
      loaded = true;
    } catch (e) {
      debugPrint('Erro ao carregar a gestação: $e');
    } finally {
      loading = false;
      update();
    }
  }

  PregnancyWeek? weekData(int week) =>
      weeks.firstWhereOrNull((w) => w.week == week);

  /// Ilustração da semana de referência mais próxima.
  String? imageFor(int week) {
    final ref = week == pregnancy?.week
        ? pregnancy!.refWeek
        : nearestReferenceWeek(week);
    return weekData(ref)?.imageUrl;
  }

  /// Registros com peso, do mais antigo ao mais novo (gráfico de peso).
  List<PregnancyRecord> get weightRecords =>
      records.where((r) => r.motherWeight != null).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  /// Diferença para o peso anterior, ou null.
  double? weightGain(PregnancyRecord record) {
    final list = weightRecords;
    final i = list.indexWhere((r) => r.id == record.id);
    if (i <= 0) return null;
    return record.motherWeight! - list[i - 1].motherWeight!;
  }

  PregnancyRecord? get lastWeight =>
      weightRecords.isEmpty ? null : weightRecords.last;

  /// Salva um registro (e a foto, se houver). Devolve true se deu certo.
  Future<bool> saveRecord({
    required DateTime date,
    required PregnancyRecordType type,
    double? motherWeight,
    String? pressure,
    int? heartRate,
    int? babyWeight,
    double? babyLength,
    String? feeling,
    String? notes,
    Uint8List? photo,
    String? photoExtension,
    required bool shared,
  }) async {
    final userId = _userId;
    final p = pregnancy;
    if (userId == null || p == null) return false;
    String? photoPath;
    try {
      if (photo != null) {
        photoPath = await _repository.uploadPhoto(
          userId,
          photo,
          photoExtension ?? 'jpg',
        );
      }
      await _repository.saveRecord({
        'pregnancy_id': p.id,
        'user_id': userId,
        'record_date': dayKey(date),
        'type': type.name,
        'peso_mae': motherWeight,
        'pressao': pressure,
        'bcf': heartRate,
        'peso_estimado_bebe': babyWeight,
        'comprimento_estimado': babyLength,
        'como_estou': feeling,
        'notes': notes,
        'photo_url': photoPath,
        'shared_with_professional': shared,
        if (shared) 'shared_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Erro ao salvar o registro da gestação: $e');
      if (photoPath != null) {
        try {
          await _repository.removePhoto(photoPath);
        } catch (_) {}
      }
      AppSnackbar.to.show('Não foi possível salvar. Tente novamente.');
      return false;
    }
    await load();
    return true;
  }

  Future<bool> deleteRecord(PregnancyRecord record) async {
    try {
      await _repository.deleteRecord(record.id);
      if (record.photoPath != null) {
        try {
          await _repository.removePhoto(record.photoPath!);
        } catch (_) {}
      }
      records.removeWhere((r) => r.id == record.id);
      update();
      return true;
    } catch (e) {
      debugPrint('Erro ao apagar o registro da gestação: $e');
      AppSnackbar.to.show('Não foi possível apagar. Tente novamente.');
      return false;
    }
  }

  Future<String?> photoLink(String path) async {
    try {
      return await _repository.photoLink(path);
    } catch (e) {
      debugPrint('Erro ao abrir a foto: $e');
      return null;
    }
  }

  /// Encerra o acompanhamento (para os avisos semanais). Nada é apagado.
  Future<void> endPregnancy() async {
    try {
      final id = pregnancy?.id ?? (await _repository.current())?['id'];
      if (id == null) return;
      await _repository.end(id as String);
      pregnancy = null;
      records = [];
      update();
    } catch (e) {
      debugPrint('Erro ao encerrar a gestação: $e');
    }
  }
}
