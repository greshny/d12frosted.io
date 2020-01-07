-- | Module description

--------------------------------------------------------------------------------

{-# LANGUAGE OverloadedStrings #-}

--------------------------------------------------------------------------------

module Site.Core
  ( module Hakyll
  , UTCTime
  , assetsRoute
  , ToContext(..)
  , (<+>)
  ) where

--------------------------------------------------------------------------------

import           Data.Time (UTCTime)
import           Hakyll

--------------------------------------------------------------------------------

assetsRoute :: Routes
assetsRoute = gsubRoute "assets/" (const "")

--------------------------------------------------------------------------------

class ToContext a where
  toContext :: a -> Context b

--------------------------------------------------------------------------------

(<+>) :: (Monoid a, Applicative m) => a -> m a -> m a
a <+> ma = mappend a <$> ma
infixr 6 <+>

--------------------------------------------------------------------------------
