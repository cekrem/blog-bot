module Transform.Port exposing (Transform)

import BackendTask exposing (BackendTask)
import Domain.Post exposing (Post)
import Domain.SocialPost exposing (SocialPost)
import FatalError exposing (FatalError)


type alias Transform =
    ( Post, List Post ) -> BackendTask FatalError ( SocialPost, List SocialPost )
