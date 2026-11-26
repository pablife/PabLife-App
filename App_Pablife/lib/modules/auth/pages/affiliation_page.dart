import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../infra/models/affiliation.dart';
import '../../../infra/repositories/affiliation_repository.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../shared/utils/app_snackbar.dart';
import '../affiliation_draft.dart';
import '../controllers/sign_up_controller.dart';
import 'widgets/personal_data_fields.dart';
import 'widgets/registration_layout.dart';

/// "Seu vínculo": código de convite, organização (lista ou sugestão) e cargo.
/// No cadastro, é o passo depois de "Seus dados" e cria a conta no fim. Pelo
/// Perfil (`{'logged': true}`), só grava.
class AffiliationPage extends StatefulWidget {
  const AffiliationPage({super.key});

  static const route = '/auth/affiliation';

  /// Pelo Perfil. Devolve true se gravou.
  static Future<bool> openFromProfile({MyAffiliation? current}) async =>
      await Get.toNamed<bool>(
        route,
        arguments: {'logged': true, 'current': current},
      ) ==
      true;

  @override
  State<AffiliationPage> createState() => _AffiliationPageState();
}

class _AffiliationPageState extends State<AffiliationPage> {
  late final Map _args = Get.arguments is Map ? Get.arguments as Map : const {};
  late final bool _logged =
      _args['logged'] == true || !Get.isRegistered<SignUpController>();

  // Estado próprio quando vem do Perfil.
  final AffiliationDraft _own = AffiliationDraft();
  bool _saving = false;
  String? _error;

  // Busca na lista de organizações.
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  List<Organization> _results = const [];
  bool _searching = false;
  bool _listOpen = false;
  int _searchRun = 0;

  late final TextEditingController _code;
  late final TextEditingController _suggestion;
  late final TextEditingController _role;

  AffiliationRepository get _repo => AffiliationRepository.instance;

  AffiliationDraft get _draft =>
      _logged ? _own : Get.find<SignUpController>().affiliation;

  void _changed() {
    if (_logged) {
      setState(() => _error = null);
    } else {
      final c = Get.find<SignUpController>();
      c.error = null;
      c.update();
    }
  }

  @override
  void initState() {
    super.initState();
    final current = _args['current'];
    if (_logged && current is MyAffiliation) {
      _own.kind = current.kind;
      _own.role = current.roleTitle ?? '';
      if (current.suggestionPending) {
        _own.suggesting = true;
        _own.suggestion = current.suggestedOrganization ?? '';
      } else if (current.organizationId != null) {
        _own.organization = Organization(
          id: current.organizationId!,
          name: current.organizationName ?? 'Organização vinculada',
          kind: current.kind.organizationKinds.first,
        );
      }
    }
    _code = TextEditingController(text: _draft.code);
    _suggestion = TextEditingController(text: _draft.suggestion);
    _role = TextEditingController(text: _draft.role);
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus && !_listOpen) {
        setState(() => _listOpen = true);
        _runSearch();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    _code.dispose();
    _suggestion.dispose();
    _role.dispose();
    super.dispose();
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    setState(() => _listOpen = true);
    _debounce = Timer(const Duration(milliseconds: 300), _runSearch);
  }

  Future<void> _runSearch() async {
    final kind = _draft.kind;
    if (kind == null || !kind.hasOrganization) return;
    final run = ++_searchRun;
    setState(() => _searching = true);
    final found = await _repo.searchOrganizations(
      kinds: kind.organizationKinds,
      search: _search.text,
    );
    if (!mounted || run != _searchRun) return;
    setState(() {
      _results = found;
      _searching = false;
    });
  }

  Future<void> _applyCode() async {
    final d = _draft;
    if (d.code.trim().isEmpty || d.checking) return;
    FocusScope.of(context).unfocus();
    setState(() => d.checking = true);
    final result = await _repo.validateInvite(d.code);
    if (!mounted) return;
    setState(() {
      d.checking = false;
      d.applyCheck(result);
      if (result.valid) _listOpen = false;
    });
    _changed();
  }

  void _pick(Organization org) {
    setState(() {
      _draft.organization = org;
      _listOpen = false;
      _search.clear();
    });
    FocusScope.of(context).unfocus();
    _changed();
  }

  void _clearOrganization() {
    setState(() {
      _draft.clearOrganization();
      _code.clear();
      _listOpen = true;
    });
    _changed();
    _runSearch();
  }

  void _setSuggesting(bool on) {
    setState(() {
      _draft.suggesting = on;
      _listOpen = !on;
      if (on) _draft.clearOrganization();
      if (on) _code.clear();
    });
    _changed();
  }

  void _setKind(AffiliationKind? kind) {
    setState(() {
      _draft.setKind(kind);
      _results = const [];
    });
    _changed();
  }

  Future<void> _saveLogged() async {
    if (_own.kind == null || _saving) return;
    setState(() => _saving = true);
    final saved = await saveAffiliation(_own);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved.error != null) {
      setState(() => _error = saved.error);
      return;
    }
    Get.back<bool>(result: true);
    AppSnackbar.to.show(switch (saved.outcome) {
      'convenio' => 'Plano ${saved.planName ?? ''} liberado pelo convênio.',
      'analise' => 'Vamos conferir sua organização. Avisamos por notificação.',
      _ => 'Vínculo salvo.',
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_logged) {
      return _page(
        step: 'Seu vínculo com a organização',
        showKind: true,
        loading: _saving,
        error: _error,
        primaryLabel: 'Salvar',
        onPrimary: _saveLogged,
      );
    }
    return GetBuilder<SignUpController>(
      builder: (c) => _page(
        step: c.affiliationStep,
        showKind: false,
        loading: c.isLoading,
        error: c.error,
        primaryLabel: c.isStudent
            ? 'Continuar para o comprovante'
            : 'Criar minha conta',
        onPrimary: () => c.continueAfterAffiliation(skip: false),
        secondaryLabel: 'Preencher depois',
        onSecondary: c.isLoading
            ? null
            : () {
                _code.clear();
                _suggestion.clear();
                _role.clear();
                c.continueAfterAffiliation(skip: true);
              },
      ),
    );
  }

  Widget _page({
    required String step,
    required bool showKind,
    required bool loading,
    required String? error,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    final d = _draft;
    final kind = d.kind;
    final company = kind == AffiliationKind.partnerCompany;
    return RegistrationLayout(
      title: 'Seu vínculo',
      step: step,
      onBack: () => Get.back<void>(),
      fields: [
        if (showKind)
          RegPillChoice<AffiliationKind>(
            label: 'Você é',
            options: AffiliationKind.values,
            labelOf: (k) => k.label,
            value: kind,
            allowClear: false,
            onChanged: _setKind,
          ),
        if (kind != null && kind.hasOrganization) ...[
          _banner(company),
          _codeField(d),
          _organizationField(d, company),
          RegField(
            label: 'Cargo ou função',
            hint: 'Ex.: Agente administrativo',
            controller: _role,
            onChanged: (v) {
              d.role = v;
              _changed();
            },
            capitalization: TextCapitalization.sentences,
            formatters: [LengthLimitingTextInputFormatter(120)],
          ),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 16, color: PabColors.muted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Usamos isso só para relatórios anônimos da sua '
                  'organização. Ninguém da empresa ou da prefeitura vê seus '
                  'dados individuais.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: PabColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
      footer: [
        RegPrimaryButton(
          label: primaryLabel,
          loading: loading,
          dim: showKind
              ? kind == null
              : kind != null && kind.hasOrganization && !d.hasChoice,
          onTap: onPrimary,
        ),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 6),
          RegTextButton(label: secondaryLabel, onTap: onSecondary),
        ],
        if (error != null) RegError(error),
      ],
    );
  }

  Widget _banner(bool company) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PabColors.lilac,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            company ? Icons.business_center : Icons.account_balance,
            size: 28,
            color: PabColors.lilacText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              company
                  ? 'Se a sua empresa tem convênio com a Pablife, o código '
                        'libera o plano sem custo para você.'
                  : 'Se a sua prefeitura ou câmara tem convênio com a '
                        'Pablife, o código libera o plano sem custo para você.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF1F1B4D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeField(AffiliationDraft d) {
    final check = d.check;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: RegField(
                label: 'Código de convite (opcional)',
                hint: 'Ex.: PMFORTALEZA-7K2',
                controller: _code,
                onChanged: (v) {
                  setState(() => d.setCode(v));
                  _changed();
                },
                capitalization: TextCapitalization.characters,
                formatters: [LengthLimitingTextInputFormatter(30)],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: d.checking ? null : _applyCode,
                style: FilledButton.styleFrom(
                  backgroundColor: PabColors.accent,
                  foregroundColor: PabColors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: d.checking
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: PabColors.ink,
                        ),
                      )
                    : const Text(
                        'Aplicar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Quem tem convênio recebe o código do RH ou do órgão.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: PabColors.muted,
          ),
        ),
        if (check != null && check.valid) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PabColors.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: PabColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: PabColors.accentText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        check.organization?.name ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: PabColors.softText,
                        ),
                      ),
                      Text(
                        check.planName == null
                            ? 'Código válido.'
                            : 'Código válido. Plano ${check.planName} '
                                  'liberado pelo convênio.',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: PabColors.softText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (d.codeInvalid)
          const RegError(
            'Código não encontrado. Confira com o RH ou escolha na lista '
            'abaixo.',
          ),
      ],
    );
  }

  Widget _organizationField(AffiliationDraft d, bool company) {
    final label = company ? 'Empresa' : 'Prefeitura ou câmara';
    final link = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: PabColors.accentText,
    );
    Widget textLink(String text, VoidCallback onTap) => Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          foregroundColor: PabColors.accentText,
        ),
        child: Text(text, style: link),
      ),
    );

    if (d.suggesting) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegField(
            label: label,
            hint: 'Nome da prefeitura, câmara ou empresa',
            controller: _suggestion,
            onChanged: (v) {
              d.suggestion = v;
              _changed();
            },
            capitalization: TextCapitalization.words,
            formatters: [LengthLimitingTextInputFormatter(160)],
            helper:
                'Nossa equipe confere e adiciona à lista. Avisamos por '
                'notificação.',
          ),
          textLink('Voltar para a lista', () => _setSuggesting(false)),
        ],
      );
    }

    final org = d.organization;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: PabColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        if (org != null)
          Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
            decoration: BoxDecoration(
              color: PabColors.card,
              border: Border.all(color: PabColors.accent, width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        org.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: PabColors.ink,
                        ),
                      ),
                      if (org.place.isNotEmpty)
                        Text(
                          org.place,
                          style: const TextStyle(
                            fontSize: 12,
                            color: PabColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Trocar',
                  onPressed: _clearOrganization,
                  icon: const Icon(Icons.close, color: PabColors.muted),
                ),
              ],
            ),
          )
        else ...[
          TextField(
            controller: _search,
            focusNode: _searchFocus,
            onChanged: _onSearch,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 16, color: PabColors.ink),
            decoration: InputDecoration(
              hintText: company
                  ? 'Buscar empresa'
                  : 'Buscar prefeitura ou câmara',
              hintStyle: const TextStyle(color: PabColors.muted),
              prefixIcon: const Icon(Icons.search, color: PabColors.muted),
              filled: true,
              fillColor: PabColors.card,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: PabColors.lineStrong),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: PabColors.accent, width: 2),
              ),
            ),
          ),
          if (_listOpen) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: PabColors.card,
                border: Border.all(color: PabColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _searching && _results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: PabColors.accentText,
                          ),
                        ),
                      ),
                    )
                  : _results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Nenhuma organização com esse nome.',
                        style: TextStyle(fontSize: 13, color: PabColors.muted),
                      ),
                    )
                  : Column(
                      children: [
                        for (final o in _results)
                          InkWell(
                            onTap: () => _pick(o),
                            borderRadius: BorderRadius.circular(10),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 52),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            o.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: PabColors.ink,
                                            ),
                                          ),
                                          if (o.place.isNotEmpty)
                                            Text(
                                              o.place,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: PabColors.muted,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
          textLink(
            'Não encontrei minha organização',
            () => _setSuggesting(true),
          ),
        ],
      ],
    );
  }
}
