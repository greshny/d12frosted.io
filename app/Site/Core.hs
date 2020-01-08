--------------------------------------------------------------------------------

module Site.Core
  ( module Hakyll
  , UTCTime
  , ToContext(..)
  , (<+>)
  ) where

--------------------------------------------------------------------------------

import           Data.Time (UTCTime)
import           Hakyll

--------------------------------------------------------------------------------

class ToContext a where
  toContext :: a -> Context b

--------------------------------------------------------------------------------

(<+>) :: (Monoid a, Applicative m) => a -> m a -> m a
a <+> ma = mappend a <$> ma
infixr 6 <+>

--------------------------------------------------------------------------------
