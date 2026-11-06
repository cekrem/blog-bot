module Domain (Post (..)) where

import Data.Text (Text)

data Post = Post
  { title :: Text,
    link :: Text,
    description :: Text
  }
  deriving (Show, Eq)
