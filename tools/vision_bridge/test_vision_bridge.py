import base64
import json
import os
import unittest
from pathlib import Path
from unittest.mock import patch

import vision_bridge as vb

FIXTURES = Path(__file__).resolve().parent / "testdata"


class FakeResponse:
    def __init__(self, payload):
        self._payload = payload

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def read(self):
        return json.dumps(self._payload).encode("utf-8")


class VisionBridgeTests(unittest.TestCase):
    def test_local_image_to_data_url(self):
        expected = (FIXTURES / "photo.png").read_bytes()
        url = vb.image_to_data_url(str(FIXTURES / "photo.png"))
        self.assertTrue(url.startswith("data:image/png;base64,"))
        self.assertEqual(base64.b64decode(url.split(",", 1)[1]), expected)

    def test_url_passthrough(self):
        url = "https://example.com/a.png?size=1"
        self.assertEqual(vb.image_to_data_url(url), url)

    @patch("urllib.request.urlopen")
    def test_describe_image_sends_openai_request(self, mock_urlopen):
        mock_urlopen.return_value = FakeResponse(
            {
                "id": "chatcmpl-1",
                "object": "chat.completion",
                "created": 1,
                "model": "seed-2.1-turbo",
                "choices": [
                    {
                        "index": 0,
                        "message": {"role": "assistant", "content": "一只猫"},
                        "finish_reason": "stop",
                    }
                ],
                "usage": {"prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15},
            }
        )
        text, data = vb.describe_image(
            str(FIXTURES / "photo.png"), "图里有什么", api_key="test-key"
        )
        request = mock_urlopen.call_args.args[0]
        body = json.loads(request.data.decode("utf-8"))
        self.assertEqual(request.full_url, "https://tokenrhythm.studio/v1/chat/completions")
        self.assertEqual(request.headers["Authorization"], "Bearer test-key")
        self.assertEqual(body["model"], "seed-2.1-turbo")
        self.assertEqual(body["stream"], False)
        content = body["messages"][0]["content"]
        self.assertEqual(content[0]["text"], "图里有什么")
        self.assertEqual(content[1]["type"], "image_url")
        self.assertTrue(content[1]["image_url"]["url"].startswith("data:image/png;base64,"))
        self.assertEqual(text, "一只猫")
        self.assertEqual(data["usage"]["total_tokens"], 15)

    def test_describe_image_requires_api_key(self):
        with patch.dict(os.environ, {}, clear=True), patch.object(vb, "_read_env_file", return_value=None):
            with self.assertRaises(RuntimeError):
                vb.describe_image(str(FIXTURES / "photo.png"))

    def test_api_key_precedence(self):
        with patch.dict(os.environ, {"TOKENRHYTHM_API_KEY": "env-key"}, clear=True):
            self.assertEqual(vb.find_api_key("explicit"), "explicit")
            self.assertEqual(vb.find_api_key(None), "env-key")
        with patch.dict(os.environ, {}, clear=True), patch.object(vb, "_read_env_file", return_value="file-key"):
            self.assertEqual(vb.find_api_key(None), "file-key")

    def test_env_file_parser(self):
        self.assertEqual(vb._read_env_file(FIXTURES / "test.env"), "file-key")

    def test_extract_text_from_parts(self):
        content = [
            {"type": "text", "text": "第一段"},
            {"type": "text", "text": "第二段"},
        ]
        self.assertEqual(vb.extract_text(content), "第一段\n第二段")

    def test_normalize_relay_messages_with_image_path(self):
        messages, found = vb.normalize_relay_messages(
            [
                {
                    "role": "user",
                    "content": "描述这张图",
                    "image_path": str(FIXTURES / "photo.jpg"),
                }
            ]
        )
        self.assertTrue(found)
        content = messages[0]["content"]
        self.assertEqual(content[0]["text"], "描述这张图")
        self.assertTrue(content[1]["image_url"]["url"].startswith("data:image/jpeg;base64,"))
        self.assertNotIn("image_path", messages[0])

    def test_normalize_relay_messages_with_vision_format(self):
        messages, found = vb.normalize_relay_messages(
            [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "有什么"},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": "https://example.com/photo.png"
                            },
                        },
                    ],
                }
            ]
        )
        self.assertTrue(found)
        self.assertEqual(
            messages[0]["content"][1]["image_url"]["url"],
            "https://example.com/photo.png",
        )

    def test_missing_api_key_in_env_parser(self):
        self.assertIsNone(vb._read_env_file(FIXTURES / "missing.env"))


if __name__ == "__main__":
    unittest.main()
