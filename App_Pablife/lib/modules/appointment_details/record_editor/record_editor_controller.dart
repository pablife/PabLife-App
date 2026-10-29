import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/patient_record_model.dart';
import '../../../infra/repositories/patient_record_repository.dart';
import '../../../shared/mixins/loader_manager.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../../../widgets/design_system/app_dialog.dart';
import 'record_editor_arguments.dart';

class RecordEditorController extends GetxController with LoaderManagerMixin {
  final PatientRecordRepository _patientRecordRepository =
      PatientRecordRepository();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  late RecordEditorArguments args;
  late PatientRecordType recordType;

  String get typeLabel => _typeLabel(recordType);
  String get pageTitle => args.isEditing
      ? 'Editar ${_typeLabel(recordType)}'
      : '${_isFeminine(recordType) ? 'Nova' : 'Novo'} ${_typeLabel(recordType)}';

  bool get isEditing => args.isEditing;

  @override
  void onInit() {
    super.onInit();
    args = Get.arguments as RecordEditorArguments;
    recordType = args.type;

    // Se estiver editando, carrega os dados do registro
    if (args.isEditing && args.record != null) {
      titleController.text = args.record!.title;
      descriptionController.text = args.record!.description;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> saveRecord() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      AppSnackbar.to.show('Informe um título para o registro.');
      return;
    }

    if (description.isEmpty) {
      AppSnackbar.to.show('Informe o conteúdo do registro.');
      return;
    }

    changeLoading(true);

    try {
      if (isEditing && args.record != null) {
        // Atualizar registro existente
        final response = await _patientRecordRepository.updatePatientRecord(
          recordId: args.record!.id,
          title: title,
          description: description,
        );

        if (response.success) {
          Get.back(result: true);
          AppSnackbar.to.show('Registro atualizado com sucesso.');
        } else {
          AppSnackbar.to.show(
            response.message.isNotEmpty
                ? response.message
                : 'Não foi possível atualizar o registro.',
          );
        }
      } else {
        // Criar novo registro
        final response = await _patientRecordRepository.createPatientRecord(
          patientId: args.patientId,
          type: recordType,
          title: title,
          description: description,
        );

        if (response.success) {
          Get.back(result: true);
          AppSnackbar.to.show('Registro criado com sucesso.');
        } else {
          AppSnackbar.to.show(
            response.message.isNotEmpty
                ? response.message
                : 'Não foi possível criar o registro.',
          );
        }
      }
    } catch (e) {
      AppSnackbar.to.show(
        isEditing
            ? 'Erro ao atualizar registro: $e'
            : 'Erro ao criar registro: $e',
      );
    } finally {
      changeLoading(false);
    }
  }

  Future<void> deleteRecord() async {
    if (!isEditing || args.record == null) return;

    final confirmed = await AppDialog.showConfirmation(
      context: Get.context!,
      title: 'Excluir registro',
      message:
          'Tem certeza que deseja excluir este registro? Esta ação não pode ser desfeita.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
      confirmButtonColor: Colors.redAccent,
    );

    if (confirmed != true) return;

    changeLoading(true);

    try {
      await _patientRecordRepository.deletePatientRecord(args.record!.id);
      Get.back(result: true);
      AppSnackbar.to.show('Registro excluído com sucesso.');
    } catch (e) {
      AppSnackbar.to.show('Erro ao excluir registro: $e');
    } finally {
      changeLoading(false);
    }
  }

  void cancel() {
    Get.back(result: false);
  }

  String _typeLabel(PatientRecordType type) {
    switch (type) {
      case PatientRecordType.mealPlan:
        return 'Plano Alimentar';
      case PatientRecordType.prescription:
        return 'Receita';
      case PatientRecordType.observation:
        return 'Observação';
      case PatientRecordType.note:
        return 'Anotação';
      case PatientRecordType.reflection:
        return 'Reflexão';
      case PatientRecordType.practice:
        return 'Prática';
    }
  }

  bool _isFeminine(PatientRecordType type) {
    switch (type) {
      case PatientRecordType.mealPlan:
        return false;
      case PatientRecordType.prescription:
      case PatientRecordType.observation:
      case PatientRecordType.note:
      case PatientRecordType.reflection:
      case PatientRecordType.practice:
        return true;
    }
  }
}
