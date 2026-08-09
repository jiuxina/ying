// 部署自检：确认 Worker 在线并读取当前版本清单。
// 环境变量：WORKER_URL（如 https://ying-verify.xxx.workers.dev）
const workerUrl = process.env.WORKER_URL;
if (!workerUrl) {
  console.error("需要设置 WORKER_URL 环境变量");
  process.exit(1);
}

const base = workerUrl.replace(/\/$/, "");
const health = await fetch(`${base}/v1/health`);
const healthBody = await health.json();
if (!health.ok || !healthBody.ok) {
  console.error("健康检查失败", health.status, JSON.stringify(healthBody));
  process.exit(1);
}
console.log("健康检查通过:", base);

const latest = await fetch(`${base}/v1/latest`);
const latestBody = await latest.json();
console.log("当前版本清单:", JSON.stringify(latestBody, null, 2));
