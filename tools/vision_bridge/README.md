# 视觉理解桥

一个零依赖的 Python 小工具，通过 OpenAI 兼容协议调用视觉大模型 `sensenova-6.7-flash-lite`，把图片转换成文字描述。适合把不擅长视觉理解的模型、脚本或 Agent 接到支持视觉的模型上。

## 功能

- CLI：一行命令描述本地图片或图片 URL
- 本地网页：拖拽 / 粘贴图片，输入提示词后查看描述
- OpenAI 兼容转发：启动后提供 `/v1/chat/completions` 端点，其他客户端可把图片以 OpenAI vision 消息格式传进来，得到描述
- API Key 可从 `.env`、环境变量或命令行参数读取

## 配置

复制 `.env.example` 为 `.env`，填入 API Key：

```env
SENSENOVA_API_KEY=你的APIKey
```

也可以改用环境变量：

```powershell
$env:SENSENOVA_API_KEY="你的APIKey"
```

优先级：`--api-key` 参数 > 环境变量 > `.env` 文件。

## CLI 使用

```powershell
python vision_bridge.py photo.png --prompt "详细描述这张图片"
python vision_bridge.py "https://example.com/photo.jpg"
```

常用参数：

```text
--prompt    描述提示词
--api-key   API Key
--base-url  接口地址，默认 https://token.sensenova.cn/v1
--model     模型，默认 sensenova-6.7-flash-lite
```

## 本地网页

```powershell
python vision_bridge.py --serve --port 8765
```

打开 <http://127.0.0.1:8765>，可拖拽、点击或粘贴图片。API Key 在页面里填写；留空则使用服务端 `.env` 或环境变量。

## OpenAI 兼容转发

启动服务后，把客户端 base URL 指向本机：

```text
http://127.0.0.1:8765/v1
```

请求格式与 OpenAI 视觉接口一致，也支持在用户消息里用 `image_path` / `image` 字段传服务器本地图片路径：

```json
{
  "model": "sensenova-6.7-flash-lite",
  "messages": [
    {
      "role": "user",
      "content": "描述这张图片",
      "image_path": "C:/path/to/photo.png"
    }
  ]
}
```

PowerShell 调用示例：

```powershell
$body = @{
  model = "sensenova-6.7-flash-lite"
  messages = @(
    @{
      role = "user"
      content = "描述这张图片"
      image_path = "C:/path/to/photo.png"
    }
  )
} | ConvertTo-Json -Depth 6

Invoke-RestMethod -Uri "http://127.0.0.1:8765/v1/chat/completions" -Method Post -ContentType "application/json" -Body $body
```

## 测试

```powershell
python -m unittest discover -s tools/vision_bridge -p "test_*.py"
```
