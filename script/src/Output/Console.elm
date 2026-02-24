module Output.Console exposing (publish)

import Domain.Post exposing (Post)
import Output.Port exposing (Output)
import Pages.Script as Script


publish : Output
publish posts =
    posts
        |> List.map formatPost
        |> String.join "\n\n"
        |> Script.log


formatPost : Post -> String
formatPost post =
    "## [" ++ post.title ++ "](" ++ post.link ++ "):\n\n" ++ post.description
