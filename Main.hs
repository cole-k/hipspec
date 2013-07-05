module Main where

import Read
import Utils

import CoreToRich
import SimplifyRich
import RichToSimple

import PrettyRich as PR
import PrettySimple as PS

import Rich (Typed(..))

import Name
import Unique
import CoreSyn

import Control.Monad
import System.Environment

import Text.PrettyPrint.HughesPJ

getFlag :: Eq a => a -> [a] -> (Bool,[a])
getFlag _   []  = (False,[])
getFlag flg (x:xs)
    | flg == x  = (True,xs)
    | otherwise = (b,x:ys)
  where (b,ys) = getFlag flg xs

getFlag' :: Eq a => a -> ([a] -> b) -> [a] -> (Bool,b)
getFlag' flg k xs = (b,k ys)
  where (b,ys) = getFlag flg xs

main :: IO ()
main = do
    args <- getArgs

    let (opt,(suppress_uniques,(show_types,file))) = ($ args) $
            getFlag' "-O" $
            getFlag' "-s" $
            getFlag' "-t" $ \ args' ->
                case args' of
                    [f] -> f
                    _   -> error "Usage: FILENAME [-O] [-s] [-t]"

    cb <- readBinds (if opt then Optimise else Don'tOptimise) file

    let name :: Name -> String
        name nm = getOccString nm ++
            if suppress_uniques then "" else "_" ++ showOutputable (getUnique nm)

        name' :: Rename Name -> String
        name' (Old nm) = name nm
        name' (New x)  = "_" ++ show x

        show_typed :: Typed String -> Doc
        show_typed (x ::: t)
            | show_types = parens (hang (text x <+> text "::") 2 (ppType 0 text t))
            | otherwise  = text x

    forM_ (flattenBinds cb) $ \ (v,e) -> do
        putStrLn (showOutputable v ++ " = " ++ showOutputable e)
        case trDefn v e of
            Right fn -> do
                let put = putStrLn . render . PR.ppFun show_typed . fmap (fmap name)
                put fn
                let fn' = simpFun fn
                put fn'
                let simp_fns
                        = uncurry (:)
                        . runRTS
                        . rtsFun
                        . fmap (fmap Old)
                        $ fn'
                    put' = putStrLn . render . PS.ppFun show_typed . fmap (fmap name')
                mapM_ put' simp_fns
            Left err -> print err
        putStrLn ""

