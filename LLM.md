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
docker exec ollama ollama pull llama3.2:3b  # a small TOOL-CALLING model (~2 GB)
```

Then in HA: Settings → Devices & Services → **Add Integration → Ollama** → URL `http://127.0.0.1:11434`
→ **Add conversation agent**, pick `llama3.2:3b`, turn **Control Home Assistant → Assist** ON. Set it as
your Assist agent (Settings → Voice assistants). Chat from the Assist icon.

**Why `llama3.2:3b` and not a tiny model:** to *read sensor values or control devices*, the model must
support **tool calling** — HA exposes an Assist tool (`GetLiveContext`) that the model calls to fetch the
real state. `llama3.2:3b` (and `qwen2.5:3b`) support tools; a 0.5b model can chat but can't reliably call
tools. **Validated live:** asked "what is the temperature right now?", `llama3.2:3b` called `GetLiveContext`
and answered **"The temperature right now is 76.9 °F"** — the real Cardputer reading. (CPU inference on a
Codespace is slow — ~60–90 s per tool-calling turn. Expose only the few entities you need to keep the
prompt small.)

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
   - (optional) `UIUC_MODEL` = a campus model name; default is `gemma3:27b` (validated working for the
     `cs460-ha` course)
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

> **The campus hub is a RAG chatbot, not a tool-calling agent.** Use it for *course-knowledge* Q&A
> ("what do these documents say about Modbus?"). Do **not** trust it for *live sensor values or control*:
> with no tool-calling it can't read HA state, so it **fabricates** a plausible answer. **Validated live:**
> asked for the Cardputer temperature, the hub confidently answered "22.5 °C / 68 %" with a made-up
> citation — the real values were ~24.8 °C / 33 %. For live reads/control use the local tool-calling
> model (Option A).

---

## Reading live sensor data (and the security lesson) [validated live]

Expose the entities (Settings → Voice assistants → **Expose**) and turn on **Control Home Assistant →
Assist** on the agent. Then the three outcomes we saw, side by side:

| Agent | Tool-calling? | "What is the temperature?" |
|---|---|---|
| campus hub (RAG) | no | **Hallucinated** "22.5 °C / 68 %" + fake citation (confidently wrong) |
| `llama3.2:3b`, over-specific query | yes | called `GetLiveContext` with a guessed area → honest *"unable to find"* |
| `llama3.2:3b`, clean query | yes | ✅ `GetLiveContext` → **"76.9 °F"** (the real reading) |

The lesson: the Assist *mechanism* for state access is tool-calling; whether you get a correct answer, an
honest failure, or a dangerous fabrication depends entirely on the **model's capability** — and giving an
LLM tools that *control* real devices is a new, powerful attack surface.

---

## Teaching angles (ties Module 5 together + security frameworks)
- **Local vs hosted model trade-off** — privacy/offline (Ollama on the device network) vs capability/RAG
  (campus hub). Same Assist front end, very different data-flow and trust story.
- **The LLM as an OT/IoT risk surface** — an agent that can *control* devices is a new attack surface:
  prompt injection via a device's own fields/names, over-broad entity exposure, and (for the hub) where
  your prompts + device data travel. Pairs with the Module 5 supply-chain / SBOM readings.
- **Framework mapping (AI side):**
  - **OWASP LLM Top 10 (2025):** LLM09 Misinformation (the hub's fabricated reading), LLM06 Excessive
    Agency + LLM05 Improper Output Handling (an LLM with device-control tools), LLM01 Prompt Injection
    (device names/fields as untrusted input), LLM02 Sensitive Information Disclosure (prompts + device
    data leaving to the hub).
  - **MITRE ATLAS** (adversarial-AI ATT&CK): AML.T0051 Prompt Injection (direct .001 / indirect .002),
    ML Model Access tactic (AML.TA0004).
  - **CWE:** CWE-1426 Improper Validation of Generative AI Output, CWE-1427 Improper Neutralization of
    Input Used for LLM Prompting (prompt injection), CWE-1434 Insecure Setting of GenAI Inference
    Parameters (→ hallucination).
- **Framework mapping (IoT/OT side):** MITRE **ATT&CK for ICS** for the Modbus/discovery lessons, plus
  CWEs for the network-reachability story (least-privilege subnet routing, discovery-vs-access).
