{-# LANGUAGE FlexibleInstances, ScopedTypeVariables, TypeFamilies, DeriveDataTypeable #-}

module Main where

import Prelude (Bool(..),error,toEnum,fromEnum,pred,succ,sqrt,round
               ,Enum,Eq,Ord,Show,return,(.),undefined)
import Hip.HipSpec
import Test.QuickCheck hiding (Prop)
import Data.Typeable

main = hipSpec "Elem.hs" conf 3
  where conf = describe "Nats"
               [ var "x"         natType
               , var "y"         natType
               , var "z"         natType
               , var "xs"        listType
               , var "ys"        listType
               , var "zs"        listType
               , con "[]"        ([]       :: [Nat])
               , con ":"         ((:)      :: Nat  -> [Nat] -> [Nat])
               , con "++"        ((++)     :: [Nat] -> [Nat] -> [Nat])
               , con "elem"      (elem  :: Nat -> [Nat] -> Bool)
               , con "=="        (==)
               ]
           where
             natType  = (error "Nat type" :: Nat)
             listType = (error "List type" :: [Nat])
instance Enum Nat where
  toEnum 0 = Z
  toEnum n = S (toEnum (pred n))
  fromEnum Z = 0
  fromEnum (S n) = succ (fromEnum n)

instance Arbitrary Nat where
  arbitrary = sized (\s -> do
    x <- choose (0,round (sqrt (toEnum s)))
    return (toEnum x))

instance CoArbitrary Nat where
  coarbitrary Z     = variant 0
  coarbitrary (S x) = variant (-1) . coarbitrary x

instance Classify Nat where
  type Value Nat = Nat
  evaluate = return

type Prop a = a

infix 0 =:=

(=:=) :: a -> a -> Prop a
(=:=) = (=:=)

proveBool :: Bool -> Prop Bool
proveBool = (=:= True)

data Nat = Z | S Nat deriving (Eq,Ord,Show,Typeable)

-- Boolean functions

(&&) :: Bool -> Bool -> Bool
True && True = True
_    && _    = False

-- Natural numbers

Z     == Z     = True
(S x) == (S y) = x == y
_     == _     = False

Z     <= _     = True
(S x) <= (S y) = x <= y
_     <= _     = False

_     < Z     = False
(S x) < (S y) = x < y
_     < _     = True

Z     + y = y
(S x) + y = S (x + y)

Z     - _     = Z
x     - Z     = x
(S x) - (S y) = x - y

-- List functions

(++) :: [a] -> [a] -> [a]
[]     ++ ys = ys
(x:xs) ++ ys = x : (xs ++ ys)

rev :: [a] -> [a]
rev [] = []
rev (x:xs) = rev xs ++ [x]

delete :: Nat -> [Nat] -> [Nat]
delete _ [] = []
delete n (x:xs) =
  case n == x of
    True -> delete n xs
    _    -> x : (delete n xs)

len :: [a] -> Nat
len [] = Z
len (_:xs) = S (len xs)

elem _ [] = False
elem n (x:xs) =
  case n == x of
    True -> True
    _    -> elem n xs

drop :: Nat -> [a] -> [a]
drop Z xs = xs
drop _ [] = []
drop (S x) (_:xs) = drop x xs

take :: Nat -> [a] -> [a]
take Z _ = []
take _ [] = []
take (S x) (y:ys) = y : (take x ys)

count :: Nat -> [Nat] -> Nat
count x [] = Z
count x (y:ys) =
  case x == y of
    True -> S (count x ys)
    _    -> count x ys

filter :: (a -> Bool) -> [a] -> [a]
filter _ [] = []
filter p (x:xs) =
  case p x of
     True  -> x : filter p xs
     _     -> filter p xs

sorted :: [Nat] -> Bool
sorted [] = True
sorted [x] = True
sorted (x:y:ys) = (x <= y) && sorted (y:ys)

insort :: Nat -> [Nat] -> [Nat]
insort n [] = [n]
insort n (x:xs) =
  case n <= x of
    True -> n : x : xs
    _ -> x : (insort n xs)

ins :: Nat -> [Nat] -> [Nat]
ins n [] = [n]
ins n (x:xs) =
  case n < x of
    True -> n : x : xs
    _ -> x : (ins n xs)

ins1 :: Nat -> [Nat] -> [Nat]
ins1 n [] = [n]
ins1 n (x:xs) =
  case n == x of
    True -> x : xs
    _ -> x : (ins1 n xs)

sort :: [Nat] -> [Nat]
sort [] = []
sort (x:xs) = insort x (sort xs)

prop_20 :: [Nat] -> Prop Nat
prop_20 xs = (len (sort xs) =:= len xs)

prop_29 :: Nat -> [Nat] -> Prop Bool
prop_29 x xs = proveBool (x `elem` ins1 x xs)

prop_30 :: Nat -> [Nat] -> Prop Bool
prop_30 x xs = proveBool (x `elem` ins x xs)

prop_38 :: Nat -> [Nat] -> Prop Nat
prop_38 n xs = (count n (xs ++ [n]) =:= S (count n xs))

prop_52 :: Nat -> [Nat] -> Prop Nat
prop_52 n xs = (count n xs =:= count n (rev xs))

prop_53 :: Nat -> [Nat] -> Prop Nat
prop_53 n xs = (count n xs =:= count n (sort xs))

prop_66 :: (a -> Bool) -> [a] -> Prop Bool
prop_66 p xs = proveBool (len (filter p xs) <= len xs)

prop_68 :: Nat -> [Nat] -> Prop Bool
prop_68 n xs = proveBool (len (delete n xs) <= len xs)

prop_72 :: Nat -> [a] -> Prop [a]
prop_72 i xs = (rev (drop i xs) =:= take (len xs - i) (rev xs))

prop_73 :: (a -> Bool) -> [a] -> Prop [a]
prop_73 p xs = (rev (filter p xs) =:= filter p (rev xs))

prop_74 :: Nat -> [a] -> Prop [a]
prop_74 i xs = (rev (take i xs) =:= drop (len xs - i) (rev xs))

prop_78 :: [Nat] -> Prop Bool
prop_78 xs = proveBool (sorted (sort xs))

