const KEY_PREFIX = "YING-";
const KEY_BODY_LENGTH = 40;
const KEY_REGEX = /^YING-[A-Za-z0-9]{40}$/;
const DEVICE_HASH_REGEX = /^[a-f0-9]{64}$/;
const MAX_DEVICES = 2;
const KV_KEY_PREFIX = "key:";
const RATE_PREFIX = "rate:";
const RELEASE_KEY = "release:latest";

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

function base64urlEncode(bytes) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function bytesToHex(bytes) {
  return [...new Uint8Array(bytes)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

async function sha256Hex(value) {
  const data = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return bytesToHex(digest);
}

function secureEqual(a, b) {
  if (typeof a !== "string" || typeof b !== "string") return false;
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i += 1) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

let cachedSignKey;

async function signUnlockToken(env, payload) {
  if (!cachedSignKey) {
    const jwk = JSON.parse(env.SIGN_PRIVATE_JWK);
    cachedSignKey = await crypto.subtle.importKey(
      "jwk",
      jwk,
      { name: "ECDSA", namedCurve: "P-256" },
      false,
      ["sign"],
    );
  }
  const message = new TextEncoder().encode(JSON.stringify(payload));
  const signature = new Uint8Array(
    await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, cachedSignKey, message),
  );
  return `${base64urlEncode(message)}.${base64urlEncode(signature)}`;
}

async function rateLimited(env, request) {
  const max = Number(env.RATE_LIMIT_MAX || 30);
  if (max <= 0) return false;
  const ip =
    request.headers.get("CF-Connecting-IP") ||
    request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    "unknown";
  const windowKey = `${RATE_PREFIX}${ip}:${new Date().toISOString().slice(0, 13)}`;
  const current = Number((await env.UNLOCK_KV.get(windowKey)) || 0);
  if (current >= max) return true;
  await env.UNLOCK_KV.put(windowKey, String(current + 1), { expirationTtl: 3600 });
  return false;
}

function adminAuthorized(env, token) {
  return secureEqual(token, env.ADMIN_TOKEN);
}

async function readBody(request) {
  try {
    const body = await request.json();
    return { ok: true, body };
  } catch (_) {
    return { ok: false, body: null };
  }
}

async function handleVerify(request, env) {
  const parsed = await readBody(request);
  if (!parsed.ok) return json({ ok: false, code: "bad_request", message: "请求格式错误" }, 400);
  const key = typeof parsed.body.key === "string" ? parsed.body.key.trim() : "";
  const deviceHash =
    typeof parsed.body.deviceHash === "string" ? parsed.body.deviceHash.trim().toLowerCase() : "";
  if (!KEY_REGEX.test(key)) {
    return json({ ok: false, code: "invalid_format", message: "密钥格式不正确" }, 400);
  }
  if (!DEVICE_HASH_REGEX.test(deviceHash)) {
    return json({ ok: false, code: "invalid_format", message: "设备标识无效" }, 400);
  }
  if (await rateLimited(env, request)) {
    return json({ ok: false, code: "rate_limited", message: "请求过于频繁，请稍后再试" }, 429);
  }

  const keyHash = await sha256Hex(key);
  const kvKey = `${KV_KEY_PREFIX}${keyHash}`;
  let record;
  try {
    record = JSON.parse((await env.UNLOCK_KV.get(kvKey)) || "null");
  } catch (_) {
    record = null;
  }
  if (record == null) {
    return json({ ok: false, code: "invalid", message: "密钥不存在" }, 403);
  }
  if (record.active === false) {
    return json({ ok: false, code: "revoked", message: "密钥已失效" }, 403);
  }

  const devices = Array.isArray(record.devices) ? record.devices : [];
  if (!devices.includes(deviceHash) && devices.length >= MAX_DEVICES) {
    return json(
      {
        ok: false,
        code: "limit_reached",
        message: `已达绑定上限（${MAX_DEVICES} 台设备）`,
      },
      403,
    );
  }
  if (!devices.includes(deviceHash)) {
    record.devices = [...devices, deviceHash];
    await env.UNLOCK_KV.put(kvKey, JSON.stringify(record));
  }
  const token = await signUnlockToken(env, {
    v: 1,
    keyHash,
    plan: "r5",
    deviceHash,
    iat: Math.floor(Date.now() / 1000),
  });
  return json({
    ok: true,
    token,
    keyHash,
    deviceCount: record.devices.length,
  });
}

async function handleAdminLoad(request, env) {
  const parsed = await readBody(request);
  if (!parsed.ok) return json({ ok: false, code: "bad_request", message: "请求格式错误" }, 400);
  if (!adminAuthorized(env, parsed.body.adminToken)) {
    return json({ ok: false, code: "unauthorized", message: "未授权" }, 401);
  }
  const keys = Array.isArray(parsed.body.keys) ? parsed.body.keys : [];
  const unique = [...new Set(keys.map((value) => (typeof value === "string" ? value.trim() : "")))]
    .filter((value) => KEY_REGEX.test(value))
    .slice(0, 1000);
  let added = 0;
  let skipped = 0;
  for (const key of unique) {
    const keyHash = await sha256Hex(key);
    const kvKey = `${KV_KEY_PREFIX}${keyHash}`;
    const existing = await env.UNLOCK_KV.get(kvKey);
    if (existing != null) {
      skipped += 1;
      continue;
    }
    await env.UNLOCK_KV.put(kvKey, JSON.stringify({ active: true, devices: [] }));
    added += 1;
  }
  return json({ ok: true, added, skipped });
}

async function handleAdminRevoke(request, env) {
  const parsed = await readBody(request);
  if (!parsed.ok) return json({ ok: false, code: "bad_request", message: "请求格式错误" }, 400);
  if (!adminAuthorized(env, parsed.body.adminToken)) {
    return json({ ok: false, code: "unauthorized", message: "未授权" }, 401);
  }
  const key = typeof parsed.body.key === "string" ? parsed.body.key.trim() : "";
  if (!KEY_REGEX.test(key)) {
    return json({ ok: false, code: "invalid_format", message: "密钥格式不正确" }, 400);
  }
  const keyHash = await sha256Hex(key);
  const kvKey = `${KV_KEY_PREFIX}${keyHash}`;
  const existing = await env.UNLOCK_KV.get(kvKey);
  if (existing == null) {
    return json({ ok: false, code: "not_found", message: "密钥不存在" }, 404);
  }
  const record = JSON.parse(existing);
  record.active = false;
  await env.UNLOCK_KV.put(kvKey, JSON.stringify(record));
  return json({ ok: true, keyHash });
}

async function handleAdminRelease(request, env) {
  const parsed = await readBody(request);
  if (!parsed.ok) return json({ ok: false, code: "bad_request", message: "请求格式错误" }, 400);
  if (!adminAuthorized(env, parsed.body.adminToken)) {
    return json({ ok: false, code: "unauthorized", message: "未授权" }, 401);
  }
  const manifest = parsed.body.manifest;
  if (manifest == null || typeof manifest !== "object") {
    return json({ ok: false, code: "bad_request", message: "缺少 manifest" }, 400);
  }
  await env.UNLOCK_KV.put(RELEASE_KEY, JSON.stringify(manifest));
  return json({ ok: true });
}

async function handleLatest(env) {
  const stored = await env.UNLOCK_KV.get(RELEASE_KEY);
  let manifest;
  try {
    manifest = stored == null ? null : JSON.parse(stored);
  } catch (_) {
    manifest = null;
  }
  if (manifest == null) {
    manifest = {
      version: "3.3.0",
      versionCode: 7,
      url: "",
      notes: "",
      publishedAt: null,
    };
  }
  return json({ ok: true, ...manifest });
}

export async function verifyWorker(request, env) {
  const url = new URL(request.url);
  if (request.method === "GET" && url.pathname === "/v1/health") {
    return json({ ok: true });
  }
  if (request.method === "GET" && url.pathname === "/v1/latest") {
    return handleLatest(env);
  }
  if (request.method === "POST") {
    switch (url.pathname) {
      case "/v1/verify":
        return handleVerify(request, env);
      case "/v1/admin/load":
        return handleAdminLoad(request, env);
      case "/v1/admin/revoke":
        return handleAdminRevoke(request, env);
      case "/v1/admin/release":
        return handleAdminRelease(request, env);
      default:
        break;
    }
  }
  return json({ ok: false, code: "not_found", message: "接口不存在" }, 404);
}

export default {
  async fetch(request, env) {
    try {
      return await verifyWorker(request, env);
    } catch (error) {
      return json({ ok: false, code: "server_error", message: "服务器错误" }, 500);
    }
  },
};
