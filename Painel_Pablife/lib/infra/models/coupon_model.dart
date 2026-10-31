DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

/// Cupom de dias grátis: libera um plano por [freeDays] dias, sem cartão.
class CouponModel {
  final String id;
  final String code;
  final String? description;
  final int freeDays;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? maxUses;
  final bool isActive;
  final String? ownerId;
  final DateTime? createdAt;

  /// Preenchidos no painel a partir dos usos (sem os de teste).
  final int uses;
  final int activeNow;

  const CouponModel({
    required this.id,
    required this.code,
    this.description,
    required this.freeDays,
    this.validFrom,
    this.validUntil,
    this.maxUses,
    required this.isActive,
    this.ownerId,
    this.createdAt,
    this.uses = 0,
    this.activeNow = 0,
  });

  bool get isExpired =>
      validUntil != null && DateTime.now().isAfter(validUntil!);

  bool get isNotStarted =>
      validFrom != null && DateTime.now().isBefore(validFrom!);

  bool get isExhausted => maxUses != null && uses >= maxUses!;

  /// Pode ser usado agora no app.
  bool get isUsable => isActive && !isExpired && !isNotStarted && !isExhausted;

  String get statusLabel {
    if (!isActive) return 'Inativo';
    if (isExpired) return 'Expirado';
    if (isNotStarted) return 'Ainda não começou';
    if (isExhausted) return 'Esgotado';
    return 'Ativo';
  }

  factory CouponModel.fromMap(Map<String, dynamic> map) {
    return CouponModel(
      id: map['id'] as String,
      code: map['code'] as String,
      description: map['description'] as String?,
      freeDays: (map['free_days'] as num?)?.toInt() ?? 30,
      validFrom: _date(map['valid_from']),
      validUntil: _date(map['valid_until']),
      maxUses: (map['max_uses'] as num?)?.toInt(),
      isActive: map['is_active'] as bool? ?? true,
      ownerId: map['owner_id'] as String?,
      createdAt: _date(map['created_at']),
    );
  }

  /// Campos editáveis no painel.
  Map<String, dynamic> toMap() {
    return {
      'code': code.trim().toUpperCase(),
      'description': (description?.trim().isEmpty ?? true)
          ? null
          : description!.trim(),
      'free_days': freeDays,
      'valid_from': validFrom?.toUtc().toIso8601String(),
      'valid_until': validUntil?.toUtc().toIso8601String(),
      'max_uses': maxUses,
      'is_active': isActive,
      'owner_id': ownerId,
    };
  }

  CouponModel copyWith({bool? isActive, int? uses, int? activeNow}) {
    return CouponModel(
      id: id,
      code: code,
      description: description,
      freeDays: freeDays,
      validFrom: validFrom,
      validUntil: validUntil,
      maxUses: maxUses,
      isActive: isActive ?? this.isActive,
      ownerId: ownerId,
      createdAt: createdAt,
      uses: uses ?? this.uses,
      activeNow: activeNow ?? this.activeNow,
    );
  }
}

/// Titular do cupom: influenciador, parceiro, empresa...
class CouponOwnerModel {
  final String id;
  final String name;
  final String kind;
  final String? instagram;
  final String? email;
  final String? phone;
  final String? notes;
  final double commissionPerConversion;
  final String? accessUserId;

  /// E-mail da conta de acesso ao painel (preenchido no painel).
  final String? accessEmail;
  final bool isActive;
  final DateTime? createdAt;

  const CouponOwnerModel({
    required this.id,
    required this.name,
    this.kind = 'influencer',
    this.instagram,
    this.email,
    this.phone,
    this.notes,
    this.commissionPerConversion = 0,
    this.accessUserId,
    this.accessEmail,
    this.isActive = true,
    this.createdAt,
  });

  static const kinds = {
    'influencer': 'Influenciador',
    'parceiro': 'Parceiro',
    'empresa': 'Empresa',
    'profissional': 'Profissional',
    'outro': 'Outro',
  };

  String get kindLabel => kinds[kind] ?? 'Outro';

  factory CouponOwnerModel.fromMap(Map<String, dynamic> map) {
    return CouponOwnerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      kind: map['kind'] as String? ?? 'influencer',
      instagram: map['instagram'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      commissionPerConversion:
          (map['commission_per_conversion'] as num?)?.toDouble() ?? 0,
      accessUserId: map['access_user_id'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: _date(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    String? clean(String? v) => (v?.trim().isEmpty ?? true) ? null : v!.trim();
    return {
      'name': name.trim(),
      'kind': kind,
      'instagram': clean(instagram),
      'email': clean(email),
      'phone': clean(phone),
      'notes': clean(notes),
      'commission_per_conversion': commissionPerConversion,
      'access_user_id': accessUserId,
      'is_active': isActive,
    };
  }

  CouponOwnerModel copyWith({
    String? accessUserId,
    String? accessEmail,
    bool clearAccess = false,
    bool? isActive,
  }) {
    return CouponOwnerModel(
      id: id,
      name: name,
      kind: kind,
      instagram: instagram,
      email: email,
      phone: phone,
      notes: notes,
      commissionPerConversion: commissionPerConversion,
      accessUserId: clearAccess ? null : (accessUserId ?? this.accessUserId),
      accessEmail: clearAccess ? null : (accessEmail ?? this.accessEmail),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

/// Uma pessoa que entrou por cupom e o que aconteceu depois
/// (admin_coupon_users / my_coupon_owner_users).
class CouponUserMetric {
  final String? userId;
  final String? fullName;
  final String? email;
  final String? couponId;
  final String couponCode;
  final String? ownerId;
  final String? ownerName;
  final String? planName;
  final DateTime redeemedAt;
  final DateTime? accessUntil;
  final String? subscriptionStatus;
  final int consultations;
  final int noShows;
  final DateTime? firstConsultationAt;
  final DateTime? lastConsultationAt;
  final DateTime? convertedAt;

  const CouponUserMetric({
    this.userId,
    this.fullName,
    this.email,
    this.couponId,
    required this.couponCode,
    this.ownerId,
    this.ownerName,
    this.planName,
    required this.redeemedAt,
    this.accessUntil,
    this.subscriptionStatus,
    this.consultations = 0,
    this.noShows = 0,
    this.firstConsultationAt,
    this.lastConsultationAt,
    this.convertedAt,
  });

  bool get hasFirstConsultation => consultations > 0;
  bool get isConverted => convertedAt != null;

  bool get inFreePeriod =>
      !isConverted &&
      subscriptionStatus == 'active' &&
      accessUntil != null &&
      DateTime.now().isBefore(accessUntil!);

  String get situation {
    if (isConverted) return 'Assinante';
    if (inFreePeriod) return 'Período grátis';
    return 'Saiu';
  }

  factory CouponUserMetric.fromMap(Map<String, dynamic> map) {
    return CouponUserMetric(
      userId: map['user_id'] as String?,
      fullName: (map['full_name'] ?? map['display_name']) as String?,
      email: map['email'] as String?,
      couponId: map['coupon_id'] as String?,
      couponCode: map['coupon_code'] as String? ?? '-',
      ownerId: map['owner_id'] as String?,
      ownerName: map['owner_name'] as String?,
      planName: map['plan_name'] as String?,
      redeemedAt: _date(map['redeemed_at']) ?? DateTime.now(),
      accessUntil: _date(map['access_until']),
      subscriptionStatus: map['subscription_status'] as String?,
      consultations: (map['consultations'] as num?)?.toInt() ?? 0,
      noShows: (map['no_shows'] as num?)?.toInt() ?? 0,
      firstConsultationAt: _date(map['first_consultation_at']),
      lastConsultationAt: _date(map['last_consultation_at']),
      convertedAt: _date(map['converted_at']),
    );
  }
}

/// Totais de um grupo de usuários (todos, um titular, um cupom...).
class CouponResults {
  final int users;
  final int firstConsultations;
  final int conversions;
  final int inFreePeriod;
  final int consultations;

  const CouponResults({
    this.users = 0,
    this.firstConsultations = 0,
    this.conversions = 0,
    this.inFreePeriod = 0,
    this.consultations = 0,
  });

  factory CouponResults.of(Iterable<CouponUserMetric> rows) {
    var users = 0, first = 0, conv = 0, free = 0, total = 0;
    for (final r in rows) {
      users++;
      if (r.hasFirstConsultation) first++;
      if (r.isConverted) conv++;
      if (r.inFreePeriod) free++;
      total += r.consultations;
    }
    return CouponResults(
      users: users,
      firstConsultations: first,
      conversions: conv,
      inFreePeriod: free,
      consultations: total,
    );
  }

  double _rate(int part) => users == 0 ? 0 : part / users;
  double get firstConsultationRate => _rate(firstConsultations);
  double get conversionRate => _rate(conversions);
  double get averageConsultations => users == 0 ? 0 : consultations / users;
}
