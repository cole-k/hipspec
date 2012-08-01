{-# LANGUAGE ViewPatterns #-}
{-

    From casing on a non-variable scrutinee, a constraint is
    generated. These are either equalities or inequalities.
    Example:

        f x = case e of
            K u     -> e1
            BAD     -> BAD
            DEFAULT -> UNR

    Here, it is assumed that e is more complex than just a variable.
    The desired (min-less) translation is this:

        forall x u . e = K(u) => f(x) = [[ e1 ]]

        forall x . e = BAD => f(x) = BAD

        forall x . (e /= K(sel_1_K(e)) & e /= BAD) => f(x) = UNR

    So we have get equalities from exact matches, and inequalities
    from inverting the other patterns in the DEFAULT branch.

    This file also contains some machinery to remove duplicate
    constraints, remove unnecessary constraints, and alert when
    constraints conflict. Conditions for these phenomena arise are either
    casing on a constructor or re-casing on an expression.
    Luckily, the GHC optimiser removes most occurences like this.

-}
module Halo.Constraints where

import CoreSubst
import CoreSyn
import CoreUtils
import DataCon
import Outputable
import Id

import Halo.Shared

import Data.List

-- Constraints from case expressions to results, under a substitution
data Constraint
    = Equality   CoreExpr DataCon [CoreExpr]
    | Inequality CoreExpr DataCon

instance Show Constraint where
    show constr = case constr of
        Equality e dc bs ->
            showExpr e ++ " = " ++ showOutputable dc
              ++ "(" ++ intercalate "," (map showOutputable bs) ++ ")"
        Inequality e dc ->
             showExpr e ++ " != " ++ showOutputable dc

-- | Substitute in the constraints
substConstr :: Subst -> Constraint -> Constraint
substConstr s c = case c of
    Equality e dc bs -> Equality (substExpr (text "substConstr") s e) dc
                                 (map (substExpr (text "substConstr") s) bs)
    Inequality e dc  -> Inequality (substExpr (text "substConstr") s e) dc

-- | The empty constraints
noConstraints :: [Constraint]
noConstraints = []

conflict :: [Constraint] -> Bool
conflict cs = or
    $ -- Conflict if C1(...) /= C1(...)
        [ cheapEqExpr e1 e2 && con_x == con_y
        | Equality   e1 con_x _ <- cs
        , Inequality e2 con_y <- cs
        ]
        -- Conflict if C1(...) = C2(...)
     ++ [ cheapEqExpr e1 e2 && con_x /= con_y
        | Equality e1 con_x _ <- cs
        , Equality e2 con_y _ <- cs
        ]
        -- Conflict if Inequality C1 C2(..), but C1 == C2
     ++ [ dataConWorkId con == x
        | Inequality (collectArgs -> (Var x,_)) con <- cs
        ]
        -- Conflict if Equality C1 C2(..), but C1 /= C2
     ++ [ dataConWorkId con /= x
        | Equality (collectArgs -> (Var x,_)) con _ <- cs
        , isConLikeId x
        -- ^ only if x is a constructor!
        ]

rmRedundantConstraints :: [Constraint] -> [Constraint]
rmRedundantConstraints = nubBy laxConstrEq . filter (not . redundant)

laxConstrEq :: Constraint -> Constraint -> Bool
laxConstrEq (Equality e1 con1 as1) (Equality e2 con2 as2)
    = cheapEqExpr e1 e2 && con1 == con2 && and (zipWith cheapEqExpr as1 as2)
laxConstrEq (Inequality e1 con1) (Inequality e2 con2)
    = cheapEqExpr e1 e2 && con1 == con2
laxConstrEq _ _ = False

redundant :: Constraint -> Bool
redundant c = case c of
    -- C1 /= C2 is redundant information, if C1 really is a constructor
    Inequality (collectArgs -> (Var x,_xs)) c2
        -> case isDataConId_maybe x of
               Just c1 -> c1 /= c2
               _       -> False
    -- C1 == C1 is redundant information,
    -- but what to do if it has arguments?
    Equality (collectArgs -> (Var x,[])) con []
        -> dataConWorkId con == x
    _ -> False
