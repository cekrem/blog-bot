module Main (main) where

import Data.Text qualified as T
import Data.Text.Encoding (decodeUtf8)
import Data.Text.IO qualified as T
import Domain (Post (..))
import Feed (parseFeed)
import Network.HTTP.Simple (getResponseBody, httpBS, parseRequest)
import System.Exit (exitFailure)
import System.IO (stderr)

main :: IO ()
main = do
  request <- parseRequest "https://cekrem.github.io/index.xml"
  response <- httpBS request
  case parseFeed (decodeUtf8 (getResponseBody response)) of
    Left err -> do
      T.hPutStrLn stderr ("Could not read feed: " <> showError err)
      exitFailure
    Right posts -> mapM_ (T.putStrLn . title) posts
  where
    showError = T.pack . show
