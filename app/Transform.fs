namespace BlogBot

open System.Net.Http
open System.Text
open BlogBot.Domain
open BlogBot.Pipeline
open Thoth.Json.Net
open FsToolkit.ErrorHandling

module Transform =

    let passThrough: Transform =
        fun post ->
            async {
                return
                    Ok
                        { Body = post.Description
                          Link = post.Link }
            }

    module Groq =

        let private formatPrompt (post: Post) =
            $"""You are my social media assistant. Friendlyness and politeness are among your
core values, and you will never (ever!) output anything offensive or rude at any point.

At the end of this message I will send you my most recent post and its URL,
and you will compose a Twitter/X friendly promotional message I will post.

Add the URL where you see fit within the message.

Try to refrain from typical AI-jargon, and keep a casual (and slightly nerdy) tone.

The final post should be pure ASCII, with a length under 300 characters (including the URL),
this is a hard limit!

Important note: Your answer should be _only_ the social media post content, no introduction before or
conclusion after. And no surrounding quotes(!); just the exact thing to post on social media.

Post follows here:

  Post title: {post.Title}
Post description: {post.Description}
Post url: {post.Link}
"""

        let private encodeRequest (prompt: string) =
            Encode.object
                [ "messages",
                  Encode.list [ Encode.object [ "content", Encode.string prompt; "role", Encode.string "user" ] ]
                  "model", Encode.string "groq/compound-mini" ]
            |> Encode.toString 0

        let private decodeResponse (json: string) =
            let decoder =
                Decode.field "choices" (Decode.index 0 (Decode.field "message" (Decode.field "content" Decode.string)))

            Decode.fromString decoder json |> Result.map (fun s -> s.Trim('"'))

        let private httpClient = new HttpClient()

        let transform (apiKey: string) : Transform =
            fun post ->
                asyncResult {
                    let requestBody = formatPrompt post |> encodeRequest

                    use request =
                        new HttpRequestMessage(HttpMethod.Post, "https://api.groq.com/openai/v1/chat/completions")

                    request.Headers.Add("Authorization", $"Bearer {apiKey}")
                    request.Content <- new StringContent(requestBody, Encoding.UTF8, "application/json")

                    let! response =
                        async {
                            try
                                let! resp = httpClient.SendAsync(request) |> Async.AwaitTask
                                return Ok resp
                            with ex ->
                                return Error(TransformError $"Groq API request failed: {ex.Message}")
                        }

                    let! responseBody =
                        async {
                            try
                                let! body = response.Content.ReadAsStringAsync() |> Async.AwaitTask
                                return Ok body
                            with ex ->
                                return Error(TransformError $"Failed to read Groq response: {ex.Message}")
                        }

                    if not response.IsSuccessStatusCode then
                        return! Error(TransformError $"Groq API error %d{int response.StatusCode}: {responseBody}")

                    match decodeResponse responseBody with
                    | Ok body -> return { Body = body; Link = post.Link }
                    | Error err -> return! Error(TransformError $"Failed to decode Groq response: {err}")
                }
