{-
 - This is a block comment
 -}

import System.Environment
import System.IO
import Text.Printf

{- |This program prints "Hello, world,"
 - and this text documents the fact
 -}

main = do
    args <- getArgs
    if length args > 0
    then putStrLn( printf "Hello %s!" $ head args )
    else putStrLn "Hello world!"
-- This is a comment
-- | But this is documentation
-- and this is documentation also.

-- But this is a comment
