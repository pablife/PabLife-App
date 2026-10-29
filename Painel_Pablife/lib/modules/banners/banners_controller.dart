import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:painel_pablife/modules/banners/widgets/banner_form_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:painel_pablife/infra/models/banner_model.dart';
import 'package:painel_pablife/infra/repositories/banner_repository.dart';
import 'package:painel_pablife/shared/enums/view_mode.dart';

class BannersController extends GetxController {
  final BannerRepository _repository;

  BannersController(this._repository);

  bool loading = false;
  List<BannerModel> items = <BannerModel>[];
  ViewMode viewMode = ViewMode.grid;

  @override
  void onInit() {
    super.onInit();
    debugPrint('BannersController.onInit');
    load();
  }

  Future<void> openForm(
    BuildContext context,
    BannersController controller, [
    BannerModel? editing,
  ]) async {
    final result = await showDialog<(BannerModel, String?)>(
      context: context,
      builder: (_) => BannerFormDialog(editing: editing),
    );
    if (result != null) {
      final (banner, uploadedPath) = result;
      debugPrint(
        'BannersPage: formulário retornou banner id=${banner.id.isEmpty ? '<novo>' : banner.id}',
      );
      await controller.upsert(banner, uploadedPath);
    }
  }

  Future<void> load() async {
    debugPrint('BannersController.load: iniciando');
    loading = true;
    update();
    final response = await _repository.getAll();
    items = response.data ?? [];
    loading = false;
    debugPrint('BannersController.load: carregados ${items.length} itens');
    update();
  }

  Future<void> _deleteStorageImage(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final client = Supabase.instance.client;
      await client.storage.from('Banners').remove([path]);
      debugPrint('BannersController: imagem deletada $path');
    } catch (e) {
      debugPrint('BannersController: erro ao deletar $path - $e');
    }
  }

  Future<void> upsert(BannerModel banner, [String? uploadedPath]) async {
    final index = items.indexWhere((b) => b.id == banner.id);
    if (index >= 0) {
      debugPrint('BannersController.upsert: update id=${banner.id}');
      final response = await _repository.update(banner);
      if (response.success && response.data == true) {
        items[index] = banner;
        update();
      } else {
        debugPrint('BannersController.upsert: update falhou id=${banner.id}');
        await _deleteStorageImage(uploadedPath);
        Get.snackbar('Aviso', 'Falha ao atualizar banner');
      }
    } else {
      debugPrint('BannersController.upsert: create title=${banner.title}');
      final response = await _repository.create(banner);
      if (response.success && response.data != null) {
        debugPrint(
          'BannersController.upsert: create ok id=${response.data!.id}',
        );
        items.insert(0, response.data!);
        update();
      } else {
        debugPrint('BannersController.upsert: create falhou');
        await _deleteStorageImage(uploadedPath);
        Get.snackbar('Aviso', 'Falha ao criar banner');
      }
    }
  }

  Future<void> toggleActive(String id, bool newValue) async {
    final index = items.indexWhere((b) => b.id == id);
    if (index < 0) return;
    final current = items[index];
    final updated = BannerModel(
      id: current.id,
      title: current.title,
      imageUrl: current.imageUrl,
      linkUrl: current.linkUrl,
      isActive: newValue,
      startDate: current.startDate,
      endDate: current.endDate,
      createdAt: current.createdAt,
    );
    final response = await _repository.update(updated);
    if (response.success && response.data == true) {
      items[index] = updated;
      update();
    } else {
      Get.snackbar('Aviso', 'Falha ao alterar status');
    }
  }

  Future<void> delete(String id) async {
    debugPrint('BannersController.delete: id=$id');
    final response = await _repository.delete(id);
    if (response.success && response.data == true) {
      items.removeWhere((b) => b.id == id);
      update();
    } else {
      debugPrint('BannersController.delete: falhou id=$id');
      Get.snackbar('Aviso', 'Falha ao excluir banner');
    }
  }

  void setViewMode(ViewMode mode) {
    viewMode = mode;
    update();
  }
}
