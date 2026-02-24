module Output.Port exposing (Output)

import BackendTask exposing (BackendTask)
import Domain.PublishedPost exposing (PublishedPost)
import Domain.SocialPost exposing (SocialPost)
import FatalError exposing (FatalError)
import Set exposing (Set)


type alias Output =
    List SocialPost -> BackendTask FatalError (Set PublishedPost)
