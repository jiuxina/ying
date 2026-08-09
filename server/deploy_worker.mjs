import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

// 通过 Cloudflare API 自动部署 Worker：
// 1. 读取 .env 中的 Cloudflare-API-Token（或 CLOUDFLARE_API_TOKEN 环境变量）
// 2. 自动查询 Account ID（或使用 ACCOUNT_ID 环境变量）
// 3. 创建/复用 KV namespace ying-unlock
// 4. 上传 verify_worker.js（模块格式）
// 5. 写入 ADMIN_TOKEN 与 SIGN_PRIVATE_JWK 两个 secret
const rootDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const envFile = resolve(rootDir, ".env");

function readDotEnv(key) {
  if (process.env[key]) return process.env[key];
  if (!readFileSync(envFile, "utf8").includes(`${key}=`)) return null;
  const line = readFileSync(envFile, "utf8")
    .split(/\r?\n/)
    .find((item) => item.startsWith(`${key}=`));
  return line?.slice(key.length + 1).trim() || null;
}

const apiToken =
  readDotEnv("Cloudflare-API-Token") || readDotEnv("CLOUDFLARE_API_TOKEN");
if (!apiToken) {
  console.error("未找到 Cloudflare API Token（.env 的 Cloudflare-API-Token）");
  process.exit(1);
}

const api = async (path, options = {}) => {
  const response = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
    ...options,
    headers: {
      authorization: `Bearer ${apiToken}`,
      "content-type": "application/json",
      ...(options.headers || {}),
    },
  });
  const body = await response.json();
  if (!body.success) {
    console.error("Cloudflare API 失败", path, JSON.stringify(body.errors));
    process.exit(1);
  }
  return body.result;
};

let accountId = process.env.ACCOUNT_ID;
if (!accountId) {
  const accounts = await api("/accounts?per_page=1");
  accountId = accounts[0].id;
}
console.log("Account ID:", accountId);

const kvTitle = process.env.KV_TITLE || "ying-unlock";
let kvNamespaceId = process.env.KV_NAMESPACE_ID;
if (!kvNamespaceId) {
  const existing = await api(`/accounts/${accountId}/storage/kv/namespaces`);
  const found = existing.find((item) => item.title === kvTitle);
  kvNamespaceId = found?.id;
}
if (!kvNamespaceId) {
  const created = await api(
    `/accounts/${accountId}/storage/kv/namespaces`,
    { method: "POST", body: JSON.stringify({ title: kvTitle }) },
  );
  kvNamespaceId = created.id;
}
console.log("KV namespace:", kvTitle, kvNamespaceId);

const secretsDir = resolve(rootDir, "server", ".dev-secrets");
mkdirSync(secretsDir, { recursive: true });

let adminToken = process.env.ADMIN_TOKEN;
if (!adminToken) {
  const saved = resolve(secretsDir, "admin-token.txt");
  adminToken = readFileSync(saved, "utf8").trim();
}

const signingKeys = JSON.parse(
  readFileSync(resolve(rootDir, "server", "signing-keys.json"), "utf8"),
);
const privateJwk = JSON.stringify(signingKeys.privateJwk);

const scriptSource = readFileSync(
  resolve(rootDir, "server", "verify_worker.js"),
  "utf8",
);
const metadata = {
  main_module: "verify_worker.js",
  compatibility_date: "2024-09-23",
  bindings: [
    {
      name: "UNLOCK_KV",
      type: "kv_namespace",
      namespace_id: kvNamespaceId,
    },
  ],
};

const workerName = process.env.WORKER_NAME || "ying-verify";
const form = new FormData();
form.append(
  "metadata",
  new Blob([JSON.stringify(metadata)], { type: "application/json" }),
);
form.append(
  "script",
  new Blob([scriptSource], { type: "application/javascript" }),
);
const upload = await fetch(
  `https://api.cloudflare.com/client/v4/accounts/${accountId}/workers/scripts/${workerName}`,
  {
    method: "PUT",
    headers: { authorization: `Bearer ${apiToken}` },
    body: form,
  },
);
const uploadBody = await upload.json();
if (!uploadBody.success) {
  console.error("Worker 上传失败", JSON.stringify(uploadBody.errors));
  process.exit(1);
}
console.log("Worker 已上传:", workerName);

for (const secret of [
  { name: "ADMIN_TOKEN", text: adminToken },
  { name: "SIGN_PRIVATE_JWK", text: privateJwk },
]) {
  const result = await api(
    `/accounts/${accountId}/workers/scripts/${workerName}/secrets`,
    {
      method: "PUT",
      body: JSON.stringify({
        name: secret.name,
        text: secret.text,
        type: "secret_text",
      }),
    },
  );
  console.log("secret 已设置:", result.name);
}

const wranglerPath = resolve(rootDir, "server", "wrangler.toml");
writeFileSync(
  wranglerPath,
  readFileSync(wranglerPath, "utf8").replace(
    /id = "REPLACE_WITH_KV_NAMESPACE_ID"/,
    `id = "${kvNamespaceId}"`,
  ),
);
writeFileSync(
  resolve(secretsDir, "kv.json"),
  `${JSON.stringify({ accountId, kvNamespaceId, workerName }, null, 2)}\n`,
);
console.log("部署完成。健康检查：node tools/check_worker.js");
