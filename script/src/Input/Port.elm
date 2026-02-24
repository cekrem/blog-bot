module Input.Port exposing (Input)

import BackendTask exposing (BackendTask)
import Domain.Post exposing (Post)
import FatalError exposing (FatalError)


type alias Input =
    BackendTask FatalError (List Post)
