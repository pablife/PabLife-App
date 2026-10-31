/// Painel só de cupons (publicado à parte): gere com
/// `flutter build web --dart-define=COUPONS_ONLY=true`.
/// Admin vê as abas de cupons; titular (influenciador) vê só o painel dele.
const bool kCouponsOnly = bool.fromEnvironment('COUPONS_ONLY');
