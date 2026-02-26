module Pipeline exposing (run)

import BackendTask exposing (BackendTask)
import Domain.Post exposing (Post)
import Domain.PublishedPost exposing (PublishedPost)
import FatalError exposing (FatalError)
import History.Port exposing (HistoryIO)
import Input.Port exposing (Input)
import Output.Port exposing (Output)
import Set exposing (Set)
import Transform.Port exposing (Transform)
import Utils.NonEmptyList exposing (ensureNonEmpty)


run : HistoryIO -> Input -> Transform -> Output -> BackendTask FatalError ()
run historyIO input transform output =
    BackendTask.map2 filterPublished historyIO.read input
        |> BackendTask.andThen ensureNonEmpty
        |> BackendTask.andThen transform
        |> BackendTask.andThen output
        |> BackendTask.andThen historyIO.write


filterPublished : Set PublishedPost -> ( Post, List Post ) -> List Post
filterPublished previouslyPublished ( firstPost, rest ) =
    (firstPost :: rest)
        |> List.filter (\{ link } -> not (previouslyPublished |> Set.member link))
