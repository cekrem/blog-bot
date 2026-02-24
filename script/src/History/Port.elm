module History.Port exposing (HistoryIO, Read, Write)

import BackendTask exposing (BackendTask)
import Domain.PublishedPost exposing (PublishedPost)
import FatalError exposing (FatalError)
import Set exposing (Set)


type alias Read =
    BackendTask FatalError (Set PublishedPost)


type alias Write =
    BackendTask FatalError ()


type alias HistoryIO =
    { read : Read
    , write : Set PublishedPost -> Write
    }
