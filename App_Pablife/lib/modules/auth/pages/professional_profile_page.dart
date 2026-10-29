import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../infra/models/professional_type.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../widgets/design_system/text_default.dart';
import '../controllers/professional_profile_controller.dart';

class ProfessionalProfilePage extends StatelessWidget {
  const ProfessionalProfilePage({super.key});

  static const route = '/auth/professional-profile';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00343C),
      body: GetBuilder<ProfessionalProfileController>(
        builder: (controller) {
          return SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF00343C),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 200,
                  height: 652,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFC1CDFF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(39),
                        topRight: Radius.circular(39),
                      ),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(0, 30, 0, 32),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: TextDefault(
                            'Complete seu perfil profissional',
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00343C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: 0.56,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: TextDefault(
                              'Envie seus dados para que possamos validar sua conta como profissional',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: controller.isLoading
                                      ? null
                                      : () => controller.updateProfessionalType(
                                          ProfessionalType.nutritionist,
                                        ),
                                  child: Opacity(
                                    opacity: controller.isLoading ? 0.6 : 1.0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            controller.professionalType ==
                                                ProfessionalType.nutritionist
                                            ? const Color(0xFF00343C)
                                            : const Color(0xFFC1CDFF),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: const Color(0xFF00343C),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: TextDefault(
                                          ProfessionalType
                                              .nutritionist
                                              .displayName,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              controller.professionalType ==
                                                  ProfessionalType.nutritionist
                                              ? AppColors.white
                                              : const Color(0xFF00343C),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: controller.isLoading
                                      ? null
                                      : () => controller.updateProfessionalType(
                                          ProfessionalType.psychologist,
                                        ),
                                  child: Opacity(
                                    opacity: controller.isLoading ? 0.6 : 1.0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            controller.professionalType ==
                                                ProfessionalType.psychologist
                                            ? const Color(0xFF00343C)
                                            : const Color(0xFFC1CDFF),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: const Color(0xFF00343C),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: TextDefault(
                                          ProfessionalType
                                              .psychologist
                                              .displayName,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              controller.professionalType ==
                                                  ProfessionalType.psychologist
                                              ? AppColors.white
                                              : const Color(0xFF00343C),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextDefault(
                                'Sobre você',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF00343C),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: TextFormField(
                                  onChanged: (value) =>
                                      controller.description = value,
                                  enabled: !controller.isLoading,
                                  maxLines: 4,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).unfocus();
                                  },
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Escreva uma breve descrição sobre sua experiência e especialidades...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: GestureDetector(
                            onTap: controller.isLoading
                                ? null
                                : controller.selectDocument,
                            child: Opacity(
                              opacity: controller.isLoading ? 0.6 : 1.0,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.upload_file,
                                      size: 52,
                                      color: const Color(0xFF00343C),
                                    ),
                                    const SizedBox(height: 12),
                                    TextDefault(
                                      'Enviar Documento',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF00343C),
                                    ),
                                    if (controller.documentBase64 != null &&
                                        controller
                                            .documentBase64!
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF00343C,
                                          ).withAlpha(51),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF00343C),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextDefault(
                                                controller.documentFileName ??
                                                    "arquivo",
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF00343C),
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: TextDefault(
                            'Envie um documento que comprove sua formação (ex.: diploma ou certificado reconhecido). Esse documento será usado apenas para validação e não ficará visível para outros usuários.',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: controller.isLoading
                                    ? null
                                    : controller.goBack,
                                child: Opacity(
                                  opacity: controller.isLoading ? 0.6 : 1.0,
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0C8DA1),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.zero,
                                        bottomLeft: Radius.zero,
                                        topRight: Radius.circular(30),
                                        bottomRight: Radius.circular(30),
                                      ),
                                    ),
                                    child: Center(
                                      child: TextDefault(
                                        'Voltar',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: controller.isLoading
                                    ? null
                                    : () {
                                        FocusScope.of(context).unfocus();
                                        controller.completeProfile();
                                      },
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: controller.isLoading
                                        ? const Color(0xFF00343C).withAlpha(179)
                                        : const Color(0xFF00343C),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      bottomLeft: Radius.circular(30),
                                      topRight: Radius.zero,
                                      bottomRight: Radius.zero,
                                    ),
                                  ),
                                  child: Center(
                                    child: controller.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppColors.white,
                                                  ),
                                            ),
                                          )
                                        : const TextDefault(
                                            'Continuar',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.white,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 200),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 33,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: controller.isLoading
                            ? null
                            : controller.selectProfileImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 135,
                              height: 135,
                              decoration: BoxDecoration(
                                color: const Color(0xFF89BEC6),
                                shape: BoxShape.circle,
                              ),
                              child:
                                  controller.profileImageBase64 != null &&
                                      controller.profileImageBase64!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.memory(
                                        base64Decode(
                                          controller.profileImageBase64!,
                                        ),
                                        fit: BoxFit.cover,
                                        width: 135,
                                        height: 135,
                                      ),
                                    )
                                  : null,
                            ),
                            if (controller.profileImageBase64 == null ||
                                controller.profileImageBase64!.isEmpty) ...[
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22717D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Positioned(
                                bottom: -10,
                                child: ClipOval(
                                  child: Container(
                                    width: 100,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22717D),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(80),
                                        topRight: Radius.circular(80),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3395),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 24,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
