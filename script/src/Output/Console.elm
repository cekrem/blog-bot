module Output.Console exposing (publish)

import BackendTask
import Domain.PublishedPost exposing (toPublished)
import Domain.SocialPost exposing (SocialPost)
import Output.Port exposing (Output)
import Pages.Script as Script


publish : Output
publish socialPosts =
    socialPosts
        |> List.map formatSocialPost
        |> String.join "\n\n"
        |> Script.log
        |> BackendTask.map (always (socialPosts |> toPublished))


formatSocialPost : SocialPost -> String
formatSocialPost socialPost =
    socialPost.body ++ "\n" ++ socialPost.link
