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

需要 Cloudflare API Token 具备以下权限：

- Account - Workers Scripts: Edit
- Account - Workers KV Storage: Edit

使用 wrangler 部署（模块格式支持最稳定）：

```bash
cd server
set CLOUDFLARE_API_TOKEN=你的token
set CLOUDFLARE_ACCOUNT_ID=你的account_id
wrangler kv namespace create ying-unlock
# 把输出的 namespace id 填进 wrangler.toml
set /p ADMIN_TOKEN=< .dev-secrets\admin-token.txt
echo %ADMIN_TOKEN%| wrangler secret put ADMIN_TOKEN
node -e "console.log(JSON.stringify(require('./signing-keys.json').privateJwk))" | wrangler secret put SIGN_PRIVATE_JWK
npx wrangler deploy
```

`server/deploy_worker.mjs` 为实验性 API 直传脚本，若 Cloudflare API 不接受模块 multipart 格式时，请以上面的 wrangler 方式部署。

部署完成后验证：

```bash
set WORKER_URL=https://ying-verify.xxx.workers.dev
node tools/check_worker.js
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
   - `--append`：追加写入并去重，不覆盖已有密钥。
   - `--source <文件>`：不生成新密钥，改为合并已有密钥文件，例如 `dart run tools/generate_unlock_keys.dart --source keys.csv keys_activity.csv --append`。
   - 每次生成/合并的批次以 `# batch: ...` 标记行开头；`upload_keys.js` 与 `update_afdian_reply.js` 会自动跳过标记行。
2. 运行 `node tools/upload_keys.js` 把密钥哈希导入 Worker KV。
3. 运行 `node tools/update_afdian_reply.js` 把密钥库存写入爱发电方案的自动随机回复。

## 发布版本清单

构建正式 APK 后，更新 App 内更新检测：

```bash
set WORKER_URL=https://ying-verify.xxx.workers.dev
set ADMIN_TOKEN=你的token
set RELEASE_VERSION=3.3.0
set RELEASE_VERSION_CODE=7
set RELEASE_URL=https://你的公开下载地址/ying-3.3.0.apk
node tools/publish_release.js
```

正式构建命令见仓库根目录 `build_sponsor_release.bat`。

## 测试

```bash
node server/verify_worker.test.js
```
