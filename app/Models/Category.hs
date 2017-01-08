{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
module Models.Category where

import qualified Database.MongoDB as Mongo
import qualified Data.ByteString.Char8 as BS
import qualified Data.Bson as Bson
import qualified Core.Model as Model
import qualified Database.MongoDB.Query as MQ
import GHC.Generics (Generic)
import Data.Bson ((!?))

data Category = Category
  { _id :: Maybe Bson.ObjectId
  , name :: BS.ByteString
  , parentId :: Maybe Bson.ObjectId
  } deriving (Show, Generic)

instance Model.Model Category

find :: Mongo.Action IO [Category]
find = do
  res <- Mongo.find(Mongo.select [] "categories") >>= MQ.rest
  return $ map fromDocument res
 where
  fromDocument doc = Category
    { _id = doc !? "_id"
    , name = Bson.at "name" doc
    , parentId = doc !? "parent_id"
    }