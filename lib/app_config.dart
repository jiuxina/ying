/// 赞助解锁的全局配置。
///
/// 发布前通过 --dart-define 注入真实 Worker 地址：
/// flutter build apk --release --dart-define=UNLOCK_API_BASE=https://<子域>.workers.dev
///
/// 公钥来自 `node server/generate_signing_keys.mjs` 输出的 publicRawBase64。
abstract final class UnlockConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'UNLOCK_API_BASE',
    defaultValue: 'https://ying-verify.YOUR_SUBDOMAIN.workers.dev',
  );

  static bool get isApiConfigured => !apiBaseUrl.contains('YOUR_SUBDOMAIN');

  static const sponsorUrl = 'https://ifdian.net/a/jiuxina';

  static const maxDevices = 2;
  static const keyPrefix = 'YING-';
  static const keyLength = 40;

  static const publicKeyRawBase64 =
      'BLCf1WNdSmumfJkjro+aAd1SLNy9Dy2XE/TKeyQlgeQ1/EobkXT/uwjRsXBmlrP3gBU1/CfozNPU0vKSPb4c+/w=';
}
