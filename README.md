# blog-bot

An F# CLI tool that reads my blog's RSS feed, asks an LLM to write a casual promo blurb, and posts it to Bluesky. Runs daily via GitHub Actions, or whenever I feel like hitting the button.

Previously written in Elm (see `script/` for the original elm-pages version). Now rewritten in F# (`app/`).

## How it works

It's a pipeline with four pluggable stages:

1. **Input** -- fetches posts from my [blog's RSS feed](https://cekrem.github.io/index.xml)
2. **History** -- checks which posts have already been shared (so it doesn't spam the same thing twice)
3. **Transform** -- sends the latest unshared post to [Groq](https://groq.com/) (Llama 3.3 70B) to generate a social media-friendly blurb
4. **Output** -- posts the result to Bluesky (or console/file for testing)

Each stage is swappable via CLI flags.

## Usage

```bash
dotnet run --project app -- --input=rss --transform=groq --output=bluesky --history=file
```

All flags are optional and have defaults:

| Flag          | Options                      | Default |
| ------------- | ---------------------------- | ------- |
| `--input`     | `rss`                        | `rss`   |
| `--transform` | `groq`, `passthrough`        | `groq`  |
| `--output`    | `bluesky`, `console`, `file` | `file`  |
| `--history`   | `file`, `none`               | `file`  |

For local testing:

```bash
dotnet run --project app -- --output=console --history=none
```

## Environment variables

| Variable           | Required for       |
| ------------------ | ------------------ |
| `GROQ_API_KEY`     | `--transform=groq` |
| `BLUESKY_HANDLE`   | `--output=bluesky` |
| `BLUESKY_PASSWORD` | `--output=bluesky` |

## GitHub Actions

There's a workflow that runs this daily at 10:00 UTC, or on manual trigger:

```
.github/workflows/post-to-bluesky.yml
```

Secrets are configured in the repo settings.

## Project structure

```
app/                          -- F# application (current)
  Domain.fs                   -- Post, SocialPost, PublishedPost types
  Pipeline.fs                 -- read -> filter -> transform -> output -> log flow
  Input.fs                    -- RSS feed fetcher
  Transform.fs                -- Groq LLM + passthrough transforms
  Output.fs                   -- Bluesky, console, and file outputs
  History.fs                  -- log.txt deduplication + no-op history
  Program.fs                  -- CLI entry point (Argu)

script/                       -- original Elm version (legacy)
```
