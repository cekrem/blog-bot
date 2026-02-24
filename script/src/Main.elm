module Main exposing (run)

import Input.Rss as Rss
import Output.Console as Console
import Pages.Script as Script exposing (Script)
import Pipeline


run : Script
run =
    Script.withoutCliOptions
        (Pipeline.run Rss.fetch Console.publish)
