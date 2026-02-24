module History.LogFile exposing (read)

import BackendTask
import Domain.Post exposing (PublishedPost)
import Set exposing (Set)


read : BackendTask.BackendTask error (Set PublishedPost)
read =
    BackendTask.succeed Set.empty
