-- First attempt: Does not work.
module TypeChecker where

import AbsCPP
import PrintCPP
import ErrM
import LexCPP
import SkelCPP
import Data.Map(filter, lookup, Map, insert, empty)
import ParCPP
import System.Exit (exitFailure)
import Control.Monad (foldM)

typecheck :: Program -> IO ()
typecheck p = case checkProg p of
    Left err -> do
        putStrLn "TYPE ERROR"
        putStrLn err
        exitFailure
    Right _ -> putStrLn "Ok" 

checkProg :: Program -> Err ()
checkProg (PDefs defs) = do
    env <- foldM addFun emptyEnv defs
    checkMain env
    where
        addFun env' (DFun typ (Id fname) args ss) = do
            let at = map (\(ADecl  typ' _) -> typ') args
            let ft = (at, typ)
            updateFun env' fname ft >>= newBlock >>= (`checkStm` ss)
        checkMain env' =
            case lookupFun env' (Id "main") of
                Ok ([], Type_void) -> return ()
                Ok _ -> fail $ "Main function must have type 'Void'."
                Bad err -> fail err

compile :: String -> IO ()
compile s = case pProgram (myLexer s) of
    Bad err -> do
        putStrLn "SYNTAX ERROR"
        putStrLn err
        exitFailure
    Ok tree -> typecheck tree 

type Env = (Sig,[Context])
type Sig = Map Id ([Type],Type)
type Context = Map Id Type

-- Auxiliary Functions
lookupVar :: Env -> Id -> Err Type
lookupVar (sig, []) x = fail $ "Variable " ++ show x ++ " is not found."
lookupVar (sig, ctx:ctxs) x =
    case Data.Map.lookup x ctx of
        Just t -> return t
        Nothing -> lookupVar (sig, ctxs) x
lookupVar _ _ = fail "Invalid environment"

lookupFun :: Env -> Id -> Err ([Type],Type)
lookupFun (sig, []) x =
    case Data.Map.lookup x sig of
        Just t -> return t
        Nothing -> fail ("Function " ++ show x ++ " is not found.")
lookupFun (sig, ctx : ctxs) x =
    case Data.Map.lookup x ctx of
        Just _ -> lookupFun (sig, [ctx]) x
        Nothing -> lookupFun (sig, ctxs) x

updateVar :: Env -> Id -> Type -> Err Env
updateVar (sig, []) x t = fail "Empty Context"
updateVar (sig, ctx:ctxs) x t =
    case Data.Map.lookup x ctx of
        Just _ -> return (sig, Data.Map.insert x t ctx : ctxs)
        Nothing -> updateVar (sig, ctxs) x t >>= \u -> return (sig, ctx:u)

updateFun :: Env -> Id -> ([Type],Type) -> Err Env
updateFun (sig, []) x t = fail $ "Function " ++ show x ++ " is not found"
updateFun (sig, ctx:ctxs) x t =
    case Data.Map.lookup x sig of
        Just _ -> return (Data.Map.insert x t sig, ctx:ctxs)
        Nothing -> updateFun (sig, ctxs) x t >>= \u -> return (sig, ctx:u)

newBlock :: Env -> Env
newBlock (sig, ctxs) = (sig, Data.Map.empty:ctxs)

emptyEnv :: Env
emptyEnv = (Data.Map.empty, [Data.Map.empty])

inferExp :: Env -> Exp -> Err Type
inferExp env x = case x of
    ETrue -> return Type_bool
    EInt n -> return Type_int
    EId id -> lookupVar env id
    EAnd exp1 exp2 ->
        inferBin [Type_bool] env exp1 exp2

inferBin :: [Type] -> Env -> Exp -> Exp -> Err Type
inferBin types env exp1 exp2 = do
    typ <- inferExp env exp1
    if typ `elem` types
        then
            checkExp env typ exp2
        else
            fail $ "Wrong type of expression " ++ printTree exp1
    return typ

checkExp :: Env -> Type -> Exp -> Err ()
checkExp env typ exp = do
    typ2 <- inferExp env exp
    if typ2 == typ then
        return ()
    else
        fail $ "Type of " ++ printTree exp ++
                "expected " ++ printTree typ ++
                "but found " ++ printTree typ2

checkStm :: Env -> Stm -> Err Env
checkStm env s = case s of
    SExp exp -> do
        inferExp env exp
        return env
    SDecls typ x ->
        updateVar env x typ
    SWhile exp stm -> do
        checkExp env Type_bool exp
        checkStm (newBlock env) stm
        return env

checkStms :: Env -> [Stm] -> Err Env
checkStms env stms = case stms of
    [] -> return env
    s : rest -> do
        env' <- checkStm env s
        checkStms env' rest
