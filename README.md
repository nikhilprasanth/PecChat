# Petrocil Chat

Internal AI chat application for Petrocil Engineers & Consultants.
Built on [LibreChat](https://github.com/danny-avila/LibreChat) with a local [llama.cpp](https://github.com/ggerganov/llama.cpp) backend.
Fully air-gappable — no internet required at runtime.

---

## Architecture

```
Browser
  │
  ▼ :9090
┌─────────────────┐     ┌──────────────────────┐
│  LibreChat API  │────▶│  llama.cpp server     │
│  (Docker)       │     │  host:8095  (Windows) │
└────────┬────────┘     │  Model: PEC/PEC-9B    │
         │              └──────────────────────┘
    ┌────┴──────────────────────────────────────┐
    │  MongoDB :27017 │ Meilisearch :7700        │
    │  RAG API :8000  │ VectorDB (pgvector)      │
    └──────────────────────────────────────────┘
          (all inside Docker network)
```

All services run in Docker. llama.cpp runs on the Windows host and is reached
from Docker via `host.docker.internal:8095`.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Windows 10/11 | WSL2 enabled |
| Docker Desktop ≥ 4.x | Must be running before any script |
| llama.cpp server | Running on port **8095** on the host |
| ~6 GB disk | For Docker images on first pull |

---

## llama.cpp Setup

Start the model server on the host machine before using the chat:

```bat
set CUDA_VISIBLE_DEVICES=0
"C:\Users\nikhil\Desktop\llamacpp\llama-server.exe" ^
  -m "C:\Users\nikhil\Downloads\model\qwen\Qwen3.5-9B-UD-Q4_K_XL.gguf" ^
  --mmproj "C:\Users\nikhil\Downloads\model\qwen\Qwen3.5-9B-UD-Q4_K_XL_mmproj-F16.gguf" ^
  -a "PEC/PEC-9B" --host 0.0.0.0 --port 8095 --jinja -fa on ^
  --fit on --fit-ctx 80000 --fit-target 512 ^
  -t 12 -b 2048 -ub 512 --no-mmap ^
  --temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.00 ^
  --presence-penalty 1.5 ^
  --chat-template-kwargs "{\"enable_thinking\": true}"
```

The alias `-a "PEC/PEC-9B"` must match the model name in `librechat.yaml`.

---

## Development (Internet PC)

```bat
REM 1. Start llama.cpp (see above)
REM 2. Start all Docker services
docker compose up -d
REM 3. Open the app
start http://localhost:9090
```

Stop:  `docker compose down`
Logs:  `docker logs LibreChat -f`

---

## Air-Gapped Deployment

### Step 1 — Internet PC: build the package

Double-click **`prepare.bat`** from the project root.

- Saves all 5 Docker images to `petrocil-deploy\saved-images\` (~2–3 GB)
- Copies config, assets, and compose files
- Generates ready-to-run scripts

> Takes 5–10 minutes. Each run rebuilds the package from scratch.

### Step 2 — Transfer

Copy the entire `petrocil-deploy\` folder to the target PC (USB, network share, etc.).

### Step 3 — Air-gapped PC: deploy

1. Install Docker Desktop and start it
2. Start llama.cpp on port 8095
3. Double-click **`petrocil-deploy\deploy.bat`**
4. Open **http://localhost:9090**

### Scripts inside `petrocil-deploy\`

| Script | Action |
|---|---|
| `deploy.bat` | Load images + start all containers |
| `stop.bat` | Stop all containers (data preserved) |
| `restart.bat` | Restart only the API (after config changes) |

---

## Configuration

### `librechat.yaml` — AI provider

```yaml
endpoints:
  custom:
    - name: 'Petrocil AI'
      baseURL: 'http://host.docker.internal:8095/v1'
      models:
        default: ['PEC/PEC-9B']
        fetch: true       # auto-discovers models from llama.cpp /v1/models
      addParams:
        top_k: 20
        min_p: 0.00
        presence_penalty: 1.5
      dropParams: ['user', 'frequency_penalty']
```

### `.env` — key variables

| Variable | Value | Notes |
|---|---|---|
| `PORT` | `9090` | Host port for the web UI |
| `APP_TITLE` | `Petrocil Chat` | Browser tab title |
| `ENDPOINTS` | `custom` | Hides all built-in AI providers |
| `UID` / `GID` | `1000` | Container user (required on Windows) |

> **Production:** Replace `JWT_SECRET`, `JWT_REFRESH_SECRET`, `CREDS_KEY`, `CREDS_IV`
> with unique values from https://www.librechat.ai/toolkit/creds_generator

---

## Petrocil Branding — Files Changed from Upstream

| File | Change |
|---|---|
| `client/index.html` | `<title>` and meta description |
| `client/src/routes/Layouts/Startup.tsx` | Fallback `document.title` |
| `client/src/components/Auth/AuthLayout.tsx` | Logo path `logo.svg` → `logo.png` |
| `client/src/components/Chat/Footer.tsx` | Default footer text |
| `client/src/components/Nav/SettingsTabs/About/About.tsx` | Diagnostics label |
| `client/src/components/Agents/Marketplace.tsx` | Page title suffix |
| `client/src/locales/en/translation.json` | `com_agents_mcp_trust_subtext` |
| `client/public/assets/logo.png` | Petrocil logo (new file) |
| `client/public/assets/favicon-*.png` | Replaced with Petrocil logo |

`docker-compose.override.yml` bind-mounts `logo.png` at both `logo.png` and
`logo.svg` so the pre-built image serves the correct logo without a custom build.

---

## Directory Structure

```
LibreChat/
├── prepare.bat                    ← internet PC: build deploy package
├── librechat.yaml                 ← AI endpoint config
├── .env                           ← environment config
├── docker-compose.yml             ← upstream base (do not edit)
├── docker-compose.override.yml    ← logo + config mounts
├── scripts/
│   ├── deploy-template.bat        ← template → petrocil-deploy\deploy.bat
│   ├── stop-template.bat
│   ├── restart-template.bat
│   └── deploy-override.yml        ← override template for deploy package
├── client/
│   ├── public/assets/logo.png     ← Petrocil logo
│   └── src/                       ← branding changes (see table above)
└── petrocil-deploy/               ← generated by prepare.bat (gitignored)
    ├── saved-images/              ← Docker image tar files
    ├── assets/                    ← logo + favicons
    ├── .env  librechat.yaml  docker-compose*.yml
    ├── deploy.bat  stop.bat  restart.bat
    └── data-node/  logs/  uploads/  images/  meili_data*/  skill/
```

---

## Troubleshooting

**Login page shows wrong logo**
Volume mounts not applied. Run `docker compose up -d` (not `start`) to recreate
the container.

**"No models available"**
llama.cpp not reachable. Verify from host and container:
```bat
curl http://localhost:8095/v1/models
docker exec LibreChat curl http://host.docker.internal:8095/v1/models
```

**Container won't start**
```bat
docker logs LibreChat
```
If MongoDB isn't ready, wait 10 s and run `docker compose up -d` again.

**Port conflict**
Change `PORT`, `DOMAIN_CLIENT`, and `DOMAIN_SERVER` in `.env`, then
`docker compose up -d`.

---

## Updating from Upstream LibreChat

See **[UPDATING.md](UPDATING.md)** for LLM-ready step-by-step instructions on
merging upstream changes without losing Petrocil customisations.

---

*Based on LibreChat — upstream README preserved in git history.*


# ✨ Features

- 🖥️ **UI & Experience** inspired by ChatGPT with enhanced design and features

- 🤖 **AI Model Selection**:  
  - Anthropic (Claude), AWS Bedrock, OpenAI, Azure OpenAI, Google, Vertex AI, OpenAI Responses API (incl. Azure)
  - [Custom Endpoints](https://www.librechat.ai/docs/quick_start/custom_endpoints): Use any OpenAI-compatible API with LibreChat, no proxy required
  - Compatible with [Local & Remote AI Providers](https://www.librechat.ai/docs/configuration/librechat_yaml/ai_endpoints):
    - Ollama, groq, Cohere, Mistral AI, Apple MLX, koboldcpp, together.ai,
    - OpenRouter, Helicone, Perplexity, ShuttleAI, Deepseek, Qwen, and more

- 🔧 **[Code Interpreter API](https://www.librechat.ai/docs/features/code_interpreter)**: 
  - Secure, Sandboxed Execution in Python, Node.js (JS/TS), Go, C/C++, Java, PHP, Rust, and Fortran
  - Seamless File Handling: Upload, process, and download files directly
  - No Privacy Concerns: Fully isolated and secure execution

- 🔦 **Agents & Tools Integration**:  
  - **[LibreChat Agents](https://www.librechat.ai/docs/features/agents)**:
    - No-Code Custom Assistants: Build specialized, AI-driven helpers
    - Agent Marketplace: Discover and deploy community-built agents
    - Collaborative Sharing: Share agents with specific users and groups
    - Flexible & Extensible: Use MCP Servers, tools, file search, code execution, and more
    - [Skills](https://www.librechat.ai/docs/features/skills): Create reusable `SKILL.md` instruction bundles for manual, automatic, or always-on agent workflows
    - [Subagents](https://www.librechat.ai/docs/features/subagents): Delegate focused work to isolated child agent runs with their own context windows
    - Compatible with Custom Endpoints, OpenAI, Azure, Anthropic, AWS Bedrock, Google, Vertex AI, Responses API, and more
    - [Model Context Protocol (MCP) Support](https://modelcontextprotocol.io/clients#librechat) for Tools

- 🔍 **Web Search**:  
  - Search the internet and retrieve relevant information to enhance your AI context
  - Combines search providers, content scrapers, and result rerankers for optimal results
  - **Customizable Jina Reranking**: Configure custom Jina API URLs for reranking services
  - **[Learn More →](https://www.librechat.ai/docs/features/web_search)**

- 🪄 **Generative UI with Code Artifacts**:  
  - [Code Artifacts](https://youtu.be/GfTj7O4gmd0?si=WJbdnemZpJzBrJo3) allow creation of React, HTML, and Mermaid diagrams directly in chat

- 🎨 **Image Generation & Editing**
  - Text-to-image and image-to-image with [GPT-Image-1](https://www.librechat.ai/docs/features/image_gen#1--openai-image-tools-recommended)
  - Text-to-image with [DALL-E (3/2)](https://www.librechat.ai/docs/features/image_gen#2--dalle-legacy), [Stable Diffusion](https://www.librechat.ai/docs/features/image_gen#3--stable-diffusion-local), [Flux](https://www.librechat.ai/docs/features/image_gen#4--flux), or any [MCP server](https://www.librechat.ai/docs/features/image_gen#5--model-context-protocol-mcp)
  - Produce stunning visuals from prompts or refine existing images with a single instruction

- 💾 **Presets & Context Management**:  
  - Create, Save, & Share Custom Presets  
  - Switch between AI Endpoints and Presets mid-chat
  - Edit, Resubmit, and Continue Messages with Conversation branching  
  - Create and share prompts with specific users and groups
  - [Fork Messages & Conversations](https://www.librechat.ai/docs/features/fork) for Advanced Context control

- 💬 **Multimodal & File Interactions**:  
  - Upload and analyze images with Claude 3, GPT-4.5, GPT-4o, o1, Llama-Vision, and Gemini 📸  
  - Chat with Files using Custom Endpoints, OpenAI, Azure, Anthropic, AWS Bedrock, & Google 🗃️

- 🌎 **Multilingual UI**:
  - English, 中文 (简体), 中文 (繁體), العربية, Deutsch, Español, Français, Italiano
  - Polski, Português (PT), Português (BR), Русский, 日本語, Svenska, 한국어, Tiếng Việt
  - Türkçe, Nederlands, עברית, Català, Čeština, Dansk, Eesti, فارسی
  - Suomi, Magyar, Հայերեն, Bahasa Indonesia, ქართული, Latviešu, ไทย, ئۇيغۇرچە

- 🧠 **Reasoning UI**:  
  - Dynamic Reasoning UI for Chain-of-Thought/Reasoning AI models like DeepSeek-R1

- 🎨 **Customizable Interface**:  
  - Customizable Dropdown & Interface that adapts to both power users and newcomers

- 🌊 **[Resumable Streams](https://www.librechat.ai/docs/features/resumable_streams)**:  
  - Never lose a response: AI responses automatically reconnect and resume if your connection drops
  - Multi-Tab & Multi-Device Sync: Open the same chat in multiple tabs or pick up on another device
  - Production-Ready: Works from single-server setups to horizontally scaled deployments with Redis

- 🗣️ **Speech & Audio**:  
  - Chat hands-free with Speech-to-Text and Text-to-Speech  
  - Automatically send and play Audio  
  - Supports OpenAI, Azure OpenAI, and Elevenlabs

- 📥 **Import & Export Conversations**:  
  - Import Conversations from LibreChat, ChatGPT, Chatbot UI  
  - Export conversations as screenshots, markdown, text, json

- 🔍 **Search & Discovery**:  
  - Search all messages/conversations

- 👥 **Multi-User & Secure Access**:
  - Multi-User, Secure Authentication with OAuth2, LDAP, & Email Login Support
  - Built-in Moderation, and Token spend tools

- ⚙️ **Configuration & Deployment**:  
  - Configure Proxy, Reverse Proxy, Docker, & many Deployment options  
  - Use [S3 with CloudFront](https://www.librechat.ai/docs/configuration/cdn/cloudfront) for stable media links, edge delivery, signed cookies, and secured downloads
  - Use completely local or deploy on the cloud

- 📖 **Open-Source & Community**:  
  - Completely Open-Source & Built in Public  
  - Community-driven development, support, and feedback

[For a thorough review of our features, see our docs here](https://docs.librechat.ai/) 📚

## 🪶 All-In-One AI Conversations with LibreChat

LibreChat is a self-hosted AI chat platform that unifies all major AI providers in a single, privacy-focused interface.

Beyond chat, LibreChat provides AI Agents, Model Context Protocol (MCP) support, Artifacts, Code Interpreter, custom actions, conversation search, and enterprise-ready multi-user authentication.

Open source, actively developed, and built for anyone who values control over their AI infrastructure.

---

## 🌐 Resources

**GitHub Repo:**
  - **RAG API:** [github.com/danny-avila/rag_api](https://github.com/danny-avila/rag_api)
  - **Website:** [github.com/LibreChat-AI/librechat.ai](https://github.com/LibreChat-AI/librechat.ai)

**Other:**
  - **Website:** [librechat.ai](https://librechat.ai)
  - **Documentation:** [librechat.ai/docs](https://librechat.ai/docs)
  - **Blog:** [librechat.ai/blog](https://librechat.ai/blog)

---

## 📝 Changelog

Keep up with the latest updates by visiting the releases page and notes:
- [Releases](https://github.com/danny-avila/LibreChat/releases)
- [Changelog](https://www.librechat.ai/changelog) 

**⚠️ Please consult the [changelog](https://www.librechat.ai/changelog) for breaking changes before updating.**

---

## ⭐ Star History

<p align="center">
  <a href="https://star-history.com/#danny-avila/LibreChat&Date">
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=danny-avila/LibreChat&type=Date&theme=dark" onerror="this.src='https://api.star-history.com/svg?repos=danny-avila/LibreChat&type=Date'" />
  </a>
</p>
<p align="center">
  <a href="https://trendshift.io/repositories/4685" target="_blank" style="padding: 10px;">
    <img src="https://trendshift.io/api/badge/repositories/4685" alt="danny-avila%2FLibreChat | Trendshift" style="width: 250px; height: 55px;" width="250" height="55"/>
  </a>
  <a href="https://runacap.com/ross-index/q1-24/" target="_blank" rel="noopener" style="margin-left: 20px;">
    <img style="width: 260px; height: 56px" src="https://runacap.com/wp-content/uploads/2024/04/ROSS_badge_white_Q1_2024.svg" alt="ROSS Index - Fastest Growing Open-Source Startups in Q1 2024 | Runa Capital" width="260" height="56"/>
  </a>
</p>

---

## ✨ Contributions

Contributions, suggestions, bug reports and fixes are welcome!

For new features, components, or extensions, please open an issue and discuss before sending a PR.

If you'd like to help translate LibreChat into your language, we'd love your contribution! Improving our translations not only makes LibreChat more accessible to users around the world but also enhances the overall user experience. Please check out our [Translation Guide](https://www.librechat.ai/docs/translation).

---

## 💖 This project exists in its current state thanks to all the people who contribute

<a href="https://github.com/danny-avila/LibreChat/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=danny-avila/LibreChat" />
</a>

---

## 🎉 Special Thanks

We thank [Locize](https://locize.com) for their translation management tools that support multiple languages in LibreChat.

<p align="center">
  <a href="https://locize.com" target="_blank" rel="noopener noreferrer">
    <img src="https://github.com/user-attachments/assets/d6b70894-6064-475e-bb65-92a9e23e0077" alt="Locize Logo" height="50">
  </a>
</p>
