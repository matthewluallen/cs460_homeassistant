# Talking to your Home Assistant devices with an LLM (Module 5 extension)

Home Assistant has a built-in **Assist** chat (the speech-bubble icon, top-right of the HA web UI).
Point Assist at a conversation agent and you can type/say *"what's the air quality?"* or *"turn on the
lab light"* and the model answers or acts. Two ways to provide that agent — pick either or show both.

Either way, **Assist is the browser interface** and it controls a device only if that entity is
**exposed** to Assist (Settings → Voice assistants → Expose, or the "Control Home Assistant" toggle on
the agent). Over Tailscale you still add the physical device by IP first (see README); the LLM then
drives whatever entities HA already has.

---

## Option A — a LOCAL model on the Codespace (Ollama)  [validated]

Fully offline, no account, no key. Good for "the model runs right here next to the devices."

```
docker compose --profile llm up -d          # starts an Ollama server on :11434
docker exec ollama ollama pull qwen2.5:0.5b # a small CPU model (~400 MB); bigger = slower
```

Then in HA: Settings → Devices & Services → **Add Integration → Ollama** → URL `http://127.0.0.1:11434`
→ **Add conversation agent**, pick `qwen2.5:0.5b`, turn **Control Home Assistant** ON. Set it as your
Assist agent (Settings → Voice assistants). Chat from the Assist icon.

Validated here: HA connected to Ollama, created `conversation.local_llm`, and answered a prompt through
Assist in ~6 s on CPU with the 0.5b model. Bigger models (llama3.1:8b) are much slower on a Codespace's
CPU — keep demos to a small model.

---

## Option B — your OWN campus chatbot (chat.illinois.edu)  [each student uses their own login]

This is the "LLM hub" path. **Each student makes their own chatbot with their Illinois login** — no
shared key.

1. Go to **chat.illinois.edu**, sign in with your **Illinois** account.
2. Create a project/course (your chatbot) and **upload documents** to its knowledge base (device
   manuals, your HA config, the Module 5 readings, an SBOM…). This is the RAG corpus.
3. Open **Materials → API Key Management → Generate API Key**. Copy it. Note your **course name**.
4. Store them as **Codespaces secrets** (Settings → Secrets → Codespaces), granted to this repo:
   - `ILLINOIS_CHAT_API_KEY` = your key
   - `UIUC_COURSE_NAME` = your course name
   - (optional) `UIUC_MODEL` = e.g. `gpt-4o-mini` (default), or a campus model like `llama3.1:70b`
   **Never type the key into the Home Assistant UI** — it stays a secret the adapter reads from the
   environment. Rotate it from the same page if it leaks.
5. Start the adapter and point HA at it:
   ```
   docker compose --profile hub up -d          # Ollama-compatible shim on :11435
   ```
   HA: Add Integration → **Ollama** → URL `http://127.0.0.1:11435` → Add conversation agent → model
   **campus-hub** → Control Home Assistant ON → set as your Assist agent.

Now Assist routes your questions through **your** campus chatbot and its uploaded knowledge base, and
can act on exposed devices. (You can also just chat with the same bot directly in the chat.illinois.edu
web UI — handy for "what's in these documents?" style RAG without HA in the loop.)

### How the adapter works (and why it's safe)
`hub-adapter/` presents a tiny **Ollama-compatible** API (`/api/tags`, `/api/chat`) and forwards to
chat.illinois.edu's `/api/chat-api/chat`, injecting your `api_key` + `course_name` **from the
environment**. HA's built-in Ollama integration talks to any URL, so no custom HA add-on is needed. The
key is never logged and never entered in the HA UI. Validated here against a mock upstream: a chat
request in Ollama format is translated, the course name + key are attached server-side, and the reply
comes back in Ollama format.

> Note: chat.illinois.edu document **upload is via the website GUI** (API ingest is "coming soon"), so
> students build their knowledge base in the browser, not from code.

---

## Teaching angles (ties Module 5 together)
- **Local vs hosted model trade-off** — privacy/offline (Ollama on the device network) vs capability/RAG
  (campus hub). Same Assist front end, very different data-flow and trust story.
- **The LLM as an OT/IoT risk surface** — an agent that can *control* devices is a new attack surface:
  prompt injection via a device's own fields/names, over-broad entity exposure, and (for the hub) where
  your prompts + device data travel. Pairs with the Module 5 supply-chain / SBOM readings.
