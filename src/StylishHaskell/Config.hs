--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
module StylishHaskell.Config
    ( Config (..)
    , configFilePath
    , loadConfig
    ) where


--------------------------------------------------------------------------------
import           Control.Applicative            ((<$>))
import           Control.Monad                  (msum, mzero)
import           Data.Aeson                     (FromJSON(..))
import qualified Data.Aeson                     as A
import qualified Data.Aeson.Types               as A
import           Data.Maybe                     (fromMaybe)
import           Data.Yaml                      (decodeFile)
import           System.Directory
import           System.FilePath                ((</>))


--------------------------------------------------------------------------------
import           StylishHaskell.Stylish
import           StylishHaskell.Stylish.Catalog


--------------------------------------------------------------------------------
data Config = Config
    { configStylish :: [Stylish]
    }


--------------------------------------------------------------------------------
instance FromJSON Config where
    parseJSON (A.Object o) = Config <$> (parseEnabled =<< o A..: "enabled")
    parseJSON _            = mzero


--------------------------------------------------------------------------------
defaultConfig :: Config
defaultConfig = Config $
    fromCatalog ["Imports", "LanguagePragmas", "TrailingWhitespace"]


--------------------------------------------------------------------------------
parseEnabled :: A.Value -> A.Parser [Stylish]
parseEnabled = fmap fromCatalog . parseJSON


--------------------------------------------------------------------------------
configFileName :: String
configFileName = ".stylish-haskell.yaml"


--------------------------------------------------------------------------------
configFilePath :: Maybe FilePath -> IO (Maybe FilePath)
configFilePath userSpecified = do
    current  <- (</> configFileName) <$> getCurrentDirectory
    currentE <- doesFileExist current
    home     <- (</> configFileName) <$> getHomeDirectory
    homeE    <- doesFileExist home
    return $ msum
        [ userSpecified
        , if currentE then Just current else Nothing
        , if homeE then Just home else Nothing
        ]


--------------------------------------------------------------------------------
loadConfig :: Maybe FilePath -> IO Config
loadConfig mfp = do
    mfp' <- configFilePath mfp
    mc   <- maybe (return Nothing) decodeFile mfp'
    return $ fromMaybe defaultConfig mc