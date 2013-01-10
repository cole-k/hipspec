module Main where

import Prelude(undefined,Bool(..),IO,flip,($))

import HipSpec.Prelude
import HipSpec
import Definitions
import Properties

main :: IO ()
main = hipSpec "Part63.hs"
    [ vars ["x", "y", "z"] (undefined :: Nat)
    , vars ["xs", "ys", "zs"] (undefined :: [Nat])
    -- Constructors
    , "Z" `fun0` Z
    , "S" `fun1` S
    , "[]" `fun0` ([] :: [Nat])
    , ":"  `fun2` ((:) :: Nat -> [Nat] -> [Nat])
    -- Functions
    , "len" `fun1` ((len) :: [Nat] -> Nat)
    , "<" `fun2` (<)
    , "last" `fun1` ((last) :: [Nat] -> Nat)
    , "drop" `fun2` ((drop) :: Nat -> [Nat] -> [Nat])
    ]

to_show = (prop_63)