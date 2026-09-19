# RESOURCES — cognitive architecture, high-trust sources

Primary internal source for our lessons (authored by crew agent `mind`):

- `Cognitive-agent-literature/docs/cognitive-agents.html` — our 10-section knowledge
  page (what a cognitive agent is, CoALA, BDI, SDKs, MCP+A2A, evaluation, safety,
  our cabin-sim implementation, glossary, reading list). Local: repo on disk.

Background / canonical references (for citation in lessons):

- **CoALA (Cognitive Architectures for Language Agents)** — Sumers, Yao, Narasimhan,
  Griffiths (2023). Introduces the memory/action-space/reasoning-loop frame we use.
  arxiv.org/abs/2309.02427
- **BDI / STAAARS:** Rao & Georgeff, "BDI Agents: from theory to practice" (1995);
  Laird's SOAR for the goal-driven loop tradition. The belief-desire-intention pattern
  our Python bootstrap implements.
- **Google AI docs — Gemini API keys / LLM agents:** ai.google.dev (agent loop,
  model-agnostic "LLM + memory + tools" framing).
- **MCP (Model Context Protocol)** — modelcontextprotocol.io. **A2A (Agent2Agent)** —
  a2a-protocol.org. Both standardized agent interop surfaces we reference.
- **EWMA / exponential weighting** for the trust blend in `update_trust` — classic
  exponential smoothing (Holt 1957 / NIST handbook).
- **OpenAI-compatible chat completions** — the one wire format `cogarch_bootstrap.py`
  speaks to (works for OpenAI, ollama, llama.cpp, vLLM, Google's /openai surface).

## To explore when going deeper (later lessons)

- CoALA paper (read §3 memory, §4 action space).
- A tiny local brain: `ollama` + the default `qwen2.5:7b` the bootstrap already targets.
- Our cabin sim's `bdiReason` (see lesson 0002 candidate) — the same BDI shape in
  production state.