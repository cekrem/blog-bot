module Output.Console exposing (publish)

import BackendTask
import Domain.Post exposing (Post, toPublished)
import Output.Port exposing (Output)
import Pages.Script as Script


publish : Output
publish posts =
    posts
        |> List.map formatPost
        |> String.join "\n\n"
        |> Script.log
        |> BackendTask.map (always (posts |> toPublished))


formatPost : Post -> String
formatPost post =
    "## [" ++ post.title ++ "](" ++ post.link ++ "):\n\n" ++ post.description
