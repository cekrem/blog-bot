module Transform.GroqLLM exposing (ChatMessage, run)

import BackendTask
import BackendTask.Env as Env
import BackendTask.Http as Http
import Domain.Post exposing (Post)
import Domain.SocialPost exposing (SocialPost)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Transform.Port exposing (Transform)
import Utils.Http as HttpUtils


run : Transform
run ( firstPost, _ ) =
    let
        body : Http.Body
        body =
            firstPost
                |> formatLLMMessage
                |> encodeBody
    in
    Env.expect "GROQ_API_KEY"
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\key ->
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
                    |> HttpUtils.logAndAllowFatal
            )
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

The final post should be pure ASCII, with a length under 300 characters (including the URL),
this is a hard limit!

Important note: Your answer should be _only_ the social media post content, no introduction before or
conclusion after. And no surrounding quotes(!); just the exact thing to post on social media.

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
                (Decode.field "content" contentDecoder)
            )
        )


contentDecoder : Decoder String
contentDecoder =
    Decode.string
        |> Decode.map (String.replace "\"" "")



-- REQUEST BODY


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
