import '../../infra/models/affiliation.dart';
import '../../infra/repositories/affiliation_repository.dart';

/// O que a pessoa preencheu sobre o vínculo, antes de gravar. No cadastro
/// fica no SignUpController (a conta só existe no fim); no Perfil, na tela.
class AffiliationDraft {
  AffiliationKind? kind;

  /// Código de convite e o resultado de "Aplicar".
  String code = '';
  InviteCheck? check;
  bool checking = false;
  bool codeInvalid = false;

  /// Organização escolhida na lista (ou preenchida pelo código).
  Organization? organization;

  /// "Não encontrei minha organização".
  bool suggesting = false;
  String suggestion = '';

  String role = '';

  bool get worksAtOrganization => kind?.hasOrganization ?? false;

  /// O código foi conferido e vale.
  bool get usesCode => check?.valid == true && code.trim().isNotEmpty;

  /// Escolheu uma organização ou escreveu uma sugestão.
  bool get hasChoice =>
      suggesting ? suggestion.trim().length >= 2 : organization != null;

  void setKind(AffiliationKind? value) {
    if (value == kind) return;
    kind = value;
    // A organização escolhida pode não combinar com o tipo novo.
    final org = organization;
    if (org != null &&
        !(value?.organizationKinds.contains(org.kind) ?? false)) {
      clearOrganization();
    }
  }

  void setCode(String value) {
    code = value;
    check = null;
    codeInvalid = false;
  }

  /// Código válido: preenche a organização e ajusta o tipo de vínculo.
  void applyCheck(InviteCheck result) {
    check = result.valid ? result : null;
    codeInvalid = !result.valid;
    if (result.valid) {
      if (result.kind != null) kind = result.kind;
      organization = result.organization;
      suggesting = false;
    }
  }

  /// O X da organização escolhida: volta para a busca.
  void clearOrganization() {
    organization = null;
    code = '';
    check = null;
    codeInvalid = false;
  }

  /// "Preencher depois": fica só o tipo de vínculo.
  void skipDetails() {
    clearOrganization();
    suggesting = false;
    suggestion = '';
    role = '';
  }
}

/// O que foi gravado, para "Conta criada!" e o aviso do Perfil.
class AffiliationSaved {
  /// convenio (plano liberado), lista (organização da lista), analise
  /// (sugestão) ou null (só o tipo).
  final String? outcome;
  final String? organizationName;
  final String? planName;
  final DateTime? planEndsAt;
  final String? roleTitle;
  final String? error;

  const AffiliationSaved({
    this.outcome,
    this.organizationName,
    this.planName,
    this.planEndsAt,
    this.roleTitle,
    this.error,
  });

  const AffiliationSaved.failed(this.error)
    : outcome = null,
      organizationName = null,
      planName = null,
      planEndsAt = null,
      roleTitle = null;

  Map<String, dynamic> toArguments() => {
    'affiliation': outcome,
    'orgName': organizationName,
    'planName': planName,
    'planEndsAt': planEndsAt,
    'roleTitle': roleTitle,
  };
}

/// Grava o vínculo com a conta já criada: código → redeem; lista ou sugestão
/// → saveMine.
Future<AffiliationSaved> saveAffiliation(
  AffiliationDraft draft, {
  AffiliationRepository? repository,
}) async {
  final repo = repository ?? AffiliationRepository.instance;
  final kind = draft.kind;
  if (kind == null) return const AffiliationSaved();
  final role = draft.role.trim().isEmpty ? null : draft.role.trim();

  if (!kind.hasOrganization) {
    final error = await repo.saveMine(kind: kind);
    return error == null
        ? const AffiliationSaved()
        : AffiliationSaved.failed(error);
  }

  if (draft.usesCode) {
    final result = await repo.redeemInvite(draft.code, roleTitle: role);
    if (result == null || !result.valid) {
      return const AffiliationSaved.failed(
        'Não foi possível usar o código de convite. Tente de novo.',
      );
    }
    final orgName = draft.check?.organization?.name;
    if (result.planGranted) {
      return AffiliationSaved(
        outcome: 'convenio',
        organizationName: orgName,
        planName: result.planName,
        planEndsAt: result.endsAt,
        roleTitle: role,
      );
    }
    return AffiliationSaved(
      outcome: 'lista',
      organizationName: orgName,
      roleTitle: role,
    );
  }

  if (draft.suggesting && draft.suggestion.trim().length >= 2) {
    final error = await repo.saveMine(
      kind: kind,
      suggestedOrganization: draft.suggestion,
      roleTitle: role,
    );
    return error == null
        ? AffiliationSaved(
            outcome: 'analise',
            organizationName: draft.suggestion.trim(),
            roleTitle: role,
          )
        : AffiliationSaved.failed(error);
  }

  final org = draft.organization;
  final error = await repo.saveMine(
    kind: kind,
    organizationId: org?.id,
    roleTitle: role,
  );
  if (error != null) return AffiliationSaved.failed(error);
  return org == null
      ? const AffiliationSaved()
      : AffiliationSaved(
          outcome: 'lista',
          organizationName: org.name,
          roleTitle: role,
        );
}
