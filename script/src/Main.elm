module Main exposing (run)

import History.NoHistory as NoHistory
import Input.Rss as Rss
import Output.Console as Console
import Pages.Script as Script exposing (Script)
import Pipeline
import Transform.PassThrough as PassThrough


run : Script
run =
    Script.withoutCliOptions
        (Pipeline.run
            NoHistory.noop
            Rss.fetch
            PassThrough.transform
            Console.publish
        )
