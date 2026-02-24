module Domain.Post exposing (Post, PublishedPost, toPublished)

import Set


type alias Post =
    { title : String
    , link : String
    , description : String
    }


type alias PublishedPost =
    String


toPublished : List { a | link : String } -> Set.Set String
toPublished posts =
    posts |> List.map .link |> Set.fromList
