import { generateKeyPairSync, randomBytes } from "node:crypto";
import { writeFileSync } from "node:fs";
import { resolve } from "node:path";

// 生成用于签发解锁凭证的 ECDSA P-256 密钥对。
// 输出 signing-keys.json（勿提交仓库）：
//   privateJwk: 放入 Cloudflare Worker secret SIGN_PRIVATE_JWK
//   publicRawBase64: 写入 lib/app_config.dart 的 UnlockConfig.publicKeyRawBase64
const { publicKey, privateKey } = generateKeyPairSync("ec", {
  namedCurve: "prime256v1",
});

const privateJwk = privateKey.export({ format: "jwk" });
const publicJwk = publicKey.export({ format: "jwk" });

function base64UrlToBytes(value) {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/");
  return Buffer.from(base64, "base64");
}

const x = base64UrlToBytes(publicJwk.x);
const y = base64UrlToBytes(publicJwk.y);
const publicRaw = Buffer.concat([Buffer.from([0x04]), x, y]);

const output = {
  generatedAt: new Date().toISOString(),
  privateJwk,
  publicRawBase64: publicRaw.toString("base64"),
  // 备用：生成随机的 ADMIN_TOKEN 示例，正式使用时请自行替换。
  adminTokenExample: randomBytes(24).toString("base64url"),
};

const outputPath = resolve(import.meta.dirname, "signing-keys.json");
writeFileSync(outputPath, `${JSON.stringify(output, null, 2)}\n`);
console.log(`已写入 ${outputPath}`);
console.log("publicRawBase64=", output.publicRawBase64);
console.log("privateJwk=", JSON.stringify(output.privateJwk));
