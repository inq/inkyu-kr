{-# LANGUAGE OverloadedStrings, FlexibleContexts #-}
{-# LANGUAGE DeriveGeneric #-}
module Models.Article where

import qualified Data.ByteString.Char8 as BS
import qualified Data.Time.Clock as TC
import qualified Database.MongoDB as Mongo
import qualified Database.MongoDB.Query as MQ
import qualified Data.Bson as Bson
import GHC.Generics (Generic)
import Core.Model (toDocument, Model)
import Database.MongoDB ((=:))
import Data.Bson ((!?))
import Data.Int (Int32)

data Article = Article
  { _id        :: Maybe Bson.ObjectId
  , title      :: BS.ByteString
  , content    :: BS.ByteString
  , created_at :: TC.UTCTime
  }
  deriving (Show, Generic)

instance Model Article

save :: Article -> Mongo.Action IO ()
-- ^ Save the data into the DB
save (Article _id' title' content' createdAt') = do
    _ <- Mongo.insert "articles" [
        "title"      =: Bson.String title',
        "content"    =: Bson.String content',
        "created_at" =: createdAt'
      ]
    return ()

findAll :: Mongo.Action IO [Article]
-- ^ Find articles
findAll = do
    res <- Mongo.find (Mongo.select [] "articles") { Mongo.sort = ["_id" =: (-1 :: Int32)] } >>= Mongo.rest
    return $ fromDocument <$> res
  where
    fromDocument doc = Article
      { _id = doc !? "_id"
      , title = Bson.at "title" doc
      , content = Bson.at "content" doc
      , created_at = Bson.at "created_at" doc
      }

update :: Article -> Mongo.Action IO ()
update article = do
    Mongo.replace (MQ.Select ["_id" =: _id article] "articles") $ toDocument article
    return ()

find :: Bson.ObjectId -> Mongo.Action IO (Maybe Article)
-- ^ Find articles
find oid = do
    res <- Mongo.findOne (Mongo.select ["_id" =: oid] "articles")
    return $ fromDocument <$> res
  where
    fromDocument doc = Article
      { _id = doc !? "_id"
      , title = Bson.at "title" doc
      , content = Bson.at "content" doc
      , created_at = Bson.at "created_at" doc
      }
