{-# LANGUAGE DeriveDataTypeable #-}
module List where

import Prelude hiding (reverse,(++),length,map,filter,(.),(+),(*),const,maximum,product,tails,max)
import qualified Prelude
import HipSpec
import Nat

length :: [a] -> Nat
length []     = Z
length (_:xs) = S (length xs)

(++) :: [a] -> [a] -> [a]
(x:xs) ++ ys = x:(xs ++ ys)
[]     ++ ys = ys

map :: (a -> b) -> [a] -> [b]
map f (x:xs) = f x:map f xs
map f []     = []

filter :: (a -> Bool) -> [a] -> [a]
filter p (x:xs) | p x       = x:filter p xs
                | otherwise = filter p xs
filter p [] = []

maximum :: [Nat] -> Nat
maximum [] = Z
maximum (x:xs) = max x (maximum xs)

product :: [Nat] -> Nat
product [] = S Z
product (x:xs) = x * product xs

tails :: [a] -> [[a]]
tails [] = [[]]
tails (x:xs) = (x:xs) : tails xs

f . g = \ x -> f (g x)

sig = [ vars ["m","n","o"]    (undefined :: Nat)
      , vars ["x","y","z"]    (undefined :: A)
      , vars ["xs","ys","zs"] (undefined :: [A])
      , vars ["f","g"]        (undefined :: A -> A)
      , vars ["p","q"]        (undefined :: A -> Bool)
      , fun0 "Z"      Z
      , fun1 "S"      S
      , fun2 "+"      (+)
      , fun0 "[]"     ([] :: [A])
      , fun2 ":"      ((:) :: A -> [A] -> [A])
      , fun2 "++"     ((++) :: [A] -> [A] -> [A])
      , fun2 "map"    (map    :: (A -> A) -> [A] -> [A])
      , fun1 "length" (length :: [A] -> Nat)
      , fun2 "filter" (filter :: (A -> Bool) -> [A] -> [A])
      , fun1 "maximum" (maximum :: [Nat] -> Nat)
      , fun1 "product" (product :: [Nat] -> Nat)
      , fun1 "tails"   (tails :: [A] -> [[A]])
      , blind2 "."    ((.) :: (A -> A) -> (A -> A) -> (A -> A))
      ]

