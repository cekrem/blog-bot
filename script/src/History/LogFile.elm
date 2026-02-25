module History.LogFile exposing (io)

import BackendTask exposing (BackendTask)
import Domain.PublishedPost exposing (PublishedPost)
import FatalError exposing (FatalError)
import History.Port exposing (HistoryIO)
import Pages.Script as Script
import Set exposing (Set)


read : BackendTask FatalError (Set PublishedPost)
read =
    -- TODO: Actually read from file
    BackendTask.succeed Set.empty


write : Set PublishedPost -> BackendTask FatalError ()
write publishedPost =
    -- TODO: Actually write to file
    publishedPost
        |> Set.toList
        |> String.join "\n"
        |> String.append "Published these posts, pretending write somewhere (but doing nothing):\n"
        |> Script.log


io : HistoryIO
io =
    { read = read
    , write = write
    }
