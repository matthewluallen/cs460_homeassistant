#!/usr/bin/env python3
"""
CS460 Module 5 — campus LLM-hub adapter.

Presents a minimal **Ollama-compatible** API (/api/tags, /api/chat, /api/version)
and forwards chat requests to the UIUC campus LLM hub (chat.illinois.edu /
uiuc.chat). This lets Home Assistant's built-in **Ollama** integration use a
student's OWN campus chatbot as the conversation agent — so the student can talk
to their Home Assistant devices, in the browser, through the campus model and its
course knowledge base (RAG).

Why an adapter: the campus endpoint is a custom format (api_key + course_name in
the JSON body, path /api/chat-api/chat), not drop-in OpenAI/Ollama. HA's Ollama
integration happily points at any URL, so we speak Ollama on the front and
translate on the back.

SECURITY: the API key is read from the environment (a Codespaces/HA secret the
student sets themselves). It is never logged and never has to be typed into the
Home Assistant UI.
"""
import json
import os
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

API_KEY   = os.environ.get("ILLINOIS_CHAT_API_KEY", "")
COURSE    = os.environ.get("UIUC_COURSE_NAME", "")
MODEL     = os.environ.get("UIUC_MODEL", "gpt-4o-mini")
CHAT_URL  = os.environ.get("UIUC_CHAT_URL", "https://chat.illinois.edu/api/chat-api/chat")
PORT      = int(os.environ.get("ADAPTER_PORT", "11435"))

# A fake "model" entry so HA's Ollama integration shows something to pick.
FAKE_MODEL = {
    "name": "campus-hub",
    "model": "campus-hub",
    "modified_at": "2024-01-01T00:00:00Z",
    "size": 0,
    "digest": "campus-hub",
    "details": {"family": "uiuc-chat", "parameter_size": "N/A",
                "quantization_level": "N/A", "format": "gguf", "families": ["uiuc-chat"]},
}


def ask_campus_hub(messages, temperature):
    """Translate an Ollama /api/chat call into a campus-hub request."""
    if not API_KEY or not COURSE:
        return ("[adapter not configured] Set ILLINOIS_CHAT_API_KEY and "
                "UIUC_COURSE_NAME as secrets, then restart. The key is never "
                "typed into Home Assistant.")
    body = json.dumps({
        "model": MODEL,
        "messages": messages,
        "api_key": API_KEY,          # from env/secret — never logged
        "course_name": COURSE,
        "stream": False,
        "temperature": temperature,
        "retrieval_only": False,
    }).encode()
    req = urllib.request.Request(
        CHAT_URL, body, {"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=120) as r:
        raw = r.read().decode("utf-8", "replace")
    # The hub may return JSON (message + contexts) or plain text; handle both.
    try:
        j = json.loads(raw)
        if isinstance(j, dict):
            return (j.get("message") or j.get("response")
                    or j.get("text") or json.dumps(j))[:8000]
        return str(j)[:8000]
    except json.JSONDecodeError:
        return raw[:8000]


class Handler(BaseHTTPRequestHandler):
    def _send(self, obj, code=200):
        data = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path.startswith("/api/tags"):
            self._send({"models": [FAKE_MODEL]})
        elif self.path.startswith("/api/version"):
            self._send({"version": "cs460-hub-adapter"})
        else:
            self._send({"error": "not found"}, 404)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        payload = json.loads(self.rfile.read(length) or b"{}")
        if self.path.startswith("/api/chat"):
            messages = payload.get("messages", [])
            temperature = (payload.get("options") or {}).get("temperature", 0.1)
            try:
                answer = ask_campus_hub(messages, temperature)
            except Exception as e:                      # don't leak the key in errors
                answer = f"[campus hub error] {type(e).__name__}"
            self._send({
                "model": payload.get("model", "campus-hub"),
                "created_at": "2024-01-01T00:00:00Z",
                "message": {"role": "assistant", "content": answer},
                "done": True,
                "done_reason": "stop",
            })
        elif self.path.startswith("/api/generate"):
            self._send({"model": payload.get("model", "campus-hub"),
                        "response": ask_campus_hub(
                            [{"role": "user", "content": payload.get("prompt", "")}], 0.1),
                        "done": True})
        else:
            self._send({"error": "not found"}, 404)

    def log_message(self, *a):   # keep the key out of request logs entirely
        return


if __name__ == "__main__":
    print(f"cs460 hub-adapter on :{PORT} -> {CHAT_URL} "
          f"(course={COURSE or 'UNSET'}, key={'set' if API_KEY else 'UNSET'})")
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
