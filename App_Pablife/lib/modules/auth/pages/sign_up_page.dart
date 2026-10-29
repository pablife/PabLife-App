import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:brasil_fields/brasil_fields.dart';
import '../controllers/sign_up_controller.dart';
import '../../../widgets/design_system/edge_button_rounded.dart';
import '../../../widgets/design_system/text_default.dart';
import '../../../widgets/design_system/app_text_form_field.dart';
import '../../../widgets/app_text_vector.dart';
import '../../../shared/themes/app_colors.dart';
import 'widgets/sign_up_account_type_selector_widget.dart';
import 'widgets/sign_up_terms_checkbox_widget.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  static const route = '/auth/signup';

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _cpfFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void dispose() {
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _cpfFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aqua,
      body: GetBuilder<SignUpController>(
        builder: (controller) {
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: AppTextVector(width: 234, height: 71)),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.second,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 32,
                              right: 32,
                              top: 32,
                            ),
                            child: const TextDefault(
                              'Crie sua conta em poucos passos',
                              fontSize: 24,
                              textAlign: TextAlign.start,
                              fontWeight: FontWeight.w700,
                              color: AppColors.aquaText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Opacity(
                              opacity: 0.56,
                              child: const TextDefault(
                                'Preencha as informações abaixo para começar a organizar tudo em um só lugar.',
                                fontSize: 16,
                                textAlign: TextAlign.start,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: SignUpAccountTypeSelectorWidget(
                              controller: controller,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: AppTextFormField(
                              labelText: 'Nome Completo',
                              hintText: 'Seu nome completo',
                              textInputAction: TextInputAction.next,
                              onChanged: controller.updateFullName,
                              focusNode: _fullNameFocus,
                              onFieldSubmitted: (_) {
                                if (controller.isLoading) {
                                  FocusScope.of(context).unfocus();
                                  return;
                                }
                                if (_emailFocus.canRequestFocus) {
                                  _emailFocus.requestFocus();
                                } else {
                                  FocusScope.of(context).unfocus();
                                }
                              },
                              enabled: !controller.isLoading,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: AppTextFormField(
                              labelText: 'E-mail',
                              hintText: 'seu@email.com',
                              keyboardType: TextInputType.emailAddress,
                              initialValue: controller.email,
                              textInputAction: TextInputAction.next,
                              onChanged: controller.updateEmail,
                              focusNode: _emailFocus,
                              onFieldSubmitted: (_) {
                                if (controller.isLoading) {
                                  FocusScope.of(context).unfocus();
                                  return;
                                }
                                if (_phoneFocus.canRequestFocus) {
                                  _phoneFocus.requestFocus();
                                } else {
                                  FocusScope.of(context).unfocus();
                                }
                              },
                              enabled: !controller.isLoading,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: AppTextFormField(
                              labelText: 'Telefone',
                              hintText: '(11) 99999-9999',
                              keyboardType: TextInputType.number,
                              controller: controller.phoneController,
                              textInputAction: TextInputAction.next,
                              onChanged: controller.updatePhone,
                              focusNode: _phoneFocus,
                              onFieldSubmitted: (_) {
                                if (controller.isLoading) {
                                  FocusScope.of(context).unfocus();
                                  return;
                                }
                                if (_cpfFocus.canRequestFocus) {
                                  _cpfFocus.requestFocus();
                                } else {
                                  FocusScope.of(context).unfocus();
                                }
                              },
                              enabled: !controller.isLoading,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                TelefoneInputFormatter(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: AppTextFormField(
                              labelText: 'CPF',
                              hintText: '000.000.000-00',
                              keyboardType: TextInputType.number,
                              controller: controller.cpfController,
                              textInputAction: TextInputAction.next,
                              onChanged: controller.updateCpfDocument,
                              focusNode: _cpfFocus,
                              onFieldSubmitted: (_) {
                                if (controller.isLoading) {
                                  FocusScope.of(context).unfocus();
                                  return;
                                }
                                if (_passwordFocus.canRequestFocus) {
                                  _passwordFocus.requestFocus();
                                } else {
                                  FocusScope.of(context).unfocus();
                                }
                              },
                              enabled: !controller.isLoading,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                CpfInputFormatter(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: AppTextFormField(
                              labelText: 'Senha',
                              hintText: 'Mínimo 6 caracteres',
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onChanged: controller.updatePassword,
                              focusNode: _passwordFocus,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                              },
                              enabled: !controller.isLoading,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: SignUpTermsCheckboxWidget(
                              controller: controller,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Opacity(
                                    opacity: 0.56,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const TextDefault(
                                          'Já tem uma conta?',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Get.toNamed('/auth/email'),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(50, 30),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const TextDefault(
                                            'Entrar agora',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: EdgeButtonRounded(
                                  text: 'Continuar',
                                  width: 190,
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    controller.signUp();
                                  },
                                  isLoading: controller.isLoading,
                                  side: EdgeSide.left,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
