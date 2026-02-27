# blog-bot

An Elm script that reads my blog's RSS feed, asks an LLM to write a casual promo blurb, and posts it to Bluesky. Runs daily via GitHub Actions, or whenever I feel like hitting the button.

Later versions will probably be more ~~Skynet~~ autonomous and (e.g.) act on existing posts by replying with relevant content. But definitely not full-on free will bonanza.

## How it works

It's a pipeline with four pluggable stages:

1. **Input** -- fetches posts from my [blog's RSS feed](https://cekrem.github.io/index.xml)
2. **History** -- checks which posts have already been shared (so it doesn't spam the same thing twice)
3. **Transform** -- sends the latest unshared post to [Groq](https://groq.com/) (Llama 3.3 70B) to generate a social media-friendly blurb
4. **Output** -- posts the result to Bluesky (or console/file for testing)

Each stage is swappable via CLI flags. The whole thing is built with [elm-pages](https://elm-pages.com/) scripts and runs as a `BackendTask` pipeline.

## Usage

```bash
elm-pages run Main --input=rss --transform=groq --output=bluesky --history=file
```

All flags are optional and have defaults:

| Flag          | Options                      | Default |
| ------------- | ---------------------------- | ------- |
| `--input`     | `rss`                        | `rss`   |
| `--transform` | `groq`, `passthrough`        | `groq`  |
| `--output`    | `bluesky`, `console`, `file` | `file`  |
| `--history`   | `file`, `none`               | `none`  |

So for local testing you can just do:

```bash
elm-pages run Main
```

...and it'll fetch the RSS, run it through Groq, and write the result to a file. No Bluesky credentials needed.

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
script/
  src/
    Main.elm            -- CLI entry point, wires up the pipeline
    Pipeline.elm        -- the actual read -> filter -> transform -> output -> log flow
    Input/Rss.elm       -- parses the blog RSS feed
    Transform/GroqLLM.elm     -- LLM-powered blurb generation
    Transform/PassThrough.elm -- no-op transform (for testing)
    Output/Bluesky.elm  -- posts to Bluesky via AT Protocol
    Output/Console.elm  -- prints to stdout
    Output/File.elm     -- writes to a file
    History/LogFile.elm -- tracks shared posts in log.txt
    History/NoHistory.elm     -- no-op history (re-shares everything)
    Domain/Post.elm           -- blog post (title, link, description)
    Domain/SocialPost.elm     -- transformed post (body, link)
    Domain/PublishedPost.elm  -- just the link, for deduplication
```
