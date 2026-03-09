open System
open Argu
open BlogBot.Pipeline

type CliArgs =
    | History of string
    | [<AltCommandLine("-i")>] Input of string
    | [<AltCommandLine("-t")>] Transform of string
    | [<AltCommandLine("-o")>] Output of string

    interface IArgParserTemplate with
        member this.Usage =
            match this with
            | History _ -> "History provider: none, file (default: file)"
            | Input _ -> "Input source: rss (default: rss)"
            | Transform _ -> "Transform: groq, passthrough (default: groq)"
            | Output _ -> "Output target: console, file, bluesky (default: file)"

let requireEnv name =
    Environment.GetEnvironmentVariable(name)
    |> Option.ofObj
    |> Option.defaultWith (fun () -> failwith $"{name} not set")

let log = printfn "%s"

[<EntryPoint>]
let main argv =
    let parser = ArgumentParser.Create<CliArgs>(programName = "blog-bot")
    let results = parser.ParseCommandLine(inputs = argv, raiseOnUsage = true)

    let history =
        match results.GetResult(History, defaultValue = "file") with
        | "none" -> BlogBot.History.noHistory
        | _ -> BlogBot.History.logFile "log.txt"

    let input =
        match results.GetResult(Input, defaultValue = "rss") with
        | _ -> BlogBot.Input.rss "https://cekrem.github.io/index.xml"

    let transform =
        match results.GetResult(Transform, defaultValue = "groq") with
        | "passthrough" -> BlogBot.Transform.passThrough
        | _ -> BlogBot.Transform.Groq.transform (requireEnv "GROQ_API_KEY")

    let output =
        match results.GetResult(Output, defaultValue = "file") with
        | "console" -> BlogBot.Output.console
        | "bluesky" -> BlogBot.Output.Bluesky.post (requireEnv "BLUESKY_HANDLE") (requireEnv "BLUESKY_PASSWORD")
        | _ -> BlogBot.Output.file "output.txt"

    match run log history input transform output |> Async.RunSynchronously with
    | Ok() -> 0
    | Error err ->
        match err with
        | InputError msg -> eprintfn $"Input error: {msg}"
        | TransformError msg -> eprintfn $"Transform error: {msg}"
        | OutputError msg -> eprintfn $"Output error: {msg}"
        | HistoryError msg -> eprintfn $"History error: {msg}"
        | ConfigError msg -> eprintfn $"Config error: {msg}"

        1
