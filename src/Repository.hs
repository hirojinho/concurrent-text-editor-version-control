{-# LANGUAGE OverloadedStrings #-}

module Repository where

import Types
import Control.Concurrent.STM
import Data.Map.Strict as Map
import Control.Monad.IO.Class (MonadIO, liftIO)

initializeStore :: IO DocumentStore
initializeStore = newTVarIO Map.empty

addDocumentVersion :: MonadIO m => DocumentId -> Document -> DocumentStore -> m ()
addDocumentVersion docId doc store = liftIO . atomically $ do
    docs <- readTVar store
    let newVersion = maybe 1 (succ . fst . Map.findMax) (Map.lookup docId docs)
    let updatedVersion = Map.insert newVersion doc (Map.findWithDefault Map.empty docId docs)
    writeTVar store (Map.insert docId updatedVersion docs)

getDocumentVersions :: MonadIO m => DocumentId -> DocumentStore -> m (Maybe (Map Version Document))
getDocumentVersions docId store = liftIO . atomically $
    Map.lookup docId <$> readTVar store