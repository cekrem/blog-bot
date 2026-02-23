module Main exposing (run)

import BackendTask exposing (BackendTask)
import BackendTask.Http
import FatalError exposing (FatalError)
import Pages.Script as Script exposing (Script)


run : Script
run =
    Script.withoutCliOptions
        (fetchRawRss
            |> BackendTask.map parseLatestPosts
            |> BackendTask.andThen
                (\posts ->
                    Script.log posts
                )
        )


fetchRawRss : BackendTask FatalError String
fetchRawRss =
    BackendTask.Http.get "https://cekrem.github.io/index.xml"
        BackendTask.Http.expectString
        |> BackendTask.allowFatal


formatPost : String -> String
formatPost rawEntry =
    "## ["
        ++ (rawEntry |> parseProp "title")
        ++ "]("
        ++ (rawEntry |> parseProp "link")
        ++ "):\n\n"
        ++ (rawEntry |> parseProp "description")


parseLatestPosts : String -> String
parseLatestPosts =
    String.split "<item>\n"
        >> List.drop 1
        >> List.take 5
        >> List.map String.trim
        >> List.map formatPost
        >> String.join "\n\n"


parseProp : String -> String -> String
parseProp prop =
    String.split (prop ++ ">")
        >> List.drop 1
        >> List.head
        >> Maybe.withDefault ""
        >> String.dropRight 2
