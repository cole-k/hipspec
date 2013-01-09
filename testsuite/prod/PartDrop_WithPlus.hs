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
    [ vars ["m", "n", "o"] (undefined :: Nat)
    , vars ["x", "y", "z"] (undefined :: A)
    , vars ["xs", "ys", "zs"] (undefined :: [A])
    -- Constructors
    , "[]"     `fun0` ([] :: [A])
    , ":"      `fun2` ((:) :: A -> [A] -> [A])
    , "Z"      `fun0` Z
    , "S"      `fun1` S
    -- Functions
    , "drop"   `fun2`  (drop   :: Nat -> [A] -> [A])
    , "+"      `fun2`  (+)
    ]

-- The properties needs to be mentioned here to be included
to_show =
    ( prop_T08
    , prop_T09
    )


