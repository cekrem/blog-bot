module Utils.Http exposing (logAndAllowFatal)

import BackendTask
import BackendTask.Http exposing (Error(..))
import FatalError


logAndAllowFatal : BackendTask.BackendTask { a | recoverable : Error, fatal : FatalError.FatalError } data -> BackendTask.BackendTask FatalError.FatalError data
logAndAllowFatal =
    BackendTask.mapError
        (\err ->
            case err.recoverable of
                BadStatus { statusCode } body ->
                    { err | fatal = FatalError.fromString (String.fromInt statusCode ++ ": " ++ body) }

                BadBody _ body ->
                    { err | fatal = FatalError.fromString ("Http Error: " ++ body) }

                _ ->
                    err
        )
        >> BackendTask.allowFatal
