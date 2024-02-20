-- |

module MTP where

import Prelude hiding (max,product,maximum,(*),map,fst,snd)

import HipSpec

import Nat
import List

fst :: (a, b) -> a
fst (a, b) = a

snd :: (a, b) -> b
snd (a, b) = b

-- max Z     y     = y
-- max x     Z     = x
-- max (S x) (S y) = S (max x y)
--
-- maximum :: [Nat] -> Nat
-- maximum [] = Z
-- maximum (x:xs) = max x (maximum xs)
--
-- product :: [Nat] -> Nat
-- product [] = S Z
-- product (x:xs) = x * product xs
--
-- tails :: [a] -> [[a]]
-- tails [] = [[]]
-- tails (x:xs) = (x:xs) : tails xs

mtp :: [Nat] -> (Nat, Nat)
mtp [] = (S Z, S Z)
mtp (x:xs) = -- let (prevMax, prevProd) = mtp xs
             --     currProd = x * prevProd in
  (max (fst (mtp xs)) (x * snd (mtp xs)), x * snd (mtp xs))

prop_mtp :: [Nat] -> Prop Nat
prop_mtp xs = maximum (map product (tails xs)) =:= fst (mtp xs)
