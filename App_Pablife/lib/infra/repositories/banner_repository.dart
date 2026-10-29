import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawti_utils/strawti_utils.dart';

import '../models/banner_model.dart';

class BannerRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  FStrautilsResponse<List<BannerModel>> getActiveBanners() {
    return tryThis(() async {
      final now = DateTime.now();

      PostgrestFilterBuilder query = _client
          .from('tb_banners')
          .select('*')
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .or(
            'expiration_at.is.null,expiration_at.gte.${now.toUtc().toIso8601String()}',
          );

      final orderedQuery = query.order('created_at', ascending: false);

      final List<dynamic> responseData;
      try {
        responseData = await orderedQuery;
      } on PostgrestException catch (e) {
        return StrautilsResponse.error('Erro ao buscar banners: ${e.message}');
      }

      final banners = responseData
          .map(
            (row) => BannerModel.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList();

      return StrautilsResponse.success(banners);
    }, action: 'buscar banners ativos');
  }
}
