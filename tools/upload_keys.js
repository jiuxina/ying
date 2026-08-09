import { readFileSync } from "node:fs";

// 把 keys.csv 中的密钥哈希批量导入 Worker。
// 环境变量：WORKER_URL（如 https://ying-verify.xxx.workers.dev）、ADMIN_TOKEN
const workerUrl = process.env.WORKER_URL;
const adminToken = process.env.ADMIN_TOKEN;
const input = process.env.INPUT || "keys.csv";

if (!workerUrl || !adminToken) {
  console.error("需要设置 WORKER_URL 和 ADMIN_TOKEN 环境变量");
  process.exit(1);
}

const lines = readFileSync(input, "utf8")
  .split(/\r?\n/)
  .filter((line) => line.trim().length > 0 && !line.startsWith("keyId"));
const keys = lines
  .map((line) => line.split(",")[1]?.trim())
  .filter((value) => value != null && value.length > 0);

if (keys.length === 0) {
  console.error("keys.csv 中没有密钥");
  process.exit(1);
}

const batchSize = 200;
let added = 0;
let skipped = 0;
for (let offset = 0; offset < keys.length; offset += batchSize) {
  const batch = keys.slice(offset, offset + batchSize);
  const response = await fetch(`${workerUrl.replace(/\/$/, "")}/v1/admin/load`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ adminToken, keys: batch }),
  });
  const body = await response.json();
  if (!response.ok || !body.ok) {
    console.error("导入失败", response.status, JSON.stringify(body));
    process.exit(1);
  }
  added += body.added;
  skipped += body.skipped;
}
console.log(`导入完成：新增 ${added}，跳过 ${skipped}，共 ${keys.length}`);
