module Output.File exposing (write)

import BackendTask
import BackendTask.Stream as Stream
import Domain.PublishedPost exposing (toPublished)
import Domain.SocialPost exposing (SocialPost)
import Output.Port exposing (Output)


write : Output
write ( first, rest ) =
    (first :: rest)
        |> List.map formatSocialPost
        |> List.map (Stream.fromString >> Stream.pipe (Stream.fileWrite "output.txt") >> Stream.run)
        |> BackendTask.combine
        |> BackendTask.map (always ((first :: rest) |> toPublished))


formatSocialPost : SocialPost -> String
formatSocialPost socialPost =
    socialPost.body ++ "\n" ++ socialPost.link
