import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";

// 把 keys.csv 中的密钥写入爱发电方案的"自动随机回复"库存。
// 环境变量：
//   AFDIAN_USER_ID  开发者后台 user_id
//   AFDIAN_TOKEN    开发者后台 API token（不进入 App）
//   AFDIAN_PLAN_ID  要补货的方案 id
//   INPUT           密钥文件，默认 keys.csv
//   MODE            append（追加，默认）或 overwrite（覆盖）
const userId = process.env.AFDIAN_USER_ID;
const token = process.env.AFDIAN_TOKEN;
const planId = process.env.AFDIAN_PLAN_ID;
const input = process.env.INPUT || "keys.csv";
const mode = (process.env.MODE || "append").toLowerCase() === "overwrite" ? "overwrite" : "append";

if (!userId || !token || !planId) {
  console.error("需要设置 AFDIAN_USER_ID、AFDIAN_TOKEN、AFDIAN_PLAN_ID 环境变量");
  process.exit(1);
}

const lines = readFileSync(input, "utf8")
  .split(/\r?\n/)
  .filter(
    (line) =>
      line.trim().length > 0 &&
      !line.startsWith("#") &&
      !line.startsWith("keyId"),
  );
const keys = lines
  .map((line) => line.split(",")[1]?.trim())
  .filter((value) => value != null && value.length > 0);
if (keys.length === 0) {
  console.error("密钥文件为空");
  process.exit(1);
}

const params = {
  plan_id: planId,
  auto_random_reply: keys.join("\n"),
  update_random_reply_type: mode,
};
const paramsJson = JSON.stringify(params);
const ts = Math.floor(Date.now() / 1000);
// sign = md5(token + 参数按 key 排序后的 key+value 拼接)
const kv = `params${paramsJson}ts${ts}user_id${userId}`;
const sign = createHash("md5").update(`${token}${kv}`).digest("hex");

const response = await fetch("https://ifdian.net/api/open/update-plan-reply", {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ user_id: userId, params: paramsJson, ts, sign }),
});
const body = await response.json();
console.log(`HTTP ${response.status}`, JSON.stringify(body, null, 2));
if (body.ec !== 200) process.exit(1);
