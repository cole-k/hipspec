{-# LANGUAGE TemplateHaskell #-}
{-

   Compile with -fforce-recomp -fexpose-all-unfoldings -fno-ignore-interface-pragmas -fno-omit-interface-pragmas

-}
module Main where

import HipSpec.Prelude
import HipSpec
import Prelude(Bool(..), IO, undefined)
import Properties
import Definitions


main :: IO ()
main = hipSpec $(fileName)
    [ vars ["xs", "ys", "zs"] (undefined :: [A])
    , vars ["x", "y", "z"] (undefined :: A)
    -- Constructors
    , "[]"     `fun0` ([] :: [A])
    , ":"      `fun2` ((:) :: A -> [A] -> [A])
    -- Functions
    , "++"     `fun2`  ((++) :: [A] -> [A] -> [A]) -- rev calls (++)
    , "rev"    `fun1`  (rev  :: [A] -> [A])
    ]

-- The properties needs to be mentioned here to be included
to_show = (prop_T10, prop_T11, prop_T17, prop_T18, prop_T19, prop_T30)

