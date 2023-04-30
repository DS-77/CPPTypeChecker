-- This programme is an implementation of a CPP Type Checker written in Haskell. Inspired by the code
-- in Implementing Programming Languages: An introduction to Compilers and Interpreters by Aarne Ranta
-- Author Deja S.
-- Course: CSCE 531 J50
-- Professor: Dr Marcos Valtorta

module TypeChecker where

import AbsCPP
import PrintCPP
import ErrM
import LexCPP
import SkelCPP
import Data.Map(filter, lookup, Map, insert, empty, member, map, fromList)
import ParCPP
import System.Exit (exitFailure)

compile :: String -> IO ()
compile s = case pProgram (myLexer s) of
    Bad err -> fail $ "SYNTAX ERROR: " ++ err
    Ok tree -> either handleErr handleSuccess (checkProgram emptyEnv tree)
    where
        checkProgram :: Env -> Program -> Err Env
        checkProgram env (PDefs defs) = do
            env' <- checkDefs env defs
            checkMain env'

        checkDefs :: Env -> [Def] -> Err Env
        checkDefs env [] = return env
        checkDefs env (def:defs) = do
            env' <- checkDef env def
            checkDefs env' defs

        checkDef :: Env -> Def -> Err Env
        checkDef env (DFun typ id args stms) = do
            -- at: Args Types
            -- ai: Args Id
            -- ctx: context
            let at = Prelude.map (\(ADecl typ _) -> typ) args
            let ai = Prelude.map (\(ADecl _ id) -> id) args
            let ctx = Data.Map.fromList (zip ai at)
            let env' = (Data.Map.insert id (at, typ) (fst env), ctx: snd env)
            checkStms env' stms >>= \u -> return (fst u, tail(snd u))

        checkMain :: Env -> Err Env
        checkMain env@(sig, ctx) = 
            case Data.Map.lookup (Id "main") sig of
                Nothing -> fail $ "TYPE ERROR: No main function found."
                Just (pt, rt) -- pt: param types; rt: return type
                    | null pt && rt == Type_void -> return env
                    | otherwise -> fail $ "TYPE ERROR: Main function has wrong signature."

-- Helper functions
handleErr :: String -> IO ()
handleErr err = fail $ "TYPE ERROR: " ++ err

handleSuccess :: Env -> IO ()
handleSuccess env = case env of
    (sig, _) | Data.Map.member (Id "main") sig -> return ()
    _ -> fail "TYPE ERROR: No main function"

type Env = (Sig,[Context])
type Sig = Map Id ([Type],Type)
type Context = Map Id Type

-- Auxillary Functions
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
        Nothing -> updateVar (sig, ctxs) x t >>= \u -> return (sig, ctx:ctxs)

updateFun :: Env -> Id -> ([Type],Type) -> Err Env
updateFun (sig, ctx:ctxs) x t =
    case Data.Map.lookup x sig of
        Just _ -> return (Data.Map.insert x t sig, ctx:ctxs)
        Nothing -> fail $ "Function " ++ show x ++ " is not found"
updateFun _ _ _ = fail "Empty Context"

newBlock :: Env -> Env
newBlock (sig, ctxs) = (sig, Data.Map.empty:ctxs)

emptyEnv :: Env
emptyEnv = (Data.Map.empty, [Data.Map.empty])

-- Inference Rules
inferExp :: Env -> Exp -> Err Type
inferExp env x = case x of
    ETrue -> return Type_bool
    EInt n -> return Type_int
    EId id -> lookupVar env id
    EAnd exp1 exp2 ->
        inferBin [Type_int, Type_double, Type_string] env exp1 exp2

inferBin :: [Type] -> Env -> Exp -> Exp -> Err Type
inferBin types env exp1 exp2 = do
    typ <- inferExp env exp1
    if typ `elem` types
        then
            checkExp env typ exp2
        else
            fail $ "Wrong type of expression " ++ printTree exp1
    return typ

-- Checking Rules
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
    SDecl typ x ->
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