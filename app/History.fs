namespace BlogBot

open System
open System.IO
open BlogBot.Domain
open BlogBot.Pipeline

module History =

    let noHistory: HistoryIO =
        { Read = fun () -> async { return Ok Set.empty }
          Write = fun _ -> async { return Ok() } }

    let logFile (path: string) : HistoryIO =
        { Read =
            fun () ->
                async {
                    try
                        if File.Exists path then
                            let! content = File.ReadAllTextAsync(path) |> Async.AwaitTask

                            return
                                content.Split '\n'
                                |> Array.map _.Trim()
                                |> Array.filter (fun s -> s <> "" && not (s.StartsWith("#")))
                                |> Array.map PublishedPost
                                |> Set.ofArray
                                |> Ok
                        else
                            return Ok Set.empty
                    with ex ->
                        return Error(HistoryError $"Failed to read history: {ex.Message}")
                }
          Write =
            fun published ->
                async {
                    try
                        let timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()

                        let lines = published |> Set.toList |> List.map (fun (PublishedPost link) -> link)

                        let body = String.concat "\n" lines
                        let entry = $"\n\n# %d{timestamp}\n{body}\n"

                        do! File.AppendAllTextAsync(path, entry) |> Async.AwaitTask
                        return Ok()
                    with ex ->
                        return Error(HistoryError $"Failed to write history: {ex.Message}")
                } }
