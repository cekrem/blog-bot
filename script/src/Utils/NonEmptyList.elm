module Utils.NonEmptyList exposing (ensureNonEmpty)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)


ensureNonEmpty : List a -> BackendTask FatalError ( a, List a )
ensureNonEmpty list =
    case list of
        first :: rest ->
            BackendTask.succeed ( first, rest )

        [] ->
            BackendTask.fail <| FatalError.fromString "no relevant posts after filtering"
