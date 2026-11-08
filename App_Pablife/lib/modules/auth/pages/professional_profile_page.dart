import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../infra/models/professional_type.dart';
import '../../../shared/themes/pab_colors.dart';
import '../controllers/professional_profile_controller.dart';
import 'widgets/registration_layout.dart';

/// "Documento do conselho" (canvas PC2, passo 2 de 3).
class ProfessionalProfilePage extends StatelessWidget {
  const ProfessionalProfilePage({super.key});

  static const route = '/auth/professional-profile';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfessionalProfileController>(
      builder: (c) {
        final showErr = c.touched && c.missing.isNotEmpty;
        return RegistrationLayout(
          title: 'Documento do conselho',
          step: 'Cadastro do profissional · passo 2 de 3',
          progress: 2,
          maxWidth: 560,
          onBack: c.goBack,
          fields: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: PabColors.soft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'A equipe Pablife confere seu registro no conselho antes de '
                'liberar o perfil para pacientes. Os arquivos ficam guardados '
                'com segurança e só a equipe autorizada vê.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: PabColors.softText,
                ),
              ),
            ),
            // Quem já tinha conta de usuário escolhe profissão e registro aqui.
            if (c.addToExistingAccount) ..._existingAccountFields(c),
            _DocCard(
              title: 'Carteira do conselho',
              subtitle: 'Frente e verso, com nome e número visíveis',
              required: true,
              fileName: c.cardName,
              onPick: () => c.pickCard(),
              onPhoto: () => c.pickCard(image: true),
              onRemove: c.removeCard,
            ),
            _DocCard(
              title: 'Diploma ou certificado de especialização',
              subtitle: 'Opcional · aparece como selo no seu perfil',
              required: false,
              fileName: c.diplomaName,
              onPick: () => c.pickDiploma(),
              onPhoto: () => c.pickDiploma(image: true),
              onRemove: c.removeDiploma,
            ),
            const Text(
              'Aceitamos JPG, PNG ou PDF de até 10 MB.',
              style: TextStyle(fontSize: 12, color: PabColors.muted),
            ),
          ],
          footer: [
            RegPrimaryButton(
              label: 'Enviar para análise',
              loading: c.isLoading,
              dim: c.missing.isNotEmpty,
              onTap: c.completeProfile,
            ),
            if (showErr)
              RegError(
                c.missing.length == 1 &&
                        c.missing.first == 'carteira do conselho'
                    ? 'Envie a carteira do conselho para continuar.'
                    : 'Falta: ${c.missing.join(', ')}.',
              ),
            if (c.error != null) RegError(c.error!),
          ],
        );
      },
    );
  }

  List<Widget> _existingAccountFields(ProfessionalProfileController c) {
    Widget option(ProfessionalType type, String label) {
      final on = c.professionalType == type;
      return Expanded(
        child: Material(
          color: on ? PabColors.ink : PabColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: on ? PabColors.ink : PabColors.line),
          ),
          child: InkWell(
            onTap: () => c.updateProfessionalType(type),
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: on ? Colors.white : PabColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return [
      Row(
        children: [
          option(ProfessionalType.psychologist, 'Psicóloga(o)'),
          const SizedBox(width: 8),
          option(ProfessionalType.nutritionist, 'Nutricionista'),
        ],
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: RegField(
              label: c.professionalType == ProfessionalType.nutritionist
                  ? 'CRN'
                  : c.professionalType == ProfessionalType.psychologist
                  ? 'CRP'
                  : 'Registro (CRP ou CRN)',
              hint: 'Número do registro',
              initialValue: c.councilNumber,
              onChanged: c.updateCouncilNumber,
              formatters: [LengthLimitingTextInputFormatter(30)],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RegField(
              label: 'Região',
              hint: '11',
              initialValue: c.councilRegion,
              onChanged: c.updateCouncilRegion,
              formatters: [LengthLimitingTextInputFormatter(10)],
            ),
          ),
        ],
      ),
      RegCheckbox(
        value: c.termsAccepted,
        onChanged: c.updateTerms,
        boxed: true,
        text:
            'Li e aceito os termos de uso para profissionais e a política '
            'de privacidade. Atendimentos são online, pela sala Pablife.',
      ),
    ];
  }
}

class _DocCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool required;
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback onPhoto;
  final VoidCallback onRemove;

  const _DocCard({
    required this.title,
    required this.subtitle,
    required this.required,
    required this.fileName,
    required this.onPick,
    required this.onPhoto,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final sent = fileName != null;
    final (tag, tagBg, tagFg) = sent
        ? ('Enviado', PabColors.soft, PabColors.softText)
        : required
        ? ('Obrigatório', const Color(0xFFFFF1D6), const Color(0xFF6B4A00))
        : ('Opcional', PabColors.lilac, PabColors.lilacText);

    Widget pickButton(String label, IconData icon, VoidCallback onTap) =>
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 16),
            label: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: PabColors.ink,
              backgroundColor: PabColors.background,
              side: const BorderSide(color: PabColors.accentText, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PabColors.card,
        border: Border.all(color: PabColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: PabColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PabColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: tagFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!sent)
            Row(
              children: [
                pickButton('Tirar foto', Icons.photo_camera_outlined, onPhoto),
                const SizedBox(width: 8),
                pickButton('Escolher arquivo', Icons.upload_file, onPick),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: PabColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: PabColors.ink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      fileName!
                          .split('.')
                          .last
                          .toUpperCase()
                          .substring(
                            0,
                            fileName!.split('.').last.length.clamp(0, 4),
                          ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fileName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: PabColors.ink,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: onRemove,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      foregroundColor: PabColors.ink,
                      side: const BorderSide(color: PabColors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Trocar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
