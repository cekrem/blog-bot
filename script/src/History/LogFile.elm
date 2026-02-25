module History.LogFile exposing (io)

import BackendTask exposing (BackendTask)
import BackendTask.File
import BackendTask.Stream as Stream
import BackendTask.Time
import Domain.PublishedPost exposing (PublishedPost)
import FatalError exposing (FatalError)
import History.Port exposing (HistoryIO)
import Set exposing (Set)
import Time


read : BackendTask FatalError (Set PublishedPost)
read =
    BackendTask.File.rawFile logPath
        |> BackendTask.onError (\_ -> BackendTask.succeed "")
        |> BackendTask.map (String.split "\n" >> Set.fromList)


write : Set PublishedPost -> BackendTask FatalError ()
write publishedPosts =
    BackendTask.Time.now
        |> BackendTask.map (String.fromInt << Time.posixToMillis)
        |> BackendTask.map
            (\timestamp ->
                publishedPosts
                    |> Set.toList
                    |> String.join "\n"
                    |> String.append ("# " ++ timestamp ++ "\n")
            )
        |> BackendTask.map (Stream.fromString >> Stream.pipe (Stream.command "tee" [ "-a", logPath ]))
        |> BackendTask.andThen Stream.run


io : HistoryIO
io =
    { read = read
    , write = write
    }


logPath : String
logPath =
    "log.txt"
