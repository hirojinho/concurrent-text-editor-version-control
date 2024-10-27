{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

import Web.Scotty
import Data.Text.Lazy (Text)
import Control.Concurrent.STM
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import qualified Data.Text as T
import Data.Aeson (ToJSON, FromJSON, decode, encode)
import Data.Text.Lazy.Encoding (decodeUtf8)
import Control.Monad.IO.Class (liftIO)
import Data.Time.Clock (getCurrentTime)
import GHC.Generics (Generic)
import Network.HTTP.Types.Status (status400, status404)

type DocumentId = Int
type Version = Int

data Document = Document {
    content :: Text,
    timestamp :: String
} deriving (Show, Generic)

instance ToJSON Document
instance FromJSON Document

type DocumentStore = TVar (Map DocumentId (Map Version Document))

addDocumentVersion :: DocumentId -> Document -> DocumentStore -> IO()
addDocumentVersion docId doc store = atomically $ do
    docs <- readTVar store
    let newVersion = maybe 1 (succ . fst . Map.findMax) (Map.lookup docId docs)
    let updatedVersion = Map.insert newVersion doc (Map.findWithDefault Map.empty docId docs)
    writeTVar store (Map.insert docId updatedVersion docs)

getDocumentVersions :: DocumentId -> DocumentStore -> IO (Maybe (Map Version Document))
getDocumentVersions docId store = atomically $ Map.lookup docId <$> readTVar store

main :: IO ()
main = do
    documentStore <- newTVarIO Map.empty -- Initialize the empty document store
    scotty 3002 $ do -- Start the web server on port 3002
        -- Upload a document
        post (literal "/documents/:id") $ do
            docId <- param "id" -- Extract document ID from the URL
            body <- body -- Extract request body (JSON)

            case decode body :: Maybe Document of
                Just doc -> do
                    liftIO $ addDocumentVersion docId doc documentStore -- Save socument
                    json $ Map.singleton ("message" :: Text) ("Document version saved!" :: Text)
                Nothing -> do
                    status status400 -- If JSON decoding fails
                    json $ Map.singleton ("error" :: Text) ("Invalid document format" :: Text)
        
        -- Get all versions of a document
        get (literal "/documents/:id/versions") $ do
            docId <- param "id" -- Extract document ID from the URL
            docs <- liftIO $ getDocumentVersions docId documentStore -- Fetch document versions
            case docs of
                Just versions -> json versions
                Nothing -> do
                    status status404 -- If document id is not found
                    json $ Map.singleton ("error" :: Text) ("Document not found" :: Text)
