module Feed (FeedError (..), parseFeed) where

import Data.Bifunctor (first)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Lazy qualified as TL
import Domain (Post (..))
import Text.XML (def, parseText)
import Text.XML.Cursor (Cursor, content, element, fromDocument, ($/), ($//), (&/))

data FeedError
  = InvalidXml Text
  | NoPosts
  deriving (Show, Eq)

parseFeed :: Text -> Either FeedError [Post]
parseFeed xml = do
  document <- first (InvalidXml . T.pack . show) (parseText def (TL.fromStrict xml))
  case map parsePost (fromDocument document $// element "item") of
    [] -> Left NoPosts
    posts -> Right posts

parsePost :: Cursor -> Post
parsePost item =
  Post
    { title = field "title",
      link = field "link",
      description = field "description"
    }
  where
    field name = T.strip (T.concat (item $/ element name &/ content))
