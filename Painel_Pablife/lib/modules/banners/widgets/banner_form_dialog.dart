import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:painel_pablife/shared/themes/app_colors.dart';
import 'package:painel_pablife/widgets/design_system/text_default.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:painel_pablife/infra/models/banner_model.dart';
import 'package:painel_pablife/widgets/design_system/app_text_form_field.dart';

class BannerFormDialog extends StatelessWidget {
  final BannerModel? editing;
  const BannerFormDialog({super.key, this.editing});

  @override
  Widget build(BuildContext context) {
    final titleCtrl = TextEditingController(text: editing?.title ?? '');
    final linkCtrl = TextEditingController(text: editing?.linkUrl ?? '');
    bool isActive = editing?.isActive ?? true;
    String imageUrl = editing?.imageUrl ?? '';
    String? uploadedPath;

    Future<void> deleteStorageImage(String? path) async {
      if (path == null || path.isEmpty) return;
      try {
        final client = Supabase.instance.client;
        await client.storage.from('Banners').remove([path]);
        debugPrint('BannerFormDialog: imagem deletada $path');
      } catch (e) {
        debugPrint('BannerFormDialog: erro ao deletar $path - $e');
      }
    }

    Future<void> pickAndUploadImage(
      void Function(void Function()) setState,
    ) async {
      debugPrint('BannerFormDialog: selecionando imagem...');
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) {
        debugPrint('BannerFormDialog: seleção cancelada');
        return;
      }
      final file = picked.files.single;
      debugPrint(
        'BannerFormDialog: arquivo selecionado ${file.name} (${file.size} bytes)',
      );
      if (file.bytes == null) {
        debugPrint('BannerFormDialog: arquivo sem bytes (bytes==null)');
        return;
      }

      // Deletar imagem anterior se houver
      if (uploadedPath != null) {
        debugPrint('BannerFormDialog: deletando imagem anterior $uploadedPath');
        await deleteStorageImage(uploadedPath);
      }

      final client = Supabase.instance.client;
      final path =
          'banners/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      debugPrint('BannerFormDialog: enviando para Banners/$path');
      setState(() {});
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
          .from('Banners')
          .uploadBinary(
            path,
            file.bytes!,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      final publicUrl = client.storage.from('Banners').getPublicUrl(path);
      imageUrl = publicUrl;
      uploadedPath = path;
      debugPrint('BannerFormDialog: upload ok, url=$publicUrl');
      setState(() {});
    }

    return AlertDialog(
      title: Text(editing == null ? 'Novo banner' : 'Editar banner'),
      content: SizedBox(
        width: 420,
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextFormField(controller: titleCtrl, hintText: 'Título'),
                const SizedBox(height: 12),
                // Campo de URL removido; usamos apenas o upload para definir imageUrl
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: Icon(
                      Icons.upload,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.white
                          : AppColors.primaryGreen,
                    ),
                    label: const TextDefault(text: 'Enviar imagem'),
                    onPressed: () => pickAndUploadImage(setState),
                  ),
                ),
                const SizedBox(height: 8),
                if (imageUrl.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Imagem enviada',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 160,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: linkCtrl,
                  hintText: 'Link de redirecionamento',
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  activeColor: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.white
                      : AppColors.primaryGreen,
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v ?? true),
                  title: const Text('Ativo'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const TextDefault(text: 'Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (titleCtrl.text.trim().isEmpty || imageUrl.trim().isEmpty) {
              debugPrint(
                'BannerFormDialog: campos obrigatórios faltando (title/imageUrl)',
              );
              return;
            }
            debugPrint(
              'BannerFormDialog: salvar banner (id=${editing?.id ?? ''}) title=${titleCtrl.text.trim()} active=$isActive',
            );
            Navigator.pop(context, (
              BannerModel(
                id: editing?.id ?? '',
                title: titleCtrl.text.trim(),
                imageUrl: imageUrl.trim(),
                linkUrl: linkCtrl.text.trim(),
                isActive: isActive,
                createdAt: editing?.createdAt ?? DateTime.now(),
              ),
              uploadedPath,
            ));
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
