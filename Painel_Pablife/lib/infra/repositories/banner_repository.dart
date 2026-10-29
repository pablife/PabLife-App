import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strawti_utils/strawti_utils.dart';
import '../models/banner_model.dart';

class BannerRepository extends StrautilsTryThis {
  final SupabaseClient _client = Supabase.instance.client;

  FStrautilsResponse<List<BannerModel>> getAll() async {
    return tryThis<List<BannerModel>>(
      () async {
        final response = await _client
            .from('tb_banners')
            .select()
            .order('created_at', ascending: false);
        final list = (response as List)
            .map((e) => BannerModel.fromMap(e))
            .toList();
        return StrautilsResponse.success(list);
      },
      tryAgain: () => getAll(),
      action: 'buscar banners',
    );
  }

  FStrautilsResponse<BannerModel?> create(BannerModel banner) async {
    return tryThis<BannerModel?>(
      () async {
        debugPrint('BannerRepository.create: inserindo ${banner.toMap()}');
        final inserted = await _client
            .from('tb_banners')
            .insert(banner.toMap())
            .select()
            .maybeSingle();
        if (inserted != null) {
          return StrautilsResponse.success(BannerModel.fromMap(inserted));
        }
        return StrautilsResponse.error('Nenhum banner retornado após inserção');
      },
      tryAgain: () => create(banner),
      action: 'criar banner',
    );
  }

  FStrautilsResponse<bool> update(BannerModel banner) async {
    return tryThis<bool>(
      () async {
        await _client
            .from('tb_banners')
            .update(banner.toMap())
            .eq('id', banner.id);
        return StrautilsResponse.success(true);
      },
      tryAgain: () => update(banner),
      action: 'atualizar banner',
    );
  }

  FStrautilsResponse<bool> delete(String id) async {
    return tryThis<bool>(
      () async {
        await _client.from('tb_banners').delete().eq('id', id);
        return StrautilsResponse.success(true);
      },
      tryAgain: () => delete(id),
      action: 'deletar banner',
    );
  }
}
