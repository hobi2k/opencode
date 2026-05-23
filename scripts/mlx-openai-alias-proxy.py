#!/usr/bin/env python3
"""Small OpenAI-compatible alias proxy for mlx_lm.server.

mlx_lm.server often exposes Hugging Face repo ids such as
"mlx-community/Qwen2.5-Coder-32B-Instruct-4bit". opencode selectors use a
provider/model shape, so slash-heavy model ids can be awkward. This proxy
exposes a slash-free alias to opencode and rewrites requests to the upstream
mlx-lm model id.
"""

from __future__ import annotations

import json
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin
from urllib.request import Request, urlopen


LISTEN_HOST = os.environ.get("MLX_PROXY_HOST", "127.0.0.1")
LISTEN_PORT = int(os.environ.get("MLX_PROXY_PORT", "8090"))
UPSTREAM = os.environ.get("MLX_PROXY_UPSTREAM", "http://127.0.0.1:8080").rstrip("/")
MODEL_ALIAS = os.environ.get("MLX_PROXY_MODEL_ALIAS", "qwen-coder-32b")
UPSTREAM_MODEL = os.environ.get("MLX_PROXY_UPSTREAM_MODEL", MODEL_ALIAS)


def _json_response(handler: BaseHTTPRequestHandler, status: int, payload: object) -> None:
  body = json.dumps(payload).encode("utf-8")
  handler.send_response(status)
  handler.send_header("content-type", "application/json")
  handler.send_header("content-length", str(len(body)))
  handler.end_headers()
  handler.wfile.write(body)


class ProxyHandler(BaseHTTPRequestHandler):
  protocol_version = "HTTP/1.1"

  def log_message(self, fmt: str, *args: object) -> None:
    sys.stderr.write("[mlx-alias-proxy] " + fmt % args + "\n")

  def do_GET(self) -> None:
    if self.path.split("?", 1)[0] == "/v1/models":
      _json_response(
        self,
        200,
        {
          "object": "list",
          "data": [
            {
              "id": MODEL_ALIAS,
              "object": "model",
              "created": 0,
              "owned_by": "mlx-lm",
            }
          ],
        },
      )
      return
    self._forward()

  def do_POST(self) -> None:
    self._forward(rewrite_model=True)

  def _forward(self, rewrite_model: bool = False) -> None:
    length = int(self.headers.get("content-length", "0") or "0")
    body = self.rfile.read(length) if length else b""

    headers = {
      key: value
      for key, value in self.headers.items()
      if key.lower() not in {"host", "content-length", "connection"}
    }

    if rewrite_model and body:
      try:
        payload = json.loads(body)
        if not payload.get("model") or payload.get("model") == MODEL_ALIAS:
          payload["model"] = UPSTREAM_MODEL
        body = json.dumps(payload).encode("utf-8")
        headers["content-type"] = "application/json"
      except json.JSONDecodeError:
        pass

    request = Request(
      urljoin(UPSTREAM + "/", self.path.lstrip("/")),
      data=body if self.command != "GET" else None,
      method=self.command,
      headers=headers,
    )

    try:
      with urlopen(request, timeout=None) as response:
        self.send_response(response.status)
        for key, value in response.headers.items():
          if key.lower() in {"connection", "content-length", "transfer-encoding"}:
            continue
          self.send_header(key, value)
        self.end_headers()

        while True:
          chunk = response.read(8192)
          if not chunk:
            break
          self.wfile.write(chunk)
          self.wfile.flush()
    except HTTPError as error:
      error_body = error.read()
      self.send_response(error.code)
      self.send_header("content-type", error.headers.get("content-type", "application/json"))
      self.send_header("content-length", str(len(error_body)))
      self.end_headers()
      self.wfile.write(error_body)
    except URLError as error:
      _json_response(self, 502, {"error": f"Upstream unavailable: {error}"})


def main() -> None:
  server = ThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), ProxyHandler)
  print(
    f"mlx alias proxy listening on http://{LISTEN_HOST}:{LISTEN_PORT}; "
    f"alias={MODEL_ALIAS}; upstream={UPSTREAM}; upstream_model={UPSTREAM_MODEL}",
    flush=True,
  )
  server.serve_forever()


if __name__ == "__main__":
  main()
