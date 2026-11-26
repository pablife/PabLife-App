/// Vínculo institucional: servidor público, colaborador de empresa parceira ou
/// particular. Serve só para relatórios anônimos por organização.
enum AffiliationKind {
  publicServant('servidor_publico', 'Servidor(a) público(a)', [
    'prefeitura',
    'camara',
    'outro',
  ]),
  partnerCompany('empresa_parceira', 'Colaborador(a) de empresa parceira', [
    'empresa',
    'outro',
  ]),
  private('particular', 'Particular', []);

  const AffiliationKind(this.value, this.label, this.organizationKinds);

  /// Como fica no banco.
  final String value;

  /// Como aparece na tela.
  final String label;

  /// Tipos de organização que combinam com este vínculo.
  final List<String> organizationKinds;

  /// Servidor ou empresa: tem organização, código e cargo.
  bool get hasOrganization => this != private;

  static AffiliationKind? fromValue(String? value) {
    for (final k in values) {
      if (k.value == value) return k;
    }
    return null;
  }
}

/// Organização ativa como a lista do app mostra (sem o código de convite).
class Organization {
  final String id;
  final String name;
  final String kind;
  final String? city;
  final String? state;

  const Organization({
    required this.id,
    required this.name,
    required this.kind,
    this.city,
    this.state,
  });

  factory Organization.fromMap(Map<String, dynamic> map) => Organization(
    id: map['id'] as String,
    name: map['name'] as String,
    kind: map['kind'] as String,
    city: map['city'] as String?,
    state: map['state'] as String?,
  );

  /// "Cidade/UF", ou só a cidade, ou vazio.
  String get place => [
    if ((city ?? '').isNotEmpty) city!,
    if ((state ?? '').isNotEmpty) state!,
  ].join('/');
}

/// Resultado de conferir um código de convite.
class InviteCheck {
  final bool valid;
  final String? reason;
  final Organization? organization;
  final AffiliationKind? kind;
  final String? planName;

  const InviteCheck({
    required this.valid,
    this.reason,
    this.organization,
    this.kind,
    this.planName,
  });

  const InviteCheck.invalid(this.reason)
    : valid = false,
      organization = null,
      kind = null,
      planName = null;

  factory InviteCheck.fromMap(Map<String, dynamic> map) {
    if (map['valid'] != true) {
      return InviteCheck.invalid(map['reason'] as String?);
    }
    final org = map['organization'];
    return InviteCheck(
      valid: true,
      organization: org is Map
          ? Organization.fromMap(Map<String, dynamic>.from(org))
          : null,
      kind: AffiliationKind.fromValue(map['affiliation_kind'] as String?),
      planName: map['plan_name'] as String?,
    );
  }
}

/// Resultado de usar o código de convite.
class InviteRedeem {
  final bool valid;
  final bool planGranted;
  final String? reason;
  final String? planName;
  final DateTime? endsAt;

  const InviteRedeem({
    required this.valid,
    this.planGranted = false,
    this.reason,
    this.planName,
    this.endsAt,
  });

  factory InviteRedeem.fromMap(Map<String, dynamic> map) => InviteRedeem(
    valid: map['valid'] == true,
    planGranted: map['plan_granted'] == true,
    reason: map['reason'] as String?,
    planName: map['plan_name'] as String?,
    endsAt: DateTime.tryParse(map['ends_at']?.toString() ?? '')?.toLocal(),
  );
}

/// O vínculo da pessoa logada, para o cartão do Perfil.
class MyAffiliation {
  final AffiliationKind kind;
  final String? organizationId;
  final String? organizationName;
  final String? suggestedOrganization;
  final String? suggestionStatus;
  final String? roleTitle;
  final DateTime? planPausedAt;
  final String? planPauseReason;

  /// Plano do convênio em vigor, se houver.
  final String? planName;

  const MyAffiliation({
    required this.kind,
    this.organizationId,
    this.organizationName,
    this.suggestedOrganization,
    this.suggestionStatus,
    this.roleTitle,
    this.planPausedAt,
    this.planPauseReason,
    this.planName,
  });

  bool get suggestionPending =>
      suggestedOrganization != null && suggestionStatus == 'pendente';

  bool get planPaused => planPausedAt != null;
}
