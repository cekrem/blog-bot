module Input.Port exposing (Input)

import BackendTask exposing (BackendTask)
import Domain.Post exposing (Post)
import FatalError exposing (FatalError)


type alias Input =
    BackendTask FatalError ( Post, List Post )
