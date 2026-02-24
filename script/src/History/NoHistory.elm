module History.NoHistory exposing (noop)

import BackendTask exposing (BackendTask)
import Domain.Post exposing (PublishedPost)
import FatalError exposing (FatalError)
import History.Port exposing (HistoryIO)
import Pages.Script as Script
import Set exposing (Set)


read : BackendTask FatalError (Set PublishedPost)
read =
    BackendTask.succeed Set.empty


write : Set PublishedPost -> BackendTask FatalError ()
write publishedPost =
    publishedPost
        |> Set.toList
        |> String.join "\n"
        |> String.append "Published these posts:\n"
        |> Script.log


noop : HistoryIO
noop =
    { read = read
    , write = write
    }
