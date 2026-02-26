module Main exposing (run)

import BackendTask
import Cli.Option as Option
import Cli.OptionsParser as OptionsParser
import Cli.Program as Program
import Dict exposing (Dict)
import FatalError
import History.LogFile as LogFile
import History.NoHistory as NoHistory
import History.Port exposing (HistoryIO)
import Input.Port exposing (Input)
import Input.Rss as Rss
import Output.Console as Console
import Output.File as OutputFile
import Output.Port exposing (Output)
import Pages.Script as Script exposing (Script)
import Pipeline
import Transform.GroqLLM as GroqLLM
import Transform.PassThrough as PassThrough
import Transform.Port exposing (Transform)


type alias CliOptions =
    { history : String
    , input : String
    , transform : String
    , output : String
    }


run : Script
run =
    Script.withCliOptions programConfig
        (\options ->
            case resolve options of
                Err error ->
                    BackendTask.fail
                        (FatalError.build
                            { title = "Invalid CLI options"
                            , body = error
                            }
                        )

                Ok { history, input, transform, output } ->
                    Pipeline.run history input transform output
        )


programConfig : Program.Config CliOptions
programConfig =
    Program.config
        |> Program.add
            (OptionsParser.build CliOptions
                |> OptionsParser.with
                    (Option.optionalKeywordArg "history"
                        |> Option.withDefault "file"
                    )
                |> OptionsParser.with
                    (Option.optionalKeywordArg "input"
                        |> Option.withDefault "rss"
                    )
                |> OptionsParser.with
                    (Option.optionalKeywordArg "transform"
                        |> Option.withDefault "groq"
                    )
                |> OptionsParser.with
                    (Option.optionalKeywordArg "output"
                        |> Option.withDefault "console"
                    )
            )



-- Registry


histories : Dict String HistoryIO
histories =
    Dict.fromList
        [ ( "none", NoHistory.noop )
        , ( "file", LogFile.io )
        ]


inputs : Dict String Input
inputs =
    Dict.fromList
        [ ( "rss", Rss.fetch )
        ]


transforms : Dict String Transform
transforms =
    Dict.fromList
        [ ( "passthrough", PassThrough.transform )
        , ( "groq", GroqLLM.run )
        ]


outputs : Dict String Output
outputs =
    Dict.fromList
        [ ( "console", Console.publish )
        , ( "file", OutputFile.write )
        ]



-- Resolve


type alias ResolvedOptions =
    { history : HistoryIO
    , input : Input
    , transform : Transform
    , output : Output
    }


resolve : CliOptions -> Result String ResolvedOptions
resolve options =
    Result.map4 ResolvedOptions
        (lookup "history" options.history histories)
        (lookup "input" options.input inputs)
        (lookup "transform" options.transform transforms)
        (lookup "output" options.output outputs)


lookup : String -> String -> Dict String a -> Result String a
lookup label key dict =
    case Dict.get key dict of
        Just value ->
            Ok value

        Nothing ->
            Err
                ("Unknown "
                    ++ label
                    ++ ": \""
                    ++ key
                    ++ "\". Available: "
                    ++ (Dict.keys dict |> String.join ", ")
                )
