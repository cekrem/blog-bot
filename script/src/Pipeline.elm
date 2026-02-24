module Pipeline exposing (run)

import BackendTask exposing (BackendTask)
import Domain.Post exposing (Post, PublishedPost)
import FatalError exposing (FatalError)
import History.Port exposing (HistoryIO)
import Input.Port exposing (Input)
import Output.Port exposing (Output)
import Set exposing (Set)


run : HistoryIO -> Input -> Output -> BackendTask FatalError ()
run historyIO input output =
    BackendTask.map2 filterPublished historyIO.read input
        |> BackendTask.andThen output
        |> BackendTask.andThen historyIO.write


filterPublished : Set PublishedPost -> List Post -> List Post
filterPublished previouslyPublished posts =
    posts
        |> List.filter (\{ link } -> not (previouslyPublished |> Set.member link))
