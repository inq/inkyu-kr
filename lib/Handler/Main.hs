{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
module Handler.Main where

import qualified Data.ByteString.Char8          as BS
import qualified Manicure.Auth                  as Auth
import qualified Manicure.Route                 as Route
import qualified Manicure.Request               as Req
import qualified Manicure.Response              as Res
import qualified Manicure.Database              as DB
import qualified Manicure.Session               as Session
import qualified Database.MongoDB               as Mongo
import qualified Manicure.ByteString            as ByteString
import qualified Data.Text                      as T
import qualified Manicure.Html                  as Html
import qualified Models.Article                 as Article
import qualified Data.Time.Clock                as C
import qualified Data.Bson                      as Bson
import qualified Network.Curl                   as Curl
import qualified Data.Map                       as M
import qualified Models.User                    as User
import qualified Models.Article                 as Article
import Control.Monad
import Data.Map ((!))

article :: Res.Handler
-- ^ Test parsing URI parameters
article [category, article, index] db req = do
    return $ Res.success $(Html.parseFile "Views/article.html.qh") []

signin :: Res.Handler
-- ^ Sign in page
signin [] db req = response
  where
    redirect_uri = "https://whitesky.net/signin"
    response = case M.lookup "code" $ Req.query_str req of
        Just code -> do 
            query_str <- liftM snd $ Curl.curlGetString (BS.unpack $ Auth.access_token_url redirect_uri code) []
            let access_token = ((ByteString.split_and_decode '&' . BS.pack) query_str) ! "access_token"
            query_str <- liftM snd $ Curl.curlGetString (BS.unpack $ Auth.facebook_me_url access_token) []
            let query = show $ User.from_json $ BS.pack query_str
            let user = User.from_json (BS.pack query_str)
            DB.query db (User.upsert user)
            session_key <- Session.generateKey
            DB.run_redis db $ User.redis_hash session_key user
            return $ Res.success $(Html.parseFile "Views/test.html.qh") [BS.concat ["SESSION_KEY=", session_key]]
        Nothing   -> do
            return $ Res.redirect $ Auth.oauth_url redirect_uri

new_article :: Res.Handler
-- ^ Create a new article from the given POST data
new_article [] db req = do
    time <- C.getCurrentTime
    DB.query db (Article.save $ Article.Article Nothing title content time)
    return $ Res.success $(Html.parseFile "Views/new_article.html.qh") ["HELLO=WORLD"]
  where
    title   = post ! "title"
    content = post ! "content"
    post    = Req.post req

index :: Res.Handler
-- ^ Render the main page
index [] db req = do
    putStrLn $ show $ req
    temp <- DB.query db Article.find
    articles <- (mapM read) temp
    putStrLn $ show temp
    user <- userM
    let name = case user of
          Just (User.User _ _ _ name _) -> name
          Nothing -> "anonymous"
    return $ Res.success $(Html.parseFile "Views/index.html.qh") []
  where
    read :: Bson.Document -> IO [BS.ByteString]
    read document = do
        title   <- Mongo.lookup "title" document
        content <- Mongo.lookup "content" document          
        return [extract title, extract content]
      where
        extract (Bson.Binary a) = a
    userM = case M.lookup "SESSION_KEY" (Req.extract_cookie req) of
        Just key -> DB.run_redis db $ User.redis_get key
        Nothing  -> return Nothing
