{-# LANGUAGE OverloadedStrings #-}

module API
    (
        documentAPI
    ) where

import Types
import Repository
import Web.Scotty
import Data.Text.Lazy (Text)
import qualified Data.Map.Strict as Map
import Data.Aeson (decode)
import Network.HTTP.Types.Status (status400, status404)
import Control.Monad.IO.Class (liftIO)

documentAPI :: DocumentStore -> ScottyM ()
documentAPI store = do
    -- Upload a document
    post "/documents/:id" $ do
        docId <- param "id"
        body <- body
        case decode body :: Maybe Document of
            Just doc -> do
                addDocumentVersion docId doc store
                json $ Map.singleton ("message" :: Text) ("Document version saved!" :: Text)
            Nothing -> do
                status status400
                json $ Map.singleton ("message" :: Text) ("Invalid document format" :: Text)
    
    -- Get all versions of a document
    get "/documents/:id" $ do
        docId <- param "id"
        docs <- getDocumentVersions docId store
        case docs of
            Just versions -> json versions
            Nothing -> do
                status status404
                json $ Map.singleton ("message" :: Text) ("Document not found" :: Text)
