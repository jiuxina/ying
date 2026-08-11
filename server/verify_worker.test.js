import assert from "node:assert/strict";
import { generateKeyPairSync, randomBytes } from "node:crypto";
import { test } from "node:test";
import { verifyWorker } from "./verify_worker.js";

if (typeof globalThis.crypto === "undefined") {
  const { webcrypto } = await import("node:crypto");
  globalThis.crypto = webcrypto;
}

class MockKV {
  constructor() {
    this.map = new Map();
  }

  async get(key) {
    return this.map.get(key) ?? null;
  }

  async put(key, value) {
    this.map.set(key, value);
  }
}

const { publicKey, privateKey } = generateKeyPairSync("ec", {
  namedCurve: "prime256v1",
});
const privateJwk = privateKey.export({ format: "jwk" });
const publicJwk = publicKey.export({ format: "jwk" });

function makeEnv(overrides = {}) {
  return {
    UNLOCK_KV: new MockKV(),
    ADMIN_TOKEN: "test-admin-token",
    SIGN_PRIVATE_JWK: JSON.stringify(privateJwk),
    RATE_LIMIT_MAX: "1000",
    ...overrides,
  };
}

function randomKey() {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let body = "";
  const bytes = randomBytes(40);
  for (const byte of bytes) body += alphabet[byte % alphabet.length];
  return `YING-${body}`;
}

async function post(env, path, body) {
  const request = new Request(`https://ying.test${path}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  return verifyWorker(request, env);
}

async function loadKeys(env, keys) {
  return post(env, "/v1/admin/load", { adminToken: env.ADMIN_TOKEN, keys });
}

async function verifySignature(token) {
  const [payloadPart, signaturePart] = token.split(".");
  const payload = Buffer.from(payloadPart.replace(/-/g, "+").replace(/_/g, "/"), "base64");
  const signature = Buffer.from(
    signaturePart.replace(/-/g, "+").replace(/_/g, "/"),
    "base64",
  );
  const key = await crypto.subtle.importKey(
    "jwk",
    publicJwk,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["verify"],
  );
  const valid = await crypto.subtle.verify(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    signature,
    payload,
  );
  return { valid, payload: JSON.parse(payload.toString("utf8")) };
}

test("admin load requires valid token", async () => {
  const env = makeEnv();
  const response = await post(env, "/v1/admin/load", {
    adminToken: "wrong",
    keys: [randomKey()],
  });
  assert.equal(response.status, 401);
});

test("verify binds up to two devices and rejects the third", async () => {
  const env = makeEnv();
  const key = randomKey();
  const loaded = await loadKeys(env, [key]);
  assert.equal(loaded.status, 200);
  const body = await loaded.json();
  assert.equal(body.added, 1);

  const deviceA = "a".repeat(64);
  const first = await post(env, "/v1/verify", { key, deviceHash: deviceA });
  assert.equal(first.status, 200);
  const firstBody = await first.json();
  assert.equal(firstBody.ok, true);
  assert.equal(firstBody.deviceCount, 1);
  const verified = await verifySignature(firstBody.token);
  assert.equal(verified.valid, true);
  assert.equal(verified.payload.plan, "r5");
  assert.equal(verified.payload.keyHash, firstBody.keyHash);

  const deviceB = "b".repeat(64);
  const second = await post(env, "/v1/verify", { key, deviceHash: deviceB });
  assert.equal(second.status, 200);
  assert.equal((await second.json()).deviceCount, 2);

  const sameDevice = await post(env, "/v1/verify", { key, deviceHash: deviceA });
  assert.equal(sameDevice.status, 200);
  assert.equal((await sameDevice.json()).deviceCount, 2);

  const deviceC = "c".repeat(64);
  const third = await post(env, "/v1/verify", { key, deviceHash: deviceC });
  assert.equal(third.status, 403);
  const thirdBody = await third.json();
  assert.equal(thirdBody.code, "limit_reached");
});

test("invalid and malformed keys are rejected", async () => {
  const env = makeEnv();
  const malformed = await post(env, "/v1/verify", {
    key: "SHORT",
    deviceHash: "a".repeat(64),
  });
  assert.equal(malformed.status, 400);

  const unknown = await post(env, "/v1/verify", {
    key: randomKey(),
    deviceHash: "a".repeat(64),
  });
  assert.equal(unknown.status, 403);
  assert.equal((await unknown.json()).code, "invalid");
});

test("revoked keys are rejected", async () => {
  const env = makeEnv();
  const key = randomKey();
  await loadKeys(env, [key]);
  const revoke = await post(env, "/v1/admin/revoke", {
    adminToken: env.ADMIN_TOKEN,
    key,
  });
  assert.equal(revoke.status, 200);
  const verify = await post(env, "/v1/verify", {
    key,
    deviceHash: "a".repeat(64),
  });
  assert.equal(verify.status, 403);
  assert.equal((await verify.json()).code, "revoked");
});

test("rate limit responds 429", async () => {
  const env = makeEnv({ RATE_LIMIT_MAX: "2" });
  const key = randomKey();
  await loadKeys(env, [key]);
  for (let i = 0; i < 2; i += 1) {
    await post(env, "/v1/verify", { key, deviceHash: `${i}`.padStart(64, "0") });
  }
  const limited = await post(env, "/v1/verify", {
    key,
    deviceHash: "9".repeat(64),
  });
  assert.equal(limited.status, 429);
});

test("release manifest defaults and can be updated", async () => {
  const env = makeEnv();
  const before = await verifyWorker(new Request("https://ying.test/v1/latest"), env);
  assert.equal(before.status, 200);
  const beforeBody = await before.json();
  assert.equal(beforeBody.version, "3.3.0");

  const manifest = {
    version: "3.0.1",
    versionCode: 7,
    url: "https://example.com/ying.apk",
    notes: "测试发布",
    publishedAt: "2026-08-09T00:00:00Z",
  };
  const updated = await post(env, "/v1/admin/release", {
    adminToken: env.ADMIN_TOKEN,
    manifest,
  });
  assert.equal(updated.status, 200);
  const after = await verifyWorker(new Request("https://ying.test/v1/latest"), env);
  const afterBody = await after.json();
  assert.equal(afterBody.version, "3.0.1");
  assert.equal(afterBody.url, "https://example.com/ying.apk");
});
