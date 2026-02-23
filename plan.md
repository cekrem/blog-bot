Here is a clean, consolidated, and downloadable Markdown file that captures the full conclusion of our conversation so far.

You can copy the content below and save it as `cekrem-blog-bot-plan.md` (or any name you like) on your computer. It summarizes the goal, constraints, agreed architecture, modules, development approach, and next steps — all in one self-contained document.

```markdown
# Cekrem Blog → X Autonomous Content Bot

Final Agreed Plan – February 23, 2026

## Project Goal

Build a **completely free**, autonomous system that:

- Detects **new blog posts** published on https://cekrem.github.io
- Uses a free LLM to generate engaging X (Twitter) content in your personal voice
  - short summaries + questions
  - interesting quotes + teasers
  - curiosity hooks / thread starters
- Posts the generated content to X automatically
- Includes strong owner control (kill switch, easy tweaks via config)
- Supports safe development & iteration

**Explicit non-goals (due to $0 budget):**

- Proactive replies to other people’s threads
- Daily semantic/keyword searches for relevant conversations
- Mention monitoring / reactive behavior
  → The bot only acts on **your new content** (outbound only)

## Hard Constraints (X API free tier – Feb 2026 reality)

- Posting allowed: ~500–1,500 tweets/month (conservative assumption: 500)
- Reading / search / mentions / timelines: effectively unusable (1 request per many hours or completely blocked)
- Execution environment: GitHub Actions (free tier)
- LLM: only free inference tiers (Groq, Gemini 1.5 Flash, Hugging Face Inference API…)
- No persistent server, no paid services, no API credits

## Agreed Architecture – Modular & Testable
```

cekrem-blog-bot/
├── .github/workflows/bot.yml # schedule + manual trigger
├── config/
│ ├── personality.yaml # tone, values, prompt templates, blog context
│ └── filters.yaml # optional: avoid topics, forced hashtags, etc.
├── state/
│ ├── last_guid.txt # last processed RSS guid/link
│ └── posted_this_month.json # rate-limit safety counter
├── logs/ # gitignored
│ └── mock_posts/ # output of mock adapter
├── src/
│ ├── personality.py
│ ├── generator.py # LLM wrapper
│ ├── adapters/
│ │ ├── base.py
│ │ ├── x_real.py # tweepy → live X posting
│ │ └── x_mock.py # print + save to file
│ └── main.py # RSS → generate → post
├── requirements.txt
└── PLAN.md # this file

```

## Core Modules

1. **Personality Module**
   - File: `config/personality.yaml`
   - Defines: tone, warmth, humor style, values, boundaries, disclosure rules, blog context/themes
   - Output: system prompt + few-shot examples used by LLM
   - Owner control: edit YAML → commit → behavior changes instantly

2. **Content Generator Module**
   - Calls free LLM (recommend Groq Llama-3.1-8B-Instant or similar fast/free model)
   - Input: new blog post (title + excerpt + link + optional full text)
   - Output: 1–3 tweet candidates (summary+question, quote+teaser, etc.)
   - Safety: length check, link required, guardrails via prompt

3. **Adapter Pattern** (platform targets)
   - Abstract base class
   - `x_mock.py`: development mode – prints to console + saves timestamped .txt files in `logs/mock_posts/`
   - `x_real.py`: production – uses tweepy + OAuth 1.0a to post live (secrets in GitHub)
   - Selected via env var `ADAPTER=mock` or `real` (or config file)

4. **Orchestrator (main.py)**
   - Polls blog RSS every run (cron: every 4–6 hours)
   - Compares guid/link against `state/last_guid.txt`
   - If new post → generate content → select best / post 1–2 → update state
   - Checks monthly post count → stops early if near limit
   - Respects kill switch (`secrets.ENABLE_BOT`)

5. **State & Control**
   - Kill switch: GitHub secret `ENABLE_BOT=false` → immediate exit
   - Rate limit guard: track posts this month, buffer at ~450
   - Tweaks: edit personality.yaml / filters.yaml → commit/push
   - Manual run: GitHub Actions “Run workflow” button

## Development & Safety Workflow
1. Develop & iterate with `ADAPTER=mock`
   → see generated tweets in console + saved files
2. Test full flow locally (`python src/main.py`) and via GitHub dispatch
3. Tweak personality / prompts → re-run until voice feels right
4. Only switch to `ADAPTER=real` when confident
5. Start with very low volume (1 post per new blog entry)
6. Monitor Actions logs + `posted_this_month.json`

## Must-Have Safety Features
- Auto-append disclosure: “generated with AI • original: {link}”
- Prompt guardrails: refuse politics/drama/off-topic
- Never exceed ~450 posts/month (hard stop)
- Easy emergency stop via secret toggle
- All changes owner-only (your repo, your secrets)

## Recommended Starting Tech Choices
- RSS: https://cekrem.github.io/feed.xml (or atom.xml / rss.xml)
- LLM: Groq API (free tier, fast inference)
- Library: tweepy (for real posting)
- Trigger: GitHub Actions schedule (`0 */4 * * *`) + workflow_dispatch

## Next Concrete Steps (after repo setup)
1. Create repo + folder structure
2. Add secrets: GROQ_API_KEY + X_* keys (even if using mock at first)
3. Write personality.yaml with your tone/values
4. Implement personality.py + generator.py
5. Build mock adapter first
6. Write main.py orchestrator
7. Create workflow file
8. Test end-to-end with mock → refine → go live

```
