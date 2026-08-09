// 更新 Worker 上的版本清单，供 App 的 /v1/latest 更新检测使用。
// 环境变量：
//   WORKER_URL            如 https://ying-verify.xxx.workers.dev
//   ADMIN_TOKEN           Worker 的 ADMIN_TOKEN
//   RELEASE_VERSION       版本号，如 3.0.0
//   RELEASE_VERSION_CODE  构建号，如 6
//   RELEASE_URL           APK 下载地址
//   RELEASE_NOTES         发布说明（可选）
const workerUrl = process.env.WORKER_URL;
const adminToken = process.env.ADMIN_TOKEN;
const version = process.env.RELEASE_VERSION;
const versionCode = Number(process.env.RELEASE_VERSION_CODE || 0);
const url = process.env.RELEASE_URL;

if (!workerUrl || !adminToken || !version || !url) {
  console.error(
    "需要设置 WORKER_URL、ADMIN_TOKEN、RELEASE_VERSION、RELEASE_URL 环境变量",
  );
  process.exit(1);
}

const manifest = {
  version,
  versionCode,
  url,
  notes: process.env.RELEASE_NOTES || "",
  publishedAt: process.env.RELEASE_PUBLISHED_AT || new Date().toISOString(),
};

const response = await fetch(
  `${workerUrl.replace(/\/$/, "")}/v1/admin/release`,
  {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ adminToken, manifest }),
  },
);
const body = await response.json();
if (!response.ok || !body.ok) {
  console.error("发布清单更新失败", response.status, JSON.stringify(body));
  process.exit(1);
}
console.log(`已发布版本清单 ${version} (${versionCode})`);
