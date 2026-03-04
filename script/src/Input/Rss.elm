module Input.Rss exposing (fetch)

import BackendTask exposing (BackendTask)
import BackendTask.Http
import Domain.Post exposing (Post)
import FatalError exposing (FatalError)
import Input.Port exposing (Input)
import Utils.Http as HttpUtils
import Xml.Decode as XD


fetch : Input
fetch =
    BackendTask.Http.get "https://cekrem.github.io/index.xml"
        BackendTask.Http.expectString
        |> HttpUtils.logAndAllowFatal
        |> BackendTask.andThen parse


parse : String -> BackendTask FatalError ( Post, List Post )
parse rawXml =
    case XD.run postsDecoder rawXml of
        Err error ->
            BackendTask.fail (FatalError.fromString error)

        Ok (firstPost :: rest) ->
            BackendTask.succeed ( firstPost, rest )

        Ok [] ->
            BackendTask.fail (FatalError.fromString "No relevant posts in RSS!")


postsDecoder : XD.Decoder (List Post)
postsDecoder =
    XD.path [ "channel", "item" ] (XD.list postDecoder)


postDecoder : XD.Decoder Post
postDecoder =
    XD.map3 Post
        (XD.path [ "title" ] (XD.single XD.string))
        (XD.path [ "link" ] (XD.single XD.string))
        (XD.path [ "description" ] (XD.single XD.string))
