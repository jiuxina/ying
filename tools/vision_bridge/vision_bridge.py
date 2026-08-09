#!/usr/bin/env python3
"""视觉理解桥：调用 OpenAI 兼容协议的视觉大模型描述图片。

三种使用方式：
1. CLI：python vision_bridge.py image.png --prompt "描述这张图"
2. 本地网页：python vision_bridge.py --serve
3. OpenAI 兼容转发：把 /v1/chat/completions 指向本服务，图片随消息传入
"""

from __future__ import annotations

import argparse
import base64
import html
import json
import mimetypes
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

DEFAULT_BASE_URL = "https://token.sensenova.cn/v1"
DEFAULT_MODEL = "sensenova-6.7-flash-lite"
DEFAULT_PROMPT = "请详细描述这张图片。"
DEFAULT_TIMEOUT = 120
MAX_BODY_BYTES = 25 * 1024 * 1024
ENV_KEY_NAMES = ("SENSENOVA_API_KEY", "TOKENRHYTHM_API_KEY", "OPENAI_API_KEY")


def _env_file_path() -> Path:
    return Path(__file__).resolve().with_name(".env")


def _read_env_file(path: Optional[Path] = None) -> Optional[str]:
    path = path or _env_file_path()
    if not path.is_file():
        return None
    values: Dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        values[key.strip()] = value.strip().strip('"').strip("'")
    for name in ENV_KEY_NAMES:
        if values.get(name):
            return values[name]
    return None


def find_api_key(explicit: Optional[str] = None) -> Optional[str]:
    """按 命令行参数 > 环境变量 > .env 的顺序查找 API Key。"""
    if explicit:
        return explicit
    for name in ENV_KEY_NAMES:
        value = os.environ.get(name)
        if value:
            return value
    return _read_env_file()


def image_to_data_url(image: str) -> str:
    """把本地路径、URL 或 base64 字符串统一成 vision 消息可用的图片引用。"""
    image = image.strip()
    if image.startswith("data:"):
        return image
    if image.startswith(("http://", "https://")):
        return image
    if image.startswith("file://"):
        image = urllib.request.url2pathname(urllib.parse.urlparse(image).path)
    path = Path(image).expanduser()
    if path.is_file():
        mime = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
        data = path.read_bytes()
        encoded = base64.b64encode(data).decode("ascii")
        return f"data:{mime};base64,{encoded}"
    if re.fullmatch(r"[A-Za-z0-9+/=\s]+", image) and len(image) > 100:
        return f"data:application/octet-stream;base64,{image.replace(chr(10), '').replace(chr(13), '')}"
    raise ValueError(f"找不到图片文件：{image}")


def build_vision_content(image: str, prompt: Optional[str] = None) -> List[Dict[str, Any]]:
    text = prompt.strip() if prompt and prompt.strip() else DEFAULT_PROMPT
    return [
        {"type": "text", "text": text},
        {"type": "image_url", "image_url": {"url": image_to_data_url(image)}},
    ]


def extract_text(content: Any) -> str:
    """从 OpenAI 返回的 content（字符串或分段数组）中提取纯文本。"""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts: List[str] = []
        for item in content:
            if isinstance(item, dict):
                text = item.get("text")
                if isinstance(text, str):
                    parts.append(text)
            elif isinstance(item, str):
                parts.append(item)
        return "\n".join(parts)
    return str(content)


def call_chat_completions(
    base_url: str,
    model: str,
    api_key: str,
    messages: List[Dict[str, Any]],
    timeout: int = DEFAULT_TIMEOUT,
) -> Dict[str, Any]:
    endpoint = base_url.rstrip("/") + "/chat/completions"
    payload = json.dumps(
        {"model": model, "messages": messages, "stream": False}
    ).encode("utf-8")
    request = urllib.request.Request(
        endpoint,
        data=payload,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", "replace")
        try:
            parsed = json.loads(detail)
            err = parsed.get("error")
            detail = err.get("message") if isinstance(err, dict) else err or detail
        except (json.JSONDecodeError, AttributeError):
            pass
        raise RuntimeError(f"上游接口返回 {exc.code}: {detail}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"无法连接上游接口: {exc.reason}") from exc
    try:
        return json.loads(raw.decode("utf-8"))
    except json.JSONDecodeError as exc:
        raise RuntimeError("上游接口返回的不是合法 JSON") from exc


def describe_image(
    image: str,
    prompt: Optional[str] = None,
    api_key: Optional[str] = None,
    base_url: str = DEFAULT_BASE_URL,
    model: str = DEFAULT_MODEL,
    timeout: int = DEFAULT_TIMEOUT,
) -> Tuple[str, Dict[str, Any]]:
    key = find_api_key(api_key)
    if not key:
        raise RuntimeError(
            "未配置 API Key：请设置 SENSENOVA_API_KEY 或 TOKENRHYTHM_API_KEY 环境变量，"
            "或在 .env 文件、--api-key 参数中配置。"
        )
    messages = [{"role": "user", "content": build_vision_content(image, prompt)}]
    data = call_chat_completions(base_url, model, key, messages, timeout)
    try:
        content = data["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError) as exc:
        raise RuntimeError(f"上游返回格式异常: {data}") from exc
    return extract_text(content), data


def normalize_relay_messages(messages: Any) -> Tuple[List[Dict[str, Any]], bool]:
    """把 OpenAI 兼容消息里的图片引用解析为 vision 消息，支持自定义 image/image_path 字段。"""
    if not isinstance(messages, list):
        raise ValueError("messages 必须是数组")
    normalized: List[Dict[str, Any]] = []
    found_image = False
    for message in messages:
        if not isinstance(message, dict):
            normalized.append(message)
            continue
        content = message.get("content")
        image_ref = message.get("image") or message.get("image_path")
        if image_ref is not None and message.get("role") == "user":
            text = content if isinstance(content, str) else None
            if not text or not text.strip():
                text = DEFAULT_PROMPT
            parts: List[Dict[str, Any]] = [{"type": "text", "text": text}]
            parts.append(
                {"type": "image_url", "image_url": {"url": image_to_data_url(str(image_ref))}}
            )
            clean = {k: v for k, v in message.items() if k not in ("image", "image_path")}
            clean["content"] = parts
            normalized.append(clean)
            found_image = True
            continue
        if isinstance(content, list):
            parts = []
            for part in content:
                if isinstance(part, dict) and part.get("type") == "image_url":
                    url = part.get("image_url")
                    if isinstance(url, dict):
                        url = url.get("url")
                    if isinstance(url, str) and url:
                        parts.append(
                            {"type": "image_url", "image_url": {"url": image_to_data_url(url)}}
                        )
                        found_image = True
                        continue
                parts.append(part)
            clean = dict(message)
            clean["content"] = parts
            normalized.append(clean)
            continue
        normalized.append(message)
    return normalized, found_image


INDEX_HTML = r"""<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>视觉理解桥</title>
<style>
:root {
  color-scheme: dark;
  --bg: #0d1017;
  --panel: #131722;
  --panel-2: #181e2b;
  --border: #2a3140;
  --text: #e8ecf3;
  --muted: #8b94a7;
  --accent: #2dd4bf;
  --accent-ink: #06211d;
  --danger: #fb7185;
}
* { box-sizing: border-box; }
html, body { margin: 0; min-height: 100%; }
body {
  background: var(--bg);
  color: var(--text);
  font-family: "Segoe UI", "Microsoft YaHei", system-ui, sans-serif;
  letter-spacing: 0;
}
.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  max-width: 1040px;
  margin: 0 auto;
  padding: 18px 20px 10px;
}
.brand {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 17px;
  font-weight: 600;
}
.brand svg { display: block; color: var(--accent); }
.model-chip {
  color: var(--muted);
  font-size: 13px;
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 5px 11px;
  background: var(--panel);
}
main {
  max-width: 1040px;
  margin: 0 auto;
  padding: 10px 20px 32px;
  display: grid;
  gap: 16px;
}
.workspace {
  display: grid;
  grid-template-columns: minmax(0, 1.2fr) minmax(0, 1fr);
  gap: 16px;
  align-items: stretch;
}
.dropzone {
  position: relative;
  min-height: 340px;
  border: 1.5px dashed #394154;
  border-radius: 8px;
  background: var(--panel);
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  cursor: pointer;
  transition: border-color .15s ease, background .15s ease;
}
.dropzone:hover, .dropzone:focus-visible {
  border-color: var(--accent);
  outline: none;
}
.dropzone.has-image { border-style: solid; background: #0a0d12; }
.placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  color: var(--muted);
  font-size: 14px;
  pointer-events: none;
}
.placeholder svg { color: #4b5568; }
#preview {
  width: 100%;
  height: 100%;
  object-fit: contain;
  position: absolute;
  inset: 0;
}
.panel {
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.field {
  display: flex;
  flex-direction: column;
  gap: 7px;
  color: var(--muted);
  font-size: 13px;
}
.field textarea, .field input {
  width: 100%;
  background: var(--panel-2);
  color: var(--text);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 11px 12px;
  font: inherit;
  resize: vertical;
}
.field textarea:focus, .field input:focus {
  border-color: var(--accent);
  outline: none;
}
.actions {
  display: flex;
  gap: 10px;
  margin-top: auto;
}
button {
  font: inherit;
  border: 1px solid transparent;
  border-radius: 8px;
  padding: 10px 14px;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  transition: transform .08s ease, opacity .15s ease;
}
button:active { transform: translateY(1px); }
button:disabled { opacity: .55; cursor: not-allowed; }
.primary {
  flex: 1;
  background: var(--accent);
  color: var(--accent-ink);
  font-weight: 600;
}
.ghost {
  background: transparent;
  color: var(--muted);
  border-color: var(--border);
}
.ghost:hover { color: var(--text); }
.result-box {
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: 8px;
  overflow: hidden;
}
.result-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 12px 16px;
  border-bottom: 1px solid var(--border);
  color: var(--muted);
  font-size: 13px;
}
.result-head > span { color: var(--text); font-weight: 600; }
.result-meta { display: flex; align-items: center; gap: 10px; }
#status { min-height: 18px; }
#status.error { color: var(--danger); }
#copyBtn {
  background: transparent;
  color: var(--muted);
  border: 1px solid var(--border);
  padding: 6px 10px;
  font-size: 12px;
}
#copyBtn:hover { color: var(--text); }
#result {
  margin: 0;
  padding: 16px;
  min-height: 130px;
  white-space: pre-wrap;
  word-break: break-word;
  font-family: inherit;
  line-height: 1.7;
  color: var(--text);
}
.spinner {
  width: 14px;
  height: 14px;
  border: 2px solid currentColor;
  border-right-color: transparent;
  border-radius: 50%;
  animation: spin .7s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
@media (max-width: 720px) {
  .workspace { grid-template-columns: 1fr; }
  .dropzone { min-height: 240px; }
}
</style>
</head>
<body>
<header class="topbar">
  <div class="brand">
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
    <span>视觉理解桥</span>
  </div>
  <div class="model-chip">__MODEL__</div>
</header>
<main>
  <section class="workspace">
    <div class="dropzone" id="dropzone" role="button" tabindex="0" aria-label="选择图片">
      <input type="file" id="fileInput" accept="image/*" hidden>
      <img id="preview" alt="图片预览" hidden>
      <div class="placeholder" id="placeholder">
        <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="M17 8l-5-5-5 5"/><path d="M12 3v12"/></svg>
        <span>选择图片</span>
      </div>
    </div>
    <div class="panel">
      <label class="field">提示词
        <textarea id="prompt" rows="5">请详细描述这张图片。</textarea>
      </label>
      <label class="field">API Key
        <input id="apiKey" type="password" placeholder="留空则使用服务端配置" autocomplete="off">
      </label>
      <div class="actions">
        <button id="runBtn" class="primary" type="button">
          <span class="run-icon">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
          </span>
          <span id="runText">理解图片</span>
        </button>
        <button id="clearBtn" class="ghost" type="button">清空</button>
      </div>
    </div>
  </section>
  <section class="result-box">
    <div class="result-head">
      <span>描述结果</span>
      <div class="result-meta">
        <span id="status"></span>
        <button id="copyBtn" type="button">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="14" height="14" x="8" y="8" rx="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></svg>
          复制
        </button>
      </div>
    </div>
    <pre id="result"></pre>
  </section>
</main>
<script>
const dropzone = document.getElementById("dropzone");
const fileInput = document.getElementById("fileInput");
const preview = document.getElementById("preview");
const placeholder = document.getElementById("placeholder");
const promptEl = document.getElementById("prompt");
const apiKeyEl = document.getElementById("apiKey");
const runBtn = document.getElementById("runBtn");
const runText = document.getElementById("runText");
const clearBtn = document.getElementById("clearBtn");
const copyBtn = document.getElementById("copyBtn");
const statusEl = document.getElementById("status");
const resultEl = document.getElementById("result");

let imageDataUrl = null;
let busy = false;

function setImage(dataUrl) {
  imageDataUrl = dataUrl;
  preview.src = dataUrl;
  preview.hidden = false;
  placeholder.hidden = true;
  dropzone.classList.add("has-image");
  statusEl.textContent = "";
  statusEl.classList.remove("error");
}

function clearAll() {
  imageDataUrl = null;
  preview.removeAttribute("src");
  preview.hidden = true;
  placeholder.hidden = false;
  dropzone.classList.remove("has-image");
  resultEl.textContent = "";
  statusEl.textContent = "";
  statusEl.classList.remove("error");
  promptEl.value = "请详细描述这张图片。";
}

function readFile(file) {
  if (!file || !file.type.startsWith("image/")) {
    statusEl.textContent = "请选择图片文件";
    statusEl.classList.add("error");
    return;
  }
  const reader = new FileReader();
  reader.onload = (event) => setImage(event.target.result);
  reader.readAsDataURL(file);
}

dropzone.addEventListener("click", () => fileInput.click());
dropzone.addEventListener("keydown", (event) => {
  if (event.key === "Enter" || event.key === " ") {
    event.preventDefault();
    fileInput.click();
  }
});
dropzone.addEventListener("dragover", (event) => {
  event.preventDefault();
  dropzone.style.borderColor = "var(--accent)";
});
dropzone.addEventListener("dragleave", () => {
  dropzone.style.borderColor = "";
});
dropzone.addEventListener("drop", (event) => {
  event.preventDefault();
  dropzone.style.borderColor = "";
  readFile(event.dataTransfer.files[0]);
});
fileInput.addEventListener("change", () => {
  readFile(fileInput.files[0]);
  fileInput.value = "";
});
window.addEventListener("paste", (event) => {
  const items = event.clipboardData && event.clipboardData.items;
  if (!items) return;
  for (const item of items) {
    if (item.type.startsWith("image/")) {
      readFile(item.getAsFile());
      break;
    }
  }
});

function setBusy(value) {
  busy = value;
  runBtn.disabled = value;
  runText.textContent = value ? "理解中" : "理解图片";
  const icon = runBtn.querySelector(".run-icon");
  icon.innerHTML = value
    ? '<span class="spinner" style="display:block"></span>'
    : '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
}

async function describe() {
  if (!imageDataUrl) {
    statusEl.textContent = "请先选择图片";
    statusEl.classList.add("error");
    return;
  }
  setBusy(true);
  statusEl.textContent = "理解中";
  statusEl.classList.remove("error");
  const payload = {
    image: imageDataUrl,
    prompt: promptEl.value,
    api_key: apiKeyEl.value || null
  };
  try {
    const response = await fetch("/api/describe", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.error || "请求失败");
    }
    resultEl.textContent = data.content || "";
    const total = data.usage && data.usage.total_tokens;
    statusEl.textContent = total ? "已完成 " + total + " tokens" : "已完成";
  } catch (error) {
    statusEl.textContent = "失败";
    statusEl.classList.add("error");
    resultEl.textContent = error.message;
  } finally {
    setBusy(false);
  }
}

runBtn.addEventListener("click", describe);
clearBtn.addEventListener("click", clearAll);
copyBtn.addEventListener("click", async () => {
  if (!resultEl.textContent) return;
  try {
    await navigator.clipboard.writeText(resultEl.textContent);
    copyBtn.textContent = "已复制";
    setTimeout(() => { copyBtn.textContent = "复制"; }, 1200);
  } catch (error) {
    statusEl.textContent = "复制失败";
    statusEl.classList.add("error");
  }
});
</script>
</body>
</html>
"""


class VisionBridgeHandler(BaseHTTPRequestHandler):
    config: Dict[str, Any] = {}

    def log_message(self, fmt: str, *args: Any) -> None:
        print(
            f"[vision-bridge] {self.address_string()} {fmt % args}",
            file=sys.stderr,
        )

    def _send_json(self, status: int, payload: Any) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _read_body(self) -> bytes:
        length = int(self.headers.get("Content-Length") or 0)
        if length <= 0:
            return b""
        if length > MAX_BODY_BYTES:
            raise ValueError("请求体过大，最大支持 25MB")
        return self.rfile.read(length)

    def do_GET(self) -> None:
        path = urllib.parse.urlparse(self.path).path
        if path in ("/", "/index.html"):
            page = INDEX_HTML.replace("__MODEL__", html.escape(self.config["model"]))
            body = page.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if path == "/health":
            self._send_json(
                200,
                {
                    "ok": True,
                    "model": self.config["model"],
                    "base_url": self.config["base_url"],
                    "api_key_configured": bool(find_api_key(self.config["api_key"])),
                },
            )
            return
        self._send_json(404, {"error": "not found"})

    def do_POST(self) -> None:
        try:
            raw = self._read_body()
            if not raw:
                raise ValueError("空请求体")
            payload = json.loads(raw.decode("utf-8"))
            path = urllib.parse.urlparse(self.path).path
            if path == "/api/describe":
                self._handle_describe(payload)
            elif path == "/v1/chat/completions":
                self._handle_relay(payload)
            else:
                self._send_json(404, {"error": "not found"})
        except ValueError as exc:
            self._send_json(400, {"error": str(exc)})
        except Exception as exc:
            self._send_json(500, {"error": str(exc)})

    def _handle_describe(self, payload: Dict[str, Any]) -> None:
        image = payload.get("image")
        if not image:
            raise ValueError("缺少 image 字段")
        api_key = payload.get("api_key") or self.config["api_key"]
        text, upstream = describe_image(
            str(image),
            payload.get("prompt"),
            api_key=api_key,
            base_url=self.config["base_url"],
            model=self.config["model"],
            timeout=self.config["timeout"],
        )
        self._send_json(
            200,
            {
                "content": text,
                "model": upstream.get("model", self.config["model"]),
                "usage": upstream.get("usage"),
            },
        )

    def _handle_relay(self, payload: Dict[str, Any]) -> None:
        if payload.get("stream"):
            raise ValueError("暂不支持流式输出，请使用 stream=false")
        messages, _ = normalize_relay_messages(payload.get("messages"))
        api_key = payload.get("api_key") or self.config["api_key"]
        if not find_api_key(api_key):
            raise RuntimeError(
                "未配置 API Key：请设置 SENSENOVA_API_KEY 或 TOKENRHYTHM_API_KEY 环境变量，"
                "或在 .env 文件、请求 api_key 字段中配置。"
            )
        model = payload.get("model") or self.config["model"]
        upstream = call_chat_completions(
            self.config["base_url"],
            model,
            api_key,
            messages,
            timeout=self.config["timeout"],
        )
        self._send_json(200, upstream)


def run_server(args: argparse.Namespace) -> None:
    config = {
        "api_key": args.api_key,
        "base_url": args.base_url,
        "model": args.model,
        "timeout": args.timeout,
    }
    handler = type("BoundVisionBridgeHandler", (VisionBridgeHandler,), {"config": config})
    server = ThreadingHTTPServer((args.host, args.port), handler)
    server.daemon_threads = True
    address = f"http://{args.host}:{args.port}"
    print(f"视觉理解桥已启动：{address}")
    print(f"模型：{args.model} | 上游：{args.base_url}")
    print(f"OpenAI 兼容端点：{address}/v1/chat/completions")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n已停止")
    finally:
        server.server_close()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="vision_bridge.py",
        description="调用 OpenAI 兼容协议的视觉大模型描述图片。",
    )
    parser.add_argument("image", nargs="?", help="图片路径、URL 或 data URL")
    parser.add_argument("--prompt", default=DEFAULT_PROMPT, help="描述提示词")
    parser.add_argument("--api-key", default=None, help="API Key（优先于环境变量和 .env）")
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL, help="OpenAI 兼容接口地址")
    parser.add_argument("--model", default=DEFAULT_MODEL, help="视觉模型名称")
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT, help="请求超时秒数")
    parser.add_argument("--serve", action="store_true", help="启动本地服务（网页 + OpenAI 兼容转发）")
    parser.add_argument("--host", default="127.0.0.1", help="服务监听地址")
    parser.add_argument("--port", type=int, default=8765, help="服务监听端口")
    parser.add_argument("--version", action="version", version="vision-bridge 1.1.0")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    if args.serve:
        run_server(args)
        return 0
    if not args.image:
        build_parser().error("请提供图片路径/URL，或使用 --serve 启动本地服务")
    text, _ = describe_image(
        args.image,
        args.prompt,
        api_key=args.api_key,
        base_url=args.base_url,
        model=args.model,
        timeout=args.timeout,
    )
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
