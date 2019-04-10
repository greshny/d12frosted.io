--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

--------------------------------------------------------------------------------
module Main (main) where

--------------------------------------------------------------------------------
import Config

--------------------------------------------------------------------------------
import Control.Applicative (Alternative (..))
import Control.Monad (filterM, mplus)
import Data.Maybe (fromMaybe)
import Data.Time (getCurrentTime, UTCTime, utctDay)
import Data.Time.Format (formatTime)
import Data.Time.Locale.Compat (TimeLocale, defaultTimeLocale)
import Hakyll

--------------------------------------------------------------------------------
main :: IO ()
main = getCurrentTime >>= \now -> hakyll $ do
  match "configs/config.json" $ do
    compile configCompiler

  match ("js/*" .||. "images/*" .||. "fonts/*") $ do
    route   idRoute
    compile copyFileCompiler

  match ("css/*" .||. "css/**/*") $ do
    route   idRoute
    compile compressCssCompiler

  create ["css/bundle.css"] $ do
    route idRoute
    compile $ do
      cssFiles <- loadAll "css/common/*"
      let styleCtx = listField "items" defaultContext (return cssFiles)

      makeItem []
        >>= loadAndApplyTemplate "templates/concat.txt" styleCtx

  tags <- buildTags postsPattern (fromCapture "tags/*.html")

  tagsRules tags $ \tag pat -> do
    route idRoute
    compile $ do
      posts   <- skipFuture now =<< recentFirst =<< loadAll pat
      postCtx <- loadPostCtx tags
      tagCtx  <- loadTagCtx tag postCtx posts

      makeItem ""
        >>= loadAndApplyTemplate "templates/tag.html" tagCtx
        >>= relativizeUrls

  match postsPattern $ do
    route   $ setExtension "html"
    compile $ do
      ctx <- loadPostCtx tags
      pandocCompiler
        >>= saveSnapshot "content"
        >>= loadAndApplyTemplate "templates/post.html" ctx
        >>= relativizeUrls

  create ["atom.xml"] $ do
    route idRoute
    compile $ do
      config  <- itemBody <$> load "configs/config.json"
      posts   <- fmap (take . getFeedSize $ config) . skipFuture now
        =<< recentFirst
        =<< loadAllSnapshots postsPattern "content"
      feedCtx <- bodyField "description" <+> loadPostCtx tags
      renderAtom (feedConfiguration config) feedCtx posts

  match "about.org" $ do
    route   $ setExtension "html"
    compile $ pandocCompiler

  match "index.html" $ do
    route   $ idRoute
    compile $ do
      about    <- load $ fromFilePath "about.org"
      posts    <- skipFuture now =<< recentFirst =<< loadAll postsPattern
      postCtx  <- loadPostCtx tags
      indexCtx <- loadIndexCtx postCtx posts about

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= relativizeUrls

  match "templates/*" $ compile templateBodyCompiler

--------------------------------------------------------------------------------
loadCtx :: Compiler (Context String)
loadCtx = appContext <$> itemBody <$> load "configs/config.json"

loadPostCtx :: Tags -> Compiler (Context String)
loadPostCtx tags
  =   tagsField "tags" tags
  <+> dateField "date" "%B %e, %Y"
  <+> updateField "update" "%B %e, %Y"
  <+> teaserField "teaser" "content"
  <+> defaultContext
  <+> loadCtx

loadIndexCtx :: Context String
            -> [Item String]
            -> Item String
            -> Compiler (Context String)
loadIndexCtx ctx posts about
  =   listField "posts" ctx (return posts)
  <+> field "about" (const . return . itemBody $ about)
  <+> loadCtx

loadTagCtx :: String
           -> Context String
           -> [Item String]
           -> Compiler (Context String)
loadTagCtx tag ctx posts
  =   constField "tag" tag
  <+> listField "posts" ctx (return posts)
  <+> loadCtx

--------------------------------------------------------------------------------
postsPattern :: Pattern
postsPattern = "posts/*"

--------------------------------------------------------------------------------
skipFuture :: (MonadMetadata m) => UTCTime -> [Item a] -> m [Item a]
skipFuture now = filterM $ fmap (now >) .
  getItemUTC defaultTimeLocale . itemIdentifier

--------------------------------------------------------------------------------
feedConfiguration :: Config -> FeedConfiguration
feedConfiguration config
  = FeedConfiguration
  { feedTitle       = getFeedTitle config
  , feedDescription = getFeedDescription config
  , feedAuthorName  = getAuthorName config
  , feedAuthorEmail = getAuthorEmail config
  , feedRoot        = getSiteUrl config
  }

--------------------------------------------------------------------------------
updateField :: String -> String -> Context a
updateField = updateFieldWith defaultTimeLocale

--------------------------------------------------------------------------------
updateFieldWith :: TimeLocale -> String -> String -> Context a
updateFieldWith locale key format = field key $ \i -> do
  createTime <- getItemUTC locale $ itemIdentifier i
  updateTime <- getItemModificationTime $ itemIdentifier i
  if utctDay createTime == utctDay updateTime
    then empty
    else pure $ formatTime locale format updateTime

--------------------------------------------------------------------------------
(<+>) :: (Monoid a, Applicative m) => a -> m a -> m a
a <+> ma = mappend a <$> ma
infixr 6 <+>