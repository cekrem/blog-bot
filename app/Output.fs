namespace BlogBot

open System
open System.IO
open System.Net.Http
open System.Text
open BlogBot.Domain
open BlogBot.Pipeline
open Thoth.Json.Net
open FsToolkit.ErrorHandling

module Output =

    let console: Output =
        fun socialPost ->
            async {
                printfn $"{socialPost.Body}\n{socialPost.Link}"
                return Ok(PublishedPost socialPost.Link)
            }

    let file (path: string) : Output =
        fun socialPost ->
            async {
                try
                    let content = $"{socialPost.Body}\n{socialPost.Link}"
                    do! File.WriteAllTextAsync(path, content) |> Async.AwaitTask
                    return Ok(PublishedPost socialPost.Link)
                with ex ->
                    return Error(OutputError $"Failed to write output file: {ex.Message}")
            }

    module Bluesky =

        type private Session =
            { Token: string
              Did: string
              Timestamp: string }

        let private httpClient = new HttpClient()

        let private authenticate (handle: string) (password: string) =
            asyncResult {
                let body =
                    Encode.object [ "identifier", Encode.string handle; "password", Encode.string password ]
                    |> Encode.toString 0

                let content = new StringContent(body, Encoding.UTF8, "application/json")

                let! response =
                    async {
                        try
                            let! resp =
                                httpClient.PostAsync(
                                    "https://bsky.social/xrpc/com.atproto.server.createSession",
                                    content
                                )
                                |> Async.AwaitTask

                            return Ok resp
                        with ex ->
                            return Error(OutputError $"Bluesky auth request failed: {ex.Message}")
                    }

                let! responseBody =
                    async {
                        try
                            let! body = response.Content.ReadAsStringAsync() |> Async.AwaitTask
                            return Ok body
                        with ex ->
                            return Error(OutputError $"Failed to read Bluesky auth response: {ex.Message}")
                    }

                if not response.IsSuccessStatusCode then
                    return! Error(OutputError $"Bluesky auth failed %d{int response.StatusCode}: {responseBody}")

                let decoder =
                    Decode.map2
                        (fun token did ->
                            { Token = token
                              Did = did
                              Timestamp = DateTimeOffset.UtcNow.ToString("o") })
                        (Decode.field "accessJwt" Decode.string)
                        (Decode.field "did" Decode.string)

                match Decode.fromString decoder responseBody with
                | Ok session -> return session
                | Error err -> return! Error(OutputError $"Failed to decode Bluesky session: {err}")
            }

        let private createFacets (socialPost: SocialPost) =
            let link = socialPost.Link
            let body = socialPost.Body
            let linkBytes = Encoding.UTF8.GetByteCount(link)

            let rec findIndexes (startIdx: int) acc =
                let idx = body.IndexOf(link, startIdx, StringComparison.Ordinal)

                if idx < 0 then
                    List.rev acc
                else
                    findIndexes (idx + 1) (idx :: acc)

            findIndexes 0 []
            |> List.map (fun charStart ->
                let byteStart = Encoding.UTF8.GetByteCount(body.Substring(0, charStart))
                let byteEnd = byteStart + linkBytes

                Encode.object
                    [ "features",
                      Encode.list
                          [ Encode.object
                                [ "$type", Encode.string "app.bsky.richtext.facet#link"
                                  "uri", Encode.string link ] ]
                      "index", Encode.object [ "byteStart", Encode.int byteStart; "byteEnd", Encode.int byteEnd ] ])
            |> Encode.list

        let private createPostRequest (session: Session) (socialPost: SocialPost) =
            Encode.object
                [ "repo", Encode.string session.Did
                  "collection", Encode.string "app.bsky.feed.post"
                  "record",
                  Encode.object
                      [ "$type", Encode.string "app.bsky.feed.post"
                        "text", Encode.string socialPost.Body
                        "createdAt", Encode.string session.Timestamp
                        "facets", createFacets socialPost ] ]
            |> Encode.toString 0

        let post (handle: string) (password: string) : Output =
            fun socialPost ->
                asyncResult {
                    let! session = authenticate handle password

                    let body = createPostRequest session socialPost

                    use request =
                        new HttpRequestMessage(
                            HttpMethod.Post,
                            "https://bsky.social/xrpc/com.atproto.repo.createRecord"
                        )

                    request.Headers.Add("Authorization", $"Bearer {session.Token}")
                    request.Content <- new StringContent(body, Encoding.UTF8, "application/json")

                    let! response =
                        async {
                            try
                                let! resp = httpClient.SendAsync(request) |> Async.AwaitTask
                                return Ok resp
                            with ex ->
                                return Error(OutputError $"Bluesky post request failed: {ex.Message}")
                        }

                    let! responseBody =
                        async {
                            try
                                let! body = response.Content.ReadAsStringAsync() |> Async.AwaitTask
                                return Ok body
                            with ex ->
                                return Error(OutputError $"Failed to read Bluesky post response: {ex.Message}")
                        }

                    if not response.IsSuccessStatusCode then
                        return! Error(OutputError $"Bluesky post failed %d{int response.StatusCode}: {responseBody}")

                    return PublishedPost socialPost.Link
                }
