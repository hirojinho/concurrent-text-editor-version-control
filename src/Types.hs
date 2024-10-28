{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Types
    ( DocumentId,
      Version,
      Document(..),
      DocumentStore
    ) where

import Data.Text.Lazy (Text)
import Data.Time.Clock (UTCTime)
import GHC.Generics (Generic)
import Data.Aeson (ToJSON, FromJSON)
import Control.Concurrent.STM (TVar)
import Data.Map.Strict as Map

type DocumentId = Int
type Version = Int

data Document = Document {
    content :: Text,
    timestamp :: UTCTime
} deriving (Show, Generic)

instance ToJSON Document
instance FromJSON Document

type DocumentStore = TVar (Map DocumentId (Map Version Document))