--------------------------------------------------------------------------------
module ToContext where

--------------------------------------------------------------------------------
import           Hakyll

--------------------------------------------------------------------------------
class ToContext a where
  toContext :: a -> Context b