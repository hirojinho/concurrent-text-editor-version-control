module App
    (
        runApp
    ) where

import Types
import Repository
import API
import Web.Scotty
import Control.Monad.IO.Class (liftIO)

runApp :: IO ()
runApp = do
    store <- initializeStore
    scotty 3002 $ documentAPI store
