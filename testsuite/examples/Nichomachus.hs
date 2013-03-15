module Nichomachus where

import Prelude (error)
import Nat hiding (sig)
import HipSpec.Prelude
import Test.QuickSpec.Signature

sum Z     = Z
sum (S n) = sum n + S n

cubes Z     = Z
cubes (S n) = cubes n + (S n * S n * S n)

prop_Nichomachus :: Nat -> Prop Nat
prop_Nichomachus n = cubes n =:= sum n * sum n

sig = signature
    [ pvars ["x", "y", "z"] (error "Nat type" :: Nat)
    , fun0 "Z" Z
    , fun1 "S" S
    , fun2 "+" (+)
    , fun2 "*" (*)
    , fun1 "sum"   sum
    , fun1 "cubes" cubes
    , withQuickCheckSize 500
    ]

