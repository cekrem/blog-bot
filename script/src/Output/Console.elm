module Output.Console exposing (publish)

import BackendTask
import Domain.PublishedPost exposing (toPublished)
import Domain.SocialPost exposing (SocialPost)
import Output.Port exposing (Output)
import Pages.Script as Script


publish : Output
publish ( first, rest ) =
    (first :: rest)
        |> List.map formatSocialPost
        |> String.join "\n\n"
        |> Script.log
        |> BackendTask.map (always ((first :: rest) |> toPublished))


formatSocialPost : SocialPost -> String
formatSocialPost socialPost =
    socialPost.body ++ "\n" ++ socialPost.link
