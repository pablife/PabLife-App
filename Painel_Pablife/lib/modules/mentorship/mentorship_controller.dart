import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:painel_pablife/modules/mentorship/mentorship_page.dart';
import 'package:painel_pablife/modules/mentorship/mentorship_routes.dart';
import '../../infra/models/mentorship_model.dart';
import '../../infra/repositories/mentorship_repository.dart';
import '../../shared/enums/view_mode.dart';
import '../../shared/utils/app_snackbar.dart';

class MentorshipController extends GetxController {
  final MentorshipRepository _repository = MentorshipRepository();

  // State
  List<MentorshipModel> mentorships = <MentorshipModel>[];
  List<MentorshipCategoryModel> categories = <MentorshipCategoryModel>[];
  bool isLoading = false;
  ViewMode viewMode = ViewMode.list;
  MentorshipModel? selectedMentorship;
  List<MentorshipModuleModel> modules = <MentorshipModuleModel>[];

  // Paginação
  static const int itemsPerPage = 15;
  int _currentPage = 1;
  int _totalMentorships = 0;
  int _totalPages = 0;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalMentorships => _totalMentorships;
  bool get hasPreviousPage => _currentPage > 1;
  bool get hasNextPage => _currentPage < _totalPages;

  // Form controllers for create/edit
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final durationController = TextEditingController();
  final descriptionController = TextEditingController();
  String? selectedCategoryId;

  // Image upload
  String? imageUrl;
  String? uploadedImagePath;

  // Module form controllers
  final moduleNameController = TextEditingController();

  // Lesson form controllers
  final lessonTitleController = TextEditingController();
  final lessonVideoUrlController = TextEditingController();
  final lessonNumberController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadMentorships();
    loadCategories();
  }

  @override
  void onClose() {
    titleController.dispose();
    authorController.dispose();
    durationController.dispose();
    descriptionController.dispose();
    moduleNameController.dispose();
    lessonTitleController.dispose();
    lessonVideoUrlController.dispose();
    lessonNumberController.dispose();
    super.onClose();
  }

  Future<void> loadMentorships() async {
    isLoading = true;
    update();

    // Buscar total de mentorias
    final countResponse = await _repository.getTotalMentorship();
    if (countResponse.success) {
      _totalMentorships = countResponse.data ?? 0;
      _totalPages = (_totalMentorships / itemsPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;
    }

    // Calcular offset baseado na página atual
    final offset = (_currentPage - 1) * itemsPerPage;

    final data = await _repository.getMentorshipsPaginated(
      offset: offset,
      limit: itemsPerPage,
    );
    mentorships = data.data ?? [];
    isLoading = false;
    update();
  }

  /// Vai para a página anterior
  Future<void> goToPreviousPage() async {
    if (!hasPreviousPage) return;
    _currentPage--;
    await loadMentorships();
  }

  /// Vai para a próxima página
  Future<void> goToNextPage() async {
    if (!hasNextPage) return;
    _currentPage++;
    await loadMentorships();
  }

  /// Vai para uma página específica
  Future<void> goToPage(int page) async {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _currentPage = page;
    await loadMentorships();
  }

  Future<void> loadCategories() async {
    final data = await _repository.getCategories();
    categories = data.data ?? [];
    update();
  }

  Future<void> loadMentorshipDetails(String id) async {
    isLoading = true;
    update();
    final mentorshipRes = await _repository.getMentorshipById(id);
    selectedMentorship = mentorshipRes.data;

    if (mentorshipRes.success && mentorshipRes.data != null) {
      final modulesData = await _repository.getModulesByMentorship(id);
      modules = modulesData.data ?? [];
    }
    isLoading = false;
    update();
  }

  Future<bool> createMentorship({
    required String title,
    required String author,
    required int duration,
    required String description,
    required String categoryId,
    String? imageUrl,
  }) async {
    final data = {
      'title': title,
      'author': author,
      'duration': duration,
      'description': description,
      'category_id': categoryId,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    debugPrint('📝 Criando mentoria: $title');
    final result = await _repository.createMentorshipFromMap(data);
    debugPrint('✅ Resultado: ${result.success ? "Sucesso" : "Falha"}');

    if (result.success) {
      _currentPage = 1; // Voltar para primeira página após criar
      await loadMentorships();
      return true;
    } else {
      debugPrint('❌ Mostrando snackbar de erro');
      AppSnackbar.to.error('Falha ao criar mentoria');
      return false;
    }
  }

  Future<void> pickAndUploadImage() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) {
        return;
      }

      final file = picked.files.single;
      if (file.bytes == null) {
        AppSnackbar.to.error('Arquivo inválido');
        return;
      }

      // Deletar imagem anterior se houver
      if (uploadedImagePath != null) {
        await _deleteStorageImage(uploadedImagePath);
      }

      isLoading = true;
      update();

      final client = Supabase.instance.client;

      // Gerar um ID temporário para a pasta (será substituído pelo ID real após criação)
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final path = '$tempId/${file.name}';

      String ext = (file.extension ?? '').toLowerCase();
      String contentType;
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        case 'bmp':
          contentType = 'image/bmp';
          break;
        case 'svg':
          contentType = 'image/svg+xml';
          break;
        default:
          contentType = 'image/png';
      }

      await client.storage
          .from('mentorship_images')
          .uploadBinary(
            path,
            file.bytes!,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl = client.storage
          .from('mentorship_images')
          .getPublicUrl(path);
      imageUrl = publicUrl;
      uploadedImagePath = path;

      isLoading = false;
      update();

      AppSnackbar.to.success('Imagem carregada com sucesso');
    } catch (e) {
      isLoading = false;
      update();
      debugPrint('Erro ao carregar imagem: $e');
      AppSnackbar.to.error('Erro ao carregar imagem: $e');
    }
  }

  Future<void> _deleteStorageImage(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final client = Supabase.instance.client;
      await client.storage.from('mentorship_images').remove([path]);
    } catch (e) {
      debugPrint('Erro ao deletar imagem: $e');
    }
  }

  Future<void> handleCreateMentorship() async {
    isLoading = true;
    update();

    try {
      // Criar mentoria primeiro para obter o ID
      final success = await createMentorship(
        title: titleController.text.trim(),
        author: authorController.text.trim(),
        duration: int.tryParse(durationController.text.trim()) ?? 0,
        description: descriptionController.text.trim(),
        categoryId: selectedCategoryId ?? '',
        imageUrl: imageUrl,
      );

      isLoading = false;
      update();

      if (success) {
        // Se temos uma imagem com ID temporário, precisamos movê-la para a pasta do ID real
        if (uploadedImagePath != null && mentorships.isNotEmpty) {
          final newMentorship = mentorships.first;
          await _moveImageToMentorshipFolder(newMentorship.id);
        }

        clearCreateForm();
        AppSnackbar.to.success('Mentoria criada com sucesso');
        await Future.delayed(const Duration(milliseconds: 300));

        Get.toNamed(MentorshipPage.route);
      }
    } catch (e) {
      isLoading = false;
      update();
      AppSnackbar.to.error('Erro ao criar mentoria: $e');
    }
  }

  Future<void> _moveImageToMentorshipFolder(String mentorshipId) async {
    if (uploadedImagePath == null) return;

    try {
      final client = Supabase.instance.client;
      final oldPath = uploadedImagePath!;
      final fileName = oldPath.split('/').last;
      final newPath = '$mentorshipId/$fileName';

      // Download da imagem temporária
      final imageBytes = await client.storage
          .from('mentorship_images')
          .download(oldPath);

      // Upload na pasta definitiva
      await client.storage
          .from('mentorship_images')
          .uploadBinary(
            newPath,
            imageBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Deletar imagem temporária
      await client.storage.from('mentorship_images').remove([oldPath]);

      // Atualizar URL no banco
      final newUrl = client.storage
          .from('mentorship_images')
          .getPublicUrl(newPath);
      await _repository.updateMentorship(mentorshipId, {'image_url': newUrl});

      uploadedImagePath = null;
      imageUrl = null;
    } catch (e) {
      debugPrint('Erro ao mover imagem: $e');
    }
  }

  void clearCreateForm() {
    titleController.clear();
    authorController.clear();
    durationController.clear();
    descriptionController.clear();
    selectedCategoryId = null;
    imageUrl = null;
    uploadedImagePath = null;
    update();
  }

  void initEditForm(MentorshipModel mentorship) {
    titleController.text = mentorship.title;
    authorController.text = mentorship.author;
    durationController.text = mentorship.duration.toString();
    descriptionController.text = mentorship.description;
    selectedCategoryId = mentorship.categoryId;
    imageUrl = mentorship.imageUrl;
    uploadedImagePath = null;
  }

  Future<void> handleUpdateMentorship(String id) async {
    final success = await updateMentorship(
      id: id,
      title: titleController.text.trim(),
      author: authorController.text.trim(),
      duration: int.tryParse(durationController.text.trim()) ?? 0,
      description: descriptionController.text.trim(),
      categoryId: selectedCategoryId ?? '',
      imageUrl: imageUrl,
    );

    if (success) {
      Get.back();
    }
  }

  // Module methods
  void initModuleForm({String? moduleId, String? moduleName}) {
    if (moduleId != null && moduleName != null) {
      moduleNameController.text = moduleName;
    } else {
      moduleNameController.clear();
    }
  }

  Future<void> handleSaveModule({
    String? mentorshipId,
    String? moduleId,
  }) async {
    if (moduleId == null && mentorshipId == null) {
      AppSnackbar.to.error('Dados inválidos');
      return;
    }

    isLoading = true;
    update();

    try {
      bool success;
      if (moduleId != null) {
        final updateRes = await _repository.updateModule(
          moduleId,
          moduleNameController.text.trim(),
        );
        success = updateRes.success;
      } else {
        final result = await _repository.createModule(
          mentoringId: mentorshipId!,
          name: moduleNameController.text.trim(),
        );
        success = result.success;
      }

      isLoading = false;
      update();

      if (success) {
        if (mentorshipId != null) {
          await loadMentorshipDetails(mentorshipId);
        }
        await Future.delayed(const Duration(milliseconds: 300));

        await Future.delayed(const Duration(milliseconds: 300));
        Get.back(result: true);
        Get.toNamed(
          MentorshipRoutes.mentorshipDetails,
          arguments: mentorshipId,
        );

        AppSnackbar.to.success(
          moduleId != null ? 'Módulo atualizado' : 'Módulo criado',
        );
      } else {
        AppSnackbar.to.error('Falha ao salvar módulo');
      }
    } catch (e) {
      isLoading = false;
      update();
      AppSnackbar.to.error('Erro ao salvar módulo: $e');
    }
  }

  // Lesson methods
  void initLessonForm({
    String? lessonId,
    int? lessonNumber,
    String? title,
    String? videoUrl,
  }) {
    if (lessonId != null) {
      lessonNumberController.text = lessonNumber?.toString() ?? '';
      lessonTitleController.text = title ?? '';
      lessonVideoUrlController.text = videoUrl ?? '';
    } else {
      lessonNumberController.clear();
      lessonTitleController.clear();
      lessonVideoUrlController.clear();
    }
  }

  Future<void> handleSaveLesson({
    required String moduleId,
    String? lessonId,
    String? mentorshipId,
  }) async {
    final lessonNumber = int.tryParse(lessonNumberController.text.trim()) ?? 1;

    isLoading = true;
    update();

    bool success;
    try {
      if (lessonId != null) {
        final updateRes = await _repository.updateLesson(
          id: lessonId,
          lessonNumber: lessonNumber,
          title: lessonTitleController.text.trim(),
          videoUrl: lessonVideoUrlController.text.trim(),
        );
        success = updateRes.success;
      } else {
        final result = await _repository.createLesson(
          mentoringModuleId: moduleId,
          lessonNumber: lessonNumber,
          title: lessonTitleController.text.trim(),
          videoUrl: lessonVideoUrlController.text.trim(),
        );
        success = result.success;
      }
    } catch (e) {
      success = false;
      AppSnackbar.to.error('Erro ao salvar aula: $e');
    }

    isLoading = false;
    update();

    if (success) {
      if (mentorshipId != null) {
        await loadMentorshipDetails(mentorshipId);
      }
      await Future.delayed(const Duration(milliseconds: 300));

      await Future.delayed(const Duration(milliseconds: 300));
      Get.back(closeOverlays: true);
      AppSnackbar.to.success(
        lessonId != null ? 'Aula atualizada' : 'Aula criada',
      );
    } else {
      AppSnackbar.to.error('Falha ao salvar aula');
    }
  }

  Future<bool> updateMentorship({
    required String id,
    required String title,
    required String author,
    required int duration,
    required String description,
    required String categoryId,
    String? imageUrl,
  }) async {
    final data = {
      'title': title,
      'author': author,
      'duration': duration,
      'description': description,
      'category_id': categoryId,
      if (imageUrl != null) 'image_url': imageUrl,
    };

    final result = await _repository.updateMentorship(id, data);
    if (result.success) {
      _currentPage = 1; // Voltar para primeira página após atualizar
      await loadMentorships();
      await Future.delayed(const Duration(milliseconds: 300));

      AppSnackbar.to.success('Mentoria atualizada com sucesso');
      await Future.delayed(const Duration(milliseconds: 300));
      Get.back(closeOverlays: true);

      return true;
    } else {
      AppSnackbar.to.error('Falha ao atualizar mentoria');
      return false;
    }
  }

  Future<bool> deleteMentorship(String id) async {
    final result = await _repository.deleteMentorship(id);
    if (result.success) {
      await loadMentorships();
      AppSnackbar.to.success('Mentoria desativada com sucesso');
      return true;
    } else {
      AppSnackbar.to.error('Falha ao desativar mentoria');
      return false;
    }
  }

  Future<bool> toggleMentorshipStatus(String id, bool currentStatus) async {
    final result = currentStatus
        ? await _repository.deactivateMentorship(id)
        : await _repository.activateMentorship(id);

    if (result.success) {
      await loadMentorships();
      AppSnackbar.to.success(
        currentStatus
            ? 'Mentoria desativada com sucesso'
            : 'Mentoria ativada com sucesso',
      );
      return true;
    } else {
      AppSnackbar.to.error(
        currentStatus
            ? 'Falha ao desativar mentoria'
            : 'Falha ao ativar mentoria',
      );
      return false;
    }
  }

  Future<bool> createCategory(String name) async {
    final result = await _repository.createCategory(name);
    if (result.success) {
      await loadCategories();
      AppSnackbar.to.success('Categoria criada com sucesso');
      return true;
    } else {
      AppSnackbar.to.error('Falha ao criar categoria');
      return false;
    }
  }

  Future<List<ModuleLessonModel>> getLessonsByModule(String moduleId) async {
    final result = await _repository.getLessonsByModule(moduleId);
    return result.data ?? [];
  }

  void setViewMode(ViewMode mode) {
    viewMode = mode;
    update();
  }
}
