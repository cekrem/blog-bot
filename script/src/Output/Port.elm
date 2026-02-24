module Output.Port exposing (Output)

import BackendTask exposing (BackendTask)
import Domain.Post exposing (Post, PublishedPost)
import FatalError exposing (FatalError)
import Set exposing (Set)


type alias Output =
    List Post -> BackendTask FatalError (Set PublishedPost)
