module Transform.PassThrough exposing (transform)

import Domain.Post exposing (Post)
import Domain.SocialPost exposing (SocialPost)
import Transform.Port exposing (Transform)
import Utils.NonEmptyList exposing (ensureNonEmpty)


transform : Transform
transform ( first, rest ) =
    (first :: rest)
        |> List.map fromPost
        |> ensureNonEmpty


fromPost : Post -> SocialPost
fromPost post =
    { body = post.description
    , link = post.link
    }
