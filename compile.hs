#!/usr/bin/env stack
-- stack --install-ghc runghc --package turtle --resolver lts-5.5 --verbosity s

{-# LANGUAGE OverloadedStrings #-}
import qualified Control.Foldl       as Fold
import qualified Data.Text.IO        as T
import           Filesystem.Path     (addExtension, replaceExtension)
import qualified Filesystem.Path     as F
import           Prelude             hiding (FilePath)
import           System.Console.ANSI
import           Turtle
import Data.Maybe (isJust,fromJust)
import qualified System.IO as System

-- Command Line Options
data Options =
  Options { web    :: Bool
          , reveal :: Bool
          , pdf    :: Bool
          , beamer :: Bool
          , debug  :: Bool
          , file   :: Maybe FilePath
          } deriving (Show)

parser :: Parser Options
parser = Options <$> switch "web" 'w' "generate HTML web page"
                 <*> switch "reveal" 'r' "generate HTML presentation using reveal"
                 <*> switch "pdf" 'p' "generate PDF article"
                 <*> switch "beamer" 'b' "generate PDF presentation using beamer"
                 <*> switch "debug" 'd' "debug mode (show commands)"
                 <*> optional (argPath "file" "markdown file path")

initOptions :: IO Options
initOptions = do
    rawopts <- options "compile files" parser
    return $ if web rawopts || reveal rawopts || pdf rawopts || beamer rawopts
                then rawopts
                else rawopts { web = True
                             , reveal = True
                             , pdf = True
                             , beamer = True }

main :: IO ()
main = do
    opts <- initOptions
    maindir <- pwd
    sh $ do
      argfile <- case file opts of
        Nothing -> findMarkdownFiles
        Just someFile -> return someFile
      liftIO $ do
        yellowPrn ("-- " <> format fp argfile <> " --")
        cd (directory argfile)
        when (web opts) (toWeb (debug opts) argfile)
        when (reveal opts) (toReveal (debug opts) argfile)
        when (pdf opts) (toPdf (debug opts) argfile)
        when (beamer opts) (toBeamer (debug opts) argfile)
        cd maindir

-- | Find Markdown Files (skip hidden directories)
findMarkdownFiles :: Shell FilePath
findMarkdownFiles = do
    fic <- find  (choice [(suffix ".md"), (suffix ".org")]) "." & fgrep (invert (prefix "./."))
    let mf = stripPrefix "./" fic
    _ <- guard (isJust mf)
    return (fromJust mf)

pr :: Text -> IO ()
pr txt = do
    T.putStr txt
    System.hFlush System.stdout

-- | basic exec command with debug option and colors DONE or FAILED status
execcmd :: Bool -> FilePath -> Text -> IO ()
execcmd dbg dest cmd = do
    when dbg (T.putStrLn cmd)
    pr (format fp dest <> " ")
    answer <- shell cmd empty
    case answer of
      ExitSuccess -> greenPrn "[DONE]"
      ExitFailure _ -> redPrn "[FAILED]"

toprefix :: FilePath -> FilePath
toprefix fpath = F.concat $ map (const "..") (filter (/= "./") (splitDirectories (directory fpath)))

-- | Generate HTML format
toWeb :: Bool -> FilePath -> IO ()
toWeb dbg fpath = do
  let dest = filename (replaceExtension fpath "html")
      prf = toprefix fpath
      cmd = "pandoc -s -S --toc -mathjax -t html5 --smart "
            <> "--css " <> format fp (prf </> "styling.css") <> " "
            <> "-A " <> format fp (prf </> "footer.html") <> " "
            <> "-o " <> format fp dest <> " "
            <> format fp (filename fpath)
  execcmd dbg dest cmd

-- | Generate HTML Reveal.js Presentation
toReveal :: Bool -> FilePath -> IO ()
toReveal dbg fpath = do
  mslideLevel <- fold (fpath & filename
                             & input
                             & grep (prefix "slide_level: ")
                             & sed (prefix ("slide_level: " *> plus digit)))
                     Fold.head
  let slideLevel = maybe "2" (\l -> if l == "" then "2" else l) mslideLevel
      dest = fpath & filename
                   & dropExtension
                   & flip addExtension "reveal"
                   & flip addExtension "html"
      prf = toprefix fpath
      template = prf </> "template-revealjs.html"
      prt :: Text
      prt = format fp prf
      cmd = "pandoc -s -mathjax -t html5 "
                <> "--template=" <> format fp template <> " "
                <> "--section-divs "
                <> "--slide-level=" <> slideLevel <> " "
                <> "--variable transition=linear "
                <> "--variable prefix=" <> prt <> " "
                <> "-o " <> format fp dest <> " "
                <> format fp (filename fpath)
  execcmd dbg dest cmd

-- | Generate PDF Document using XeLaTeX
toPdf :: Bool -> FilePath -> IO ()
toPdf dbg fpath = do
  let dest = fpath & filename
                   & dropExtension
                   & flip addExtension "pdf"
      prf = toprefix fpath
      template = prf </> "template.latex"
      cmd = "pandoc -s -S -N --toc "
                <> "--template=" <> format fp template <> " "
                <> "--section-divs "
                <> "--variable fontsize=14pt "
                <> "--variable linkcolor=orange "
                <> "--variable urlcolor=orange "
                <> "--latex-engine=xelatex "
                <> "-o " <> format fp dest <> " "
                <> format fp (filename fpath)
  execcmd dbg dest cmd

-- | Generate Beamer Presentation PDF
toBeamer :: Bool -> FilePath -> IO ()
toBeamer dbg fpath = do
  mslideLevel <- fold (fpath & filename
                             & input
                             & grep (prefix "slide_level: ")
                             & sed (prefix "slide_level: " *> star digit))
                     Fold.head
  let slideLevel = maybe "2" (\l -> if l == "" then "2" else l) mslideLevel
      dest = fpath & filename
                   & dropExtension
                   & flip addExtension "beamer"
                   & flip addExtension "pdf"
      cmd :: Text
      cmd = "pandoc -s -S -N "
            <> "-t beamer "
            <> "--slide-level=" <> slideLevel <> " "
            <> "--variable fontsize=14pt "
            <> "--variable linkcolor=orange "
            <> "--variable urlcolor=orange "
            <> "--latex-engine=xelatex "
            <> "-o " <> format fp dest <> " "
            <> format fp (filename fpath)
  execcmd dbg dest cmd


-- # Colors Helpers (should be a sub lib)
-- import           System.Console.ANSI

prnColor :: Color -> Text -> IO ()
prnColor c txt =  do
  setSGR [SetColor Foreground Dull c]
  T.putStrLn txt
  setSGR [Reset]

greenPrn :: Text -> IO ()
greenPrn = prnColor Green

redPrn :: Text -> IO ()
redPrn = prnColor Red

yellowPrn :: Text -> IO ()
yellowPrn = prnColor Yellow

-- # Grep Files helper


-- onFiles :: (Shell Text -> Shell Text) -> Shell FilePath -> Shell FilePath
-- onFiles txtAction sp = do
--   fpath <- sp
--   _ <- txtAction (either id id (toText fpath))
--   return fpath

-- Bonus Discussion
--
-- on :: (a -> [b]) -> Shell a -> Shell b
-- on trans sa = do
--   anA <- sa
--   select (trans anA)
--
-- toDup :: Shell FilePath -> Shell (Text,FilePath)
-- toDup sf = do
--   fpath <- sf
--   let txtpath = either id id (toText fpath)
--   return (txtpath,fpath)
--
-- fpgrep :: Pattern a -> Shell FilePath -> Shell FilePath
-- fpgrep pat =
--   on (\fpath -> match pat (either id id (toText fpath)) >> return fpath)

onFiles :: (Text -> FilePath -> [b]) -> Shell FilePath -> Shell b
onFiles trans sa = do
  anA <- sa
  let bs = trans (either id id (toText anA)) anA
  select bs

-- | Same as grep put to be used after find or ls
fgrep :: Pattern a -> Shell FilePath -> Shell FilePath
fgrep pat = onFiles $ \ tpath fpath -> do
  _ <- match pat tpath
  return fpath
