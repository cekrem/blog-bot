module Transform.GroqLLM exposing (..)

import BackendTask
import BackendTask.Http as Http
import Domain.Post exposing (Post)
import Domain.SocialPost exposing (SocialPost)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Transform.Port exposing (Transform)


key : String
key =
    "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"


run : Transform
run ( firstPost, _ ) =
    let
        body =
            firstPost
                |> formatLLMMessage
                |> encodeBody
    in
    Http.request
        { method = "POST"
        , url = "https://api.groq.com/openai/v1/chat/completions"
        , headers =
            [ ( "Authorization", "Bearer " ++ key )
            , ( "Content-Type", "application/json" )
            ]
        , body = body
        , retries = Just 3
        , timeoutInMs = Just 10000
        }
        (Http.expectJson responseDecoder)
        |> BackendTask.allowFatal
        |> BackendTask.map
            (\llmRes ->
                ( SocialPost llmRes firstPost.link, [] )
            )



-- LLM MESSAGE TEMPLATE


formatLLMMessage : Post -> String
formatLLMMessage post =
    """
You are my social media assistant. Friendlyness and politeness are among your
core values, and you will never (ever!) output anything offensive or rude at any point.

At the end of this message I will send you my most recent post and its URL,
and you will compose a Twitter/X friendly promotional message I will post. 

Add the URL where you see fit within the message.

Try to refrain from typical AI-jargon, and keep a casual (and slightly nerdy) tone.

Important: Your answer should be _only_ the social media post content, no introduction before or
conclusion after. And no surrounding quotes, please, just the exact thing to post on social media.

Post follows here:

  """
        ++ "Post title: "
        ++ post.title
        ++ "\n"
        ++ "Post description: "
        ++ post.description
        ++ "\n"
        ++ "Post url: "
        ++ post.link
        ++ "\n"



-- RESPONSE BODY


responseDecoder : Decoder String
responseDecoder =
    Decode.field "choices"
        (Decode.oneOrMore (\first _ -> first)
            (Decode.field "message"
                (Decode.field "content" Decode.string)
            )
        )



-- REQUEST BODY


type alias RequestBody =
    { messages : List ChatMessage
    , model : String
    }


type alias ChatMessage =
    { content : String
    , role : String
    }


encodeBody : String -> Http.Body
encodeBody message =
    Encode.object
        [ ( "messages"
          , Encode.list encodeChatMessage
                ({ content = message, role = "user" }
                    |> List.singleton
                )
          )
        , ( "model", Encode.string "llama-3.3-70b-versatile" )
        ]
        |> Http.jsonBody


encodeChatMessage : ChatMessage -> Encode.Value
encodeChatMessage rootMessagesObject =
    Encode.object
        [ ( "content", Encode.string rootMessagesObject.content )
        , ( "role", Encode.string rootMessagesObject.role )
        ]
