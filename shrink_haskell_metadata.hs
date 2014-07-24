import qualified Data.ByteString.Char8 as B8
import qualified System.Environment as E

-- how hackport always defined it
from, to :: B8.ByteString
(from, to) = ( B8.pack $ unlines [ "\t<herd>haskell</herd>"
                                 , "\t<maintainer>"
                                 , "\t\t<email>haskell@gentoo.org</email>"
                                 , "\t</maintainer>"
                                 ]
             , B8.pack $ unlines [ "\t<herd>haskell</herd>"
                                 ]
             )

fix_maint :: FilePath -> IO ()
fix_maint mxml = do
    orig <- B8.readFile mxml
    case B8.findSubstring from orig of
        Nothing -> return ()
        Just ix -> do let new = B8.concat [ B8.take ix orig
                                          , to
                                          , B8.drop (ix + B8.length from) orig
                                          ]
                      putStrLn $ unwords [ "Updating", mxml ]
                      B8.writeFile mxml new

main :: IO ()
main = E.getArgs >>= mapM_ fix_maint
