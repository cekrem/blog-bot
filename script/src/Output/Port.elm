module Output.Port exposing (Output)

import BackendTask exposing (BackendTask)
import Domain.Post exposing (Post)
import FatalError exposing (FatalError)


type alias Output =
    List Post -> BackendTask FatalError ()
