import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/affiliation.dart';

/// Vínculo institucional (migração 20261126120000_vinculo_institucional).
///
/// A tabela de organizações não é aberta para leitura: a lista vem de
/// `list_organizations` e o código só é conferido pelas funções do banco.
class AffiliationRepository {
  /// Trocado nos testes.
  static AffiliationRepository instance = AffiliationRepository();

  SupabaseClient get _client => Supabase.instance.client;

  /// Organizações ativas dos [kinds], com busca sem acento (até 50).
  Future<List<Organization>> searchOrganizations({
    required List<String> kinds,
    String search = '',
  }) async {
    try {
      final rows = await _client.rpc(
        'list_organizations',
        params: {
          'p_kinds': kinds,
          'p_search': search.trim().isEmpty ? null : search.trim(),
        },
      );
      return [
        for (final r in rows as List)
          Organization.fromMap(Map<String, dynamic>.from(r as Map)),
      ];
    } catch (e) {
      debugPrint('Lista de organizações indisponível: $e');
      return [];
    }
  }

  /// Confere o código sem gravar nada.
  Future<InviteCheck> validateInvite(String code) async {
    try {
      final data = await _client.rpc(
        'validate_org_invite',
        params: {'p_code': code.trim()},
      );
      return InviteCheck.fromMap(Map<String, dynamic>.from(data as Map));
    } catch (e) {
      debugPrint('Não foi possível conferir o código: $e');
      return const InviteCheck.invalid('error');
    }
  }

  /// Usa o código: grava o vínculo e, se houver, libera o plano do convênio.
  /// Devolve null se não deu para falar com o servidor.
  Future<InviteRedeem?> redeemInvite(String code, {String? roleTitle}) async {
    try {
      final data = await _client.rpc(
        'redeem_org_invite',
        params: {
          'p_code': code.trim(),
          'p_role_title': (roleTitle ?? '').trim().isEmpty
              ? null
              : roleTitle!.trim(),
        },
      );
      return InviteRedeem.fromMap(Map<String, dynamic>.from(data as Map));
    } catch (e) {
      debugPrint('Não foi possível usar o código: $e');
      return null;
    }
  }

  /// Grava o vínculo da própria pessoa. Devolve uma mensagem de erro, ou null.
  Future<String?> saveMine({
    required AffiliationKind kind,
    String? organizationId,
    String? suggestedOrganization,
    String? roleTitle,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 'Entre na sua conta para salvar o vínculo.';
    String? clean(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    final suggestion = clean(suggestedOrganization);
    try {
      await _client.from('tb_user_affiliations').upsert({
        'user_id': userId,
        'kind': kind.value,
        'organization_id': kind.hasOrganization && suggestion == null
            ? organizationId
            : null,
        'suggested_organization': kind.hasOrganization ? suggestion : null,
        'role_title': kind.hasOrganization ? clean(roleTitle) : null,
      });
      return null;
    } catch (e) {
      debugPrint('Não foi possível salvar o vínculo: $e');
      return 'Não foi possível salvar o vínculo. Tente de novo.';
    }
  }

  /// Reativa o plano do convênio pausado.
  Future<({bool ok, String? reason, DateTime? endsAt})> resumePlan() async {
    try {
      final data = Map<String, dynamic>.from(
        await _client.rpc('resume_org_plan') as Map,
      );
      return (
        ok: data['ok'] == true,
        reason: data['reason'] as String?,
        endsAt: DateTime.tryParse(data['ends_at']?.toString() ?? '')?.toLocal(),
      );
    } catch (e) {
      debugPrint('Não foi possível reativar o plano: $e');
      return (ok: false, reason: 'error', endsAt: null);
    }
  }

  /// O vínculo da pessoa logada; null se ainda não informou (ou não carregou).
  Future<MyAffiliation?> loadMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final row = await _client
          .from('tb_user_affiliations')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return null;
      final kind = AffiliationKind.fromValue(row['kind'] as String?);
      if (kind == null) return null;
      final orgId = row['organization_id'] as String?;

      String? orgName;
      if (orgId != null) {
        final orgs = await searchOrganizations(kinds: kind.organizationKinds);
        orgName = orgs.where((o) => o.id == orgId).firstOrNull?.name;
      }

      String? planName;
      if (orgId != null) {
        final now = DateTime.now().toUtc().toIso8601String();
        final sub = await _client
            .from('tb_user_subscriptions')
            .select('plan:tb_subscription_plans(reason)')
            .eq('user_id', userId)
            .eq('organization_id', orgId)
            .eq('status', 'active')
            .lte('start_date', now)
            .gte('end_date', now)
            .limit(1)
            .maybeSingle();
        planName = (sub?['plan'] as Map?)?['reason'] as String?;
      }

      return MyAffiliation(
        kind: kind,
        organizationId: orgId,
        organizationName: orgName,
        suggestedOrganization: row['suggested_organization'] as String?,
        suggestionStatus: row['suggestion_status'] as String?,
        roleTitle: row['role_title'] as String?,
        planPausedAt: DateTime.tryParse(
          row['plan_paused_at']?.toString() ?? '',
        ),
        planPauseReason: row['plan_pause_reason'] as String?,
        planName: planName,
      );
    } catch (e) {
      debugPrint('Vínculo indisponível: $e');
      return null;
    }
  }
}
