import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../infra/models/user_role.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../widgets/design_system/app_image.dart';
import '../../auth/pages/widgets/registration_layout.dart';
import '../profile_controller.dart';

/// "Editar perfil" (canvas S1): foto, nome, como prefere ser chamado(a),
/// e-mail, WhatsApp, alterar senha e notificações. O profissional também
/// edita o texto de apresentação e o link da sala de atendimento.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  static const route = '/profile/edit';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (c) {
        final user = c.currentUser;
        if (user == null) {
          return const Scaffold(
            backgroundColor: PabColors.background,
            body: Center(
              child: CircularProgressIndicator(color: PabColors.accentText),
            ),
          );
        }
        final pro = user.role == UserRole.professional && c.isProfessionalView;
        final initials = user.fullName
            .trim()
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join();

        Widget settingsRow({
          required String label,
          VoidCallback? onTap,
          Widget? trailing,
          bool last = false,
        }) => InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: last
                  ? null
                  : const Border(bottom: BorderSide(color: PabColors.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PabColors.ink,
                    ),
                  ),
                ),
                trailing ??
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: PabColors.muted,
                    ),
              ],
            ),
          ),
        );

        return Form(
          key: c.formKey,
          child: RegistrationLayout(
            title: 'Editar perfil',
            onBack: () => Get.back<void>(),
            fields: [
              Column(
                children: [
                  ClipOval(
                    child: AppImage(
                      imageUrl: user.imageUrl,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 96,
                        height: 96,
                        color: PabColors.accent,
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: PabColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: c.isLoading ? null : c.editProfilePhoto,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: PabColors.accentText,
                    ),
                    child: const Text(
                      'Trocar foto',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              RegField(
                label: 'Nome completo',
                hint: 'Seu nome',
                controller: c.fullNameController,
                onChanged: (_) {},
                enabled: !c.isLoading,
                capitalization: TextCapitalization.words,
              ),
              RegField(
                label: 'Como prefere ser chamado(a)',
                hint: 'Ex.: ${user.fullName.split(' ').first}',
                controller: c.preferredNameController,
                onChanged: (_) {},
                enabled: !c.isLoading,
                capitalization: TextCapitalization.words,
                formatters: [LengthLimitingTextInputFormatter(40)],
              ),
              RegField(
                label: 'E-mail',
                hint: '',
                controller: c.emailController,
                onChanged: (_) {},
                enabled: false,
                helper: 'Para trocar o e-mail, fale com a equipe Pablife.',
              ),
              RegField(
                label: 'WhatsApp',
                hint: '(85) 9 0000-0000',
                controller: c.phoneController,
                onChanged: (_) {},
                enabled: !c.isLoading,
                keyboardType: TextInputType.phone,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TelefoneInputFormatter(),
                ],
              ),
              if (pro) ...[
                RegField(
                  label: 'Link da sala de atendimento',
                  hint: 'https://meet.google.com/…',
                  controller: c.meetingUrlController,
                  onChanged: (_) {},
                  enabled: !c.isLoading,
                  keyboardType: TextInputType.url,
                  helper:
                      'O paciente recebe o link só na hora da consulta, a '
                      'partir de 15 minutos antes.',
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Sobre você',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PabColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: c.descriptionController,
                      enabled: !c.isLoading,
                      minLines: 4,
                      maxLines: 10,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Como você atende, abordagem, experiência…',
                        filled: true,
                        fillColor: PabColors.card,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: PabColors.lineStrong,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: PabColors.accent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: PabColors.card,
                  border: Border.all(color: PabColors.line),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    settingsRow(
                      label: 'Alterar senha',
                      onTap: c.changePassword,
                    ),
                    settingsRow(
                      label: 'Receber notificações',
                      last: true,
                      onTap: () => c.setPushNotifications(!c.pushNotifications),
                      trailing: Switch(
                        value: c.pushNotifications,
                        onChanged: c.setPushNotifications,
                        activeThumbColor: PabColors.card,
                        activeTrackColor: PabColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            footer: [
              RegPrimaryButton(
                label: 'Salvar alterações',
                loading: c.isLoading,
                onTap: c.saveProfile,
              ),
            ],
          ),
        );
      },
    );
  }
}
