import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../infra/models/professional_type.dart';
import '../../../shared/themes/pab_colors.dart';
import '../controllers/sign_up_controller.dart';
import 'widgets/registration_layout.dart';

/// "Criar conta" (canvas E3) para o usuário; para o profissional, "Seus
/// dados" (canvas PC1, passo 1 de 3).
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  static const route = '/auth/signup';

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SignUpController>(
      builder: (c) {
        final pro = c.isProfessional;
        final showErr = c.touched && c.missing.isNotEmpty;

        final passwordSuffix = IconButton(
          tooltip: _showPassword ? 'Ocultar senha' : 'Mostrar senha',
          onPressed: () => setState(() => _showPassword = !_showPassword),
          icon: Icon(
            _showPassword ? Icons.visibility_off : Icons.visibility,
            color: PabColors.muted,
          ),
        );

        return RegistrationLayout(
          title: pro ? 'Seus dados' : 'Criar conta',
          step: pro
              ? 'Cadastro do profissional · passo 1 de 3'
              : c.isStudent
              ? 'Passo 1 de 2 · seus dados'
              : 'Seus dados',
          progress: pro ? 1 : null,
          maxWidth: pro ? 560 : 520,
          onBack: () => Get.back<void>(),
          fields: [
            RegField(
              label: 'Nome completo',
              hint: pro
                  ? 'Como está no registro do conselho'
                  : 'Como está no seu documento',
              initialValue: c.fullName,
              onChanged: c.updateFullName,
              autofillHints: const [AutofillHints.name],
              capitalization: TextCapitalization.words,
            ),
            RegField(
              label: 'E-mail',
              hint: pro ? 'nome@exemplo.com' : 'seu@email.com',
              initialValue: c.email,
              onChanged: c.updateEmail,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            RegField(
              label: 'WhatsApp',
              hint: '(85) 9 0000-0000',
              onChanged: c.updatePhone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                TelefoneInputFormatter(),
              ],
              helper: pro
                  ? null
                  : 'Sua profissional usa para falar com você sobre a consulta.',
            ),
            RegField(
              label: 'CPF',
              hint: '000.000.000-00',
              onChanged: c.updateCpfDocument,
              keyboardType: TextInputType.number,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                CpfInputFormatter(),
              ],
              helper: 'Usado no pagamento e para proteger sua conta.',
            ),
            RegField(
              label: 'Senha',
              hint: pro ? 'Pelo menos 8 caracteres' : 'Mínimo de 8 caracteres',
              onChanged: c.updatePassword,
              obscure: !_showPassword,
              autofillHints: const [AutofillHints.newPassword],
              suffix: passwordSuffix,
            ),
            if (pro) ..._professionalFields(c) else _StudentCard(controller: c),
            RegCheckbox(
              value: c.termsAccepted,
              onChanged: c.updateTerms,
              boxed: pro,
              text: pro
                  ? 'Li e aceito os termos de uso para profissionais e a '
                        'política de privacidade. Atendimentos são online, '
                        'pela sala Pablife.'
                  : 'Li e aceito os Termos de uso e a Política de '
                        'privacidade da Pablife.',
            ),
          ],
          footer: [
            RegPrimaryButton(
              label: pro
                  ? 'Continuar'
                  : c.isStudent
                  ? 'Continuar para o comprovante'
                  : 'Criar minha conta',
              loading: c.isLoading,
              dim: c.missing.isNotEmpty,
              onTap: c.continueFirstStep,
            ),
            if (showErr) RegError(c.missingText),
            if (c.error != null) RegError(c.error!),
          ],
        );
      },
    );
  }

  List<Widget> _professionalFields(SignUpController c) {
    final regLabel = switch (c.profession) {
      ProfessionalType.nutritionist => 'CRN',
      ProfessionalType.psychologist => 'CRP',
      null => 'Registro (CRP ou CRN)',
    };
    final regHint = c.profession == ProfessionalType.nutritionist
        ? 'Conselho Regional de Nutricionistas · ex.: CRN 6, número 12345'
        : 'Conselho Regional de Psicologia · ex.: CRP 11, número 12345';

    Widget option(ProfessionalType type, String label) {
      final on = c.profession == type;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: Material(
            color: on ? PabColors.ink : PabColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: on ? PabColors.ink : PabColors.line,
                width: on ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: () => c.updateProfession(type),
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
        ),
      );
    }

    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Profissão',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: PabColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              option(ProfessionalType.psychologist, 'Psicóloga(o)'),
              const SizedBox(width: 8),
              option(ProfessionalType.nutritionist, 'Nutricionista'),
            ],
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: RegField(
                  label: regLabel,
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
          const SizedBox(height: 6),
          Text(
            regHint,
            style: const TextStyle(fontSize: 12, color: PabColors.muted),
          ),
        ],
      ),
    ];
  }
}

/// "Sou estudante": liga o desconto de 10% e o passo do comprovante.
class _StudentCard extends StatelessWidget {
  final SignUpController controller;

  const _StudentCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final on = controller.isStudent;
    return Semantics(
      toggled: on,
      button: true,
      label: 'Sou estudante. Ganhe 10% de desconto em qualquer plano.',
      excludeSemantics: true,
      child: Material(
        color: on ? PabColors.soft : PabColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: on ? PabColors.accent : PabColors.line,
            width: on ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: controller.toggleStudent,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PabColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    size: 22,
                    color: PabColors.accentText,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sou estudante',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: PabColors.ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ganhe 10% de desconto em qualquer plano. Você envia '
                        'o comprovante no próximo passo.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Color(0xFF2E4446),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 26,
                    padding: const EdgeInsets.all(3),
                    alignment: on
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: on ? PabColors.accent : const Color(0xFFC9D3D4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
