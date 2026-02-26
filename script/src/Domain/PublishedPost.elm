module Domain.PublishedPost exposing (PublishedPost, toPublished)

import Set


type alias PublishedPost =
    String


toPublished : List { a | link : String } -> Set.Set PublishedPost
toPublished posts =
    posts |> List.map .link |> Set.fromList
