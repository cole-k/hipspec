{-# LANGUAGE DeriveDataTypeable #-}
module Nat where

import Prelude hiding ((+),(*), max)
import HipSpec
import Data.Typeable

data Nat = Z | S Nat deriving (Eq,Ord,Show,Typeable)

infixl 6 +
infixl 7 *

(+) :: Nat -> Nat -> Nat
S n + m = S (n + m)
Z   + m = m

(*) :: Nat -> Nat -> Nat
S n * m = m + (n * m)
Z   * m = Z

max Z     y     = y
max x     Z     = x
max (S x) (S y) = S (max x y)

-- prop_mul x y = x * y =:= y * x

instance Enum Nat where
  toEnum 0 = Z
  toEnum n = S (toEnum (pred n))
  fromEnum Z = 0
  fromEnum (S n) = succ (fromEnum n)

instance Arbitrary Nat where
  arbitrary = sized $ \ s -> do
    x <- choose (0,round (sqrt (toEnum s)))
    return (toEnum x)

instance Names Nat where
  names _ = ["m","n","o"]
