#!/usr/bin/env stack
-- stack --install-ghc runghc --package turtle --resolver lts-5.5 --verbosity silent --package=ansi-terminal

{-# LANGUAGE OverloadedStrings #-}
import           Control.Arrow       ((>>>))
import qualified Data.Text.IO        as T
import           Filesystem.Path     (addExtension, replaceExtension)
import qualified Filesystem.Path     as F
import           Prelude             hiding (FilePath)
import           System.Console.ANSI
import           Turtle

data Options = Options { web     :: Bool
                        , reveal :: Bool
                        , pdf    :: Bool
                        , beamer :: Bool
                        , file   :: Maybe FilePath
                        } deriving (Show)

parser :: Parser Options
parser = Options <$> switch "web" 'w' "generate HTML web page"
                 <*> switch "reveal" 'r' "generate HTML presentation using reveal"
                 <*> switch "pdf" 'p' "generate PDF article"
                 <*> switch "beamer" 'b' "generate PDF presentation using beamer"
                 <*> optional (argPath "file" "markdown file path")


fgrep :: Pattern a -> Shell FilePath -> Shell FilePath
fgrep pat sp = do
  fpath <- sp
  _:_ <- return (match pat (either id id (toText fpath)))
  return fpath

main :: IO ()
main = do
    opts <- options "compile files" parser
    sh $ do
      argfile <- case file opts of
        Nothing -> fgrep (invert (prefix "./.")) $ find  (has ".md") "."
        Just someFile -> return someFile
      liftIO $ do
        cd (directory argfile)
        when (web opts) (toWeb argfile)
        when (reveal opts) (toReveal argfile)
        when (pdf opts) (toPdf argfile)
        when (beamer opts) (toBeamer argfile)

toWeb :: FilePath -> IO ()
toWeb fpath = do
    let dest = replaceExtension fpath "html"
        pr :: FilePath
        pr = F.concat $ map (const "..") (splitDirectories (directory fpath))
        prt :: Text
        prt = format fp pr
    void $ shell ("pandoc -s -mathjax -t html5"
                  <> "--template " <> prt <> " "
                  <> "--section-divs"
                  <> "--variable transition=linear"
                  <> "--variable prefix=" <> prt
                  <> "-o " <> format fp dest
                  <> format fp fpath) empty

toReveal :: FilePath -> IO ()
toReveal fpath = do
  let renameToDest = filename >>> dropExtension >>> flip addExtension "reveal" >>> flip addExtension "html"
      dest = renameToDest fpath
      pr :: FilePath
      pr = F.concat $ map (const "..") (splitDirectories (directory fpath))
      template = pr </> "template-revealjs.html"
      prt :: Text
      prt = format fp pr
      cmd = "pandoc -s -mathjax -t html5 "
                <> "--template=" <> format fp template <> " "
                <> "--section-divs "
                <> "--variable transition=linear "
                <> "--variable prefix=" <> prt <> " "
                <> "-o " <> format fp dest <> " "
                <> format fp (filename fpath)
  T.putStr $ format fp dest <> " "
  answer <- shell cmd empty
  case answer of
    ExitSuccess -> greenPrn "[DONE]"
    ExitFailure _ -> redPrn "[FAILED]"

toPdf :: FilePath -> IO ()
toPdf = print

toBeamer :: FilePath -> IO ()
toBeamer = print

greenPrn :: Text -> IO ()
greenPrn txt = do
  setSGR [SetColor Foreground Dull Green]
  T.putStrLn txt
  setSGR [Reset]

redPrn :: Text -> IO ()
redPrn txt = do
  setSGR [SetColor Foreground Dull Red]
  T.putStrLn txt
  setSGR [Reset]
