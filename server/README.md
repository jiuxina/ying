# 萤 · Cloudflare Worker 验证服务

这个 Worker 负责两件事：

1. 校验爱发电自动发货的密钥（`POST /v1/verify`），并把每把密钥绑定到最多 2 台设备。
2. 提供更新清单（`GET /v1/latest`），闭源后 App 的更新检测改从这里读取。

## 本地密钥准备

```bash
node server/generate_signing_keys.mjs
```

会生成 `server/signing-keys.json`（已被 gitignore，勿提交）：

- `privateJwk`：写入 Worker secret `SIGN_PRIVATE_JWK`。
- `publicRawBase64`：复制到 `lib/app_config.dart` 的 `UnlockConfig.publicKeyRawBase64`。
- `adminTokenExample`：可作为 `ADMIN_TOKEN` 初始值，正式使用建议自行生成。

## 部署

```bash
cd server
wrangler kv namespace create ying-unlock
# 把输出的 namespace id 填进 wrangler.toml
wrangler secret put ADMIN_TOKEN
wrangler secret put SIGN_PRIVATE_JWK
wrangler deploy
```

部署完成后验证：

```bash
curl https://<你的子域名>.workers.dev/v1/health
```

## 接口

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| GET | `/v1/health` | 健康检查 |
| POST | `/v1/verify` | 校验密钥并绑定设备 |
| POST | `/v1/admin/load` | 批量导入密钥（带 `adminToken`） |
| POST | `/v1/admin/revoke` | 撤销某把密钥（带 `adminToken`） |
| POST | `/v1/admin/release` | 更新版本清单（带 `adminToken`） |
| GET | `/v1/latest` | 返回最新版本清单 |

`/v1/verify` 请求体：

```json
{ "key": "YING-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", "deviceHash": "<64位hex>" }
```

正常返回：

```json
{ "ok": true, "token": "<payload>.<signature>", "keyHash": "<64位hex>", "deviceCount": 1 }
```

## 密钥流程

1. 运行 `dart run tools/generate_unlock_keys.dart 100` 生成 100 把密钥，输出 `keys.csv`。
2. 运行 `node tools/upload_keys.js` 把密钥哈希导入 Worker KV。
3. 运行 `node tools/update_afdian_reply.js` 把密钥库存写入爱发电方案的自动随机回复。

## 测试

```bash
node server/verify_worker.test.js
```
