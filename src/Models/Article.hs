{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleContexts #-}
module Models.Article where

import qualified Data.ByteString.Char8          as BS
import qualified Data.Time.Clock                as TC
import qualified Database.MongoDB               as M
import qualified Data.Bson                      as Bson
import Control.Monad.Trans (MonadIO, liftIO)
import Control.Monad.Trans.Control (MonadBaseControl)
import Database.MongoDB ((=:))

data Article = Article {
  id        :: Maybe Bson.ObjectId,
  title     :: BS.ByteString,
  content   :: BS.ByteString,
  createdAt :: TC.UTCTime
}

save :: Article -> M.Action IO ()
-- ^ Save the data into the DB
save (Article id title content createdAt) = do
    M.insert "articles" [
        "title"      =: Bson.Binary title,
        "content"    =: Bson.Binary content,
        "created_at" =: createdAt
      ]
    return ()

find :: (MonadIO m, MonadBaseControl IO m)  => M.Action m [M.Document]
-- ^ ** Find articles
find = do
    (M.find $ M.select [] "articles") >>= M.rest
