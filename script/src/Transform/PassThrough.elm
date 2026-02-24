module Transform.PassThrough exposing (transform)

import BackendTask
import Domain.Post exposing (Post)
import Domain.SocialPost exposing (SocialPost)
import Transform.Port exposing (Transform)


transform : Transform
transform posts =
    posts
        |> List.map fromPost
        |> BackendTask.succeed


fromPost : Post -> SocialPost
fromPost post =
    { body = post.description
    , link = post.link
    }
