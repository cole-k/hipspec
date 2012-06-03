{-# LANGUAGE RecordWildCards #-}
module Hip.MakeInvocations where

import Hip.ATP.Invoke
import Hip.ATP.Provers
import Hip.ATP.Results
import Hip.Params
import Hip.Trans.MakeProofs
import Hip.Trans.ProofDatatypes (propMatter)
import Hip.Trans.Theory
import qualified Hip.Trans.ProofDatatypes as PD

import Halt.Monad
import Halt.Subtheory
import Halt.Trim
import Halt.Util

import Halt.FOL.Linearise
import Halt.FOL.Rename
import Halt.FOL.Style

import Data.List
import Data.Maybe

import Control.Monad

import UniqSupply

data InvokeResult
    = ByInduction
    | ByPlain
    | NoProof
  deriving (Eq,Ord,Show)

toInvokeResult :: PropResult -> InvokeResult
toInvokeResult p
    | plainProof p               = ByPlain
    | fst (propMatter p) /= None = ByInduction
    | otherwise                  = NoProof

partitionInvRes :: [(a,InvokeResult)] -> ([a],[a],[a])
partitionInvRes ((x,ir):xs) =
    let (a,b,c) = partitionInvRes xs
    in case ir of ByInduction -> (x:a,b,c)
                  ByPlain     -> (a,x:b,c)
                  NoProof     -> (a,b,x:c)
partitionInvRes [] = ([],[],[])

-- | Try to prove some properties in a theory, given some lemmas
tryProve :: HaltEnv -> Params -> [Prop] -> Theory -> [Prop]
         -> IO [(Prop,InvokeResult)]
tryProve halt_env params@(Params{..}) props thy lemmas = do
    let env = Env { reproveTheorems = False
                  , timeout         = timeout
                  , store           = output
                  , provers         = proversFromString provers
                  , processes       = processes
                  , propStatuses    = error "main env propStatuses"
                  , propCodes       = error "main env propCodes"
                  }

    us <- mkSplitUniqSupply '&'

    let ((properties,_msgs),_us) = runMakerM halt_env us
                                 . mapM (\prop -> theoryToInvocations
                                                      params thy prop lemmas)
                                 $ props

        properties' =
            [ PD.Property n c $
              [ let subs  = trim deps subtheories
                    pcls' = [ fmap (\cls -> linTPTP
                                     (strStyle cnf)
                                     (renameClauses
                                         (concatMap toClauses subs ++ cls))
                                      ++ "\n"
                                   ) pcl
                            | pcl <- pcls ]
                in  PD.Part m pcls'
              | PD.Part m (deps,subtheories,pcls) <- parts
              ]
            | PD.Property n c parts <- properties
            ]

    res <- invokeATPs properties' env

    forM res $ \property -> do

        let prop_name = PD.propName property
            invRes    = toInvokeResult property

        -- Need to figure out which of the input properties this
        -- invocation result corresponds to.
        -- This could obviously be done in a more elegant way.
        let err = error $ "Hip.ATP.MakeInvocations.tryProve: lost " ++ prop_name
            original = fromMaybe err $ find (\p -> prop_name == propName p) props

        let green | propOops original = Red
                  | otherwise         = Green

        case invRes of
            ByInduction -> putStrLn $ bold $ colour green
                                    $ "Proved " ++ prop_name
            ByPlain     -> putStrLn $ colour green $ "Proved " ++ prop_name
                                                      ++ " without induction"
            NoProof     -> putStrLn $ "Failed to prove " ++ prop_name

        return (original,invRes)

parLoop :: HaltEnv -> Params -> Theory -> [Prop] -> [Prop] -> IO ([Prop],[Prop])
parLoop halt_env params thy props lemmas = do

    (proved,without_induction,unproved) <-
         partitionInvRes <$> tryProve halt_env params props thy lemmas

    unless (null without_induction) $
         putStrLn $ unwords (map (showProp True) without_induction)
                 ++ " provable without induction"

    if null proved || isolate params

         then return (unproved,lemmas++proved++without_induction)

         else do putStrLn $ "Adding " ++ show (length proved)
                         ++ " lemmas: " ++ intercalate ", " (map propName proved)
                 parLoop halt_env params thy unproved
                         (lemmas ++ proved ++ without_induction)

showProp :: Bool -> Prop -> String
showProp proved Prop{..}
    | propOops && proved     = bold (colour Red propName)
    | propOops && not proved = colour Green propName
    | otherwise              = propName

printInfo :: [Prop] -> [Prop] -> IO ()
printInfo unproved proved = do

    let pr b xs | null xs   = "(none)"
                | otherwise = unwords (map (showProp b) xs)

    putStrLn ("Proved: "   ++ pr True proved)
    putStrLn ("Unproved: " ++ pr False unproved)
    putStrLn (show (length proved) ++ "/" ++ show (length (proved ++ unproved)))

