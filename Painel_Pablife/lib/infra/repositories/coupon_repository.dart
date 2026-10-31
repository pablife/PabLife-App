import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawti_utils/strawti_utils.dart';
import '../models/coupon_model.dart';

class CouponRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  List<Map<String, dynamic>> _rows(dynamic response) => (response as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  FStrautilsResponse<List<CouponModel>> getCoupons() async {
    return tryThis<List<CouponModel>>(
      () async {
        final response = await _client
            .from('tb_coupons')
            .select()
            .order('created_at', ascending: false);
        return StrautilsResponse.success(
          _rows(response).map(CouponModel.fromMap).toList(),
        );
      },
      tryAgain: () => getCoupons(),
      action: 'buscar cupons',
    );
  }

  FStrautilsResponse<bool> saveCoupon(CouponModel coupon) async {
    return tryThis<bool>(() async {
      if (coupon.id.isEmpty) {
        await _client.from('tb_coupons').insert(coupon.toMap());
      } else {
        await _client
            .from('tb_coupons')
            .update({
              ...coupon.toMap(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', coupon.id);
      }
      return StrautilsResponse.success(true);
    }, action: 'salvar cupom');
  }

  /// Titulares com o e-mail da conta de acesso ao painel.
  FStrautilsResponse<List<CouponOwnerModel>> getOwners() async {
    return tryThis<List<CouponOwnerModel>>(
      () async {
        final response = await _client
            .from('tb_coupon_owners')
            .select()
            .order('name');
        final owners = _rows(response).map(CouponOwnerModel.fromMap).toList();

        final accessIds = owners
            .map((o) => o.accessUserId)
            .whereType<String>()
            .toList();
        if (accessIds.isEmpty) return StrautilsResponse.success(owners);

        final users = _rows(
          await _client
              .from('tb_users')
              .select('id, email')
              .inFilter('id', accessIds),
        );
        final emails = {for (final u in users) u['id']: u['email'] as String?};
        return StrautilsResponse.success(
          owners
              .map(
                (o) => o.accessUserId == null
                    ? o
                    : o.copyWith(accessEmail: emails[o.accessUserId]),
              )
              .toList(),
        );
      },
      tryAgain: () => getOwners(),
      action: 'buscar titulares',
    );
  }

  FStrautilsResponse<bool> saveOwner(CouponOwnerModel owner) async {
    return tryThis<bool>(() async {
      if (owner.id.isEmpty) {
        await _client.from('tb_coupon_owners').insert(owner.toMap());
      } else {
        await _client
            .from('tb_coupon_owners')
            .update({
              ...owner.toMap(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', owner.id);
      }
      return StrautilsResponse.success(true);
    }, action: 'salvar titular');
  }

  /// Conta do app pelo e-mail (para o titular entrar no painel).
  FStrautilsResponse<String?> findUserIdByEmail(String email) async {
    return tryThis<String?>(() async {
      final row = await _client
          .from('tb_users')
          .select('id')
          .ilike('email', email.trim())
          .maybeSingle();
      return StrautilsResponse.success(row?['id'] as String?);
    }, action: 'buscar conta do titular');
  }

  /// Todos os usuários que entraram por cupom, com os resultados.
  FStrautilsResponse<List<CouponUserMetric>> getUserMetrics() async {
    return tryThis<List<CouponUserMetric>>(
      () async {
        final response = await _client.rpc('admin_coupon_users');
        return StrautilsResponse.success(
          _rows(response).map(CouponUserMetric.fromMap).toList(),
        );
      },
      tryAgain: () => getUserMetrics(),
      action: 'buscar resultados dos cupons',
    );
  }

  // ---------- Titular (acesso próprio) ----------

  FStrautilsResponse<Map<String, dynamic>?> getMyOwner() async {
    return tryThis<Map<String, dynamic>?>(() async {
      final rows = _rows(await _client.rpc('my_coupon_owner'));
      return StrautilsResponse.success(rows.isEmpty ? null : rows.first);
    }, action: 'buscar titular');
  }

  FStrautilsResponse<List<CouponUserMetric>> getMyUsers() async {
    return tryThis<List<CouponUserMetric>>(() async {
      final response = await _client.rpc('my_coupon_owner_users');
      return StrautilsResponse.success(
        _rows(response).map(CouponUserMetric.fromMap).toList(),
      );
    }, action: 'buscar seus resultados');
  }

  FStrautilsResponse<List<CouponModel>> getMyCoupons() async {
    return tryThis<List<CouponModel>>(() async {
      final rows = _rows(await _client.rpc('my_coupon_owner_coupons'));
      return StrautilsResponse.success(
        rows
            .map(
              (r) => CouponModel.fromMap({
                'id': r['code'],
                'code': r['code'],
                'free_days': r['free_days'],
                'valid_until': r['valid_until'],
                'is_active': r['is_active'],
              }),
            )
            .toList(),
      );
    }, action: 'buscar seus cupons');
  }
}
