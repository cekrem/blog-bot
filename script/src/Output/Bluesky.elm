module Output.Bluesky exposing (createPost)

import BackendTask
import BackendTask.Env as Env
import BackendTask.Http as Http exposing (Body, expectJson)
import BackendTask.Time as BackendTime
import Domain.PublishedPost exposing (toPublished)
import Domain.SocialPost exposing (SocialPost)
import FatalError
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Output.Port exposing (Output)
import Utils.Http as HttpUtils


createPost : Output
createPost ( firstPost, _ ) =
    BackendTask.combine
        [ Env.expect "BLUESKY_HANDLE"
        , Env.expect "BLUESKY_PASSWORD"
        , BackendTime.now |> BackendTask.map Iso8601.fromTime
        ]
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\envs ->
                case envs of
                    [ handle, password, timestamp ] ->
                        BackendTask.succeed ( handle, password, timestamp )

                    _ ->
                        BackendTask.fail (FatalError.fromString "illegal state, internal script error")
            )
        -- Auth:
        |> BackendTask.andThen
            (\( handle, password, timestamp ) ->
                Http.post
                    "https://bsky.social/xrpc/com.atproto.server.createSession"
                    (sessionRequest ( handle, password ))
                    (expectJson (sessionDecoder timestamp))
                    |> HttpUtils.logAndAllowFatal
            )
        -- Create post:
        |> BackendTask.andThen
            (\session ->
                Http.request
                    { method = "POST"
                    , url = "https://bsky.social/xrpc/com.atproto.repo.createRecord"
                    , headers =
                        [ ( "Authorization", "Bearer " ++ session.token )
                        , ( "Content-Type", "application/json" )
                        ]
                    , body = createPostRequest session firstPost
                    , retries = Just 3
                    , timeoutInMs = Just 10000
                    }
                    Http.expectString
                    |> HttpUtils.logAndAllowFatal
            )
        |> BackendTask.map (always ([ firstPost ] |> toPublished))


sessionRequest : ( String, String ) -> Body
sessionRequest ( handle, password ) =
    Encode.object
        [ ( "identifier", Encode.string handle )
        , ( "password", Encode.string password )
        ]
        |> Http.jsonBody


type alias Session =
    { timestamp : String
    , token : String
    , did : String
    }


sessionDecoder : String -> Decoder Session
sessionDecoder timestamp =
    Decode.map2 (Session timestamp)
        (Decode.field "accessJwt" Decode.string)
        (Decode.field "did" Decode.string)


createPostRequest : Session -> SocialPost -> Body
createPostRequest session socialPost =
    Encode.object
        [ ( "repo", Encode.string session.did )
        , ( "collection", Encode.string "app.bsky.feed.post" )
        , ( "record"
          , Encode.object
                [ ( "$type", Encode.string "app.bsky.feed.post" )
                , ( "text", Encode.string socialPost.body )
                , ( "createdAt", Encode.string session.timestamp )
                , ( "facets", createFacets socialPost )
                ]
          )
        ]
        |> Http.jsonBody


createFacets : SocialPost -> Encode.Value
createFacets { body, link } =
    let
        linkLength : Int
        linkLength =
            String.length link
    in
    String.indexes link body
        |> List.map
            (\start ->
                [ ( "features"
                  , Encode.list Encode.object
                        [ [ ( "$type", Encode.string "app.bsky.richtext.facet#link" )
                          , ( "uri", Encode.string link )
                          ]
                        ]
                  )
                , ( "index"
                  , Encode.object
                        [ ( "byteStart", Encode.int start )
                        , ( "byteEnd", Encode.int (start + linkLength) )
                        ]
                  )
                ]
            )
        |> Encode.list Encode.object
