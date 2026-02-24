module Pipeline exposing (run)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Input.Port exposing (Input)
import Output.Port exposing (Output)


run : Input -> Output -> BackendTask FatalError ()
run input output =
    input
        |> BackendTask.andThen output
