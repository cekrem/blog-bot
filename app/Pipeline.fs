namespace BlogBot

open BlogBot.Domain
open FsToolkit.ErrorHandling

module Pipeline =

    type PipelineError =
        | InputError of string
        | TransformError of string
        | OutputError of string
        | HistoryError of string
        | ConfigError of string

    type Log = string -> unit

    type HistoryIO =
        { Read: unit -> Async<Result<Set<PublishedPost>, PipelineError>>
          Write: Set<PublishedPost> -> Async<Result<unit, PipelineError>> }

    type Input = unit -> Async<Result<Post list, PipelineError>>
    type Transform = Post -> Async<Result<SocialPost, PipelineError>>
    type Output = SocialPost -> Async<Result<PublishedPost, PipelineError>>

    let private filterPublished (history: Set<PublishedPost>) (posts: Post list) =
        posts
        |> List.filter (fun p -> not (Set.contains (PublishedPost p.Link) history))

    let run (log: Log) (historyIO: HistoryIO) (input: Input) (transform: Transform) (output: Output) =
        asyncResult {
            let! history = historyIO.Read()
            log $"Read %d{Set.count history} previously published posts"

            let! posts = input ()
            log $"Fetched %d{List.length posts} posts from input"

            let newPosts = filterPublished history posts

            match newPosts with
            | [] ->
                log "No new posts to publish"
                return ()
            | post :: _ ->
                log $"Processing 1 of %d{List.length newPosts} new posts"

                let! socialPost = transform post
                let! published = output socialPost

                do! historyIO.Write(Set.singleton published)
                log "Done! Published 1 post"
        }
