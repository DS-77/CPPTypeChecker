# Type Checkers

Type checking is a crucial process in programming that ensures that each operation executed in a program adheres to the type system of the underlying programming language. It is an essential component of compilers as it enables the detection of errors at compile time and helps to resolve ambiguities within the code, resulting in the generation of optimal machine code. Furthermore, type checkers provide valuable context for looking up variable types, thereby aiding the programmer in debugging and optimizing their code. 

This project showcases the implementation of a type checker in Haskell for parsing C++ code fragments. The development is based on the concepts and techniques described in Aarne Ranta's text, "Implementing Programming Languages".

## Project 
#### Project Setup
The initial step of the project involved the creation of a formal grammar specification for the CPP language in the form of a BNF (Backus-Naur Form) grammar file, drawing upon Section 2.10 of Ranta's seminal work on formal language theory. Subsequently, I employed the BNF Converter, a powerful compiler construction tool, to generate several target language-specific files in Haskell, based on the grammar specification. The BNF Converter tool is widely used in the industry for developing compiler front-ends, by automating the generation of parser code from BNF grammar specifications.

Below is a preview of the working directory after running the `bnfc -m CPP.cf` command:
```
TypeChecker
|   AbsCPP.hs
|   CPP.cf
|   DocCPP.txt
|   DocCPP.txt.bak
|   ErrM.hi
|   ErrM.hs
|   ErrM.o
|   LexCPP.hs
|   LexCPP.x
|   Makefile
|   ParCPP.y
|   ParCPP.y.bak
|   PrintCPP.hs
|   PrintCPP.hs.bak
|   README.md
|   SkelCPP.hs
|   TestCPP.hs
|   TypeChecker.hs
|------ Test_CPP_Code
        |   Bad.cpp
        |   Good.cpp
```
The directory now comprises numerous files that provide functionalities such as pretty printing, abstract syntax, and an input file for the Happy parsing tool. In addition, the Makefile, which was generated from the previous command, facilitates the generation of the remaining essential dependencies for the compiler. 

Below is a view of the working directory after I ran the `make` command:

```
TypeChecker
|   AbsCPP.hi
|   AbsCPP.hs
|   AbsCPP.hs.bak
|   AbsCPP.o
|   CPP.cf
|   DocCPP.txt
|   DocCPP.txt.bak
|   ErrM.hi
|   ErrM.hs
|   ErrM.o
|   LexCPP.hi
|   LexCPP.hs
|   LexCPP.o
|   LexCPP.x
|   Makefile
|   ParCPP.hi
|   ParCPP.o
|   ParCPP.y
|   ParCPP.y.bak
|   PrintCPP.hi
|   PrintCPP.hs
|   PrintCPP.hs.bak
|   PrintCPP.o
|   README.md
|   SkelCPP.hi
|   SkelCPP.hs
|   SkelCPP.hs.bak
|   SkelCPP.o
|   TestCPP.hi
|   TestCPP.hs
|   TestCPP.o
|   TypeChecker.hs
|------ Test_CPP_Code
        |   Bad.cpp
        |   Good.cpp
```
#### Type Checker Implementation
After generating the required files, I proceeded to develop a Haskell program called `TypeChecker.hs`, to execute the crucial task of type checking for the provided C++ code. Within this program, I meticulously established multiple inference rules that serve as a guide for the compiler to analyze the source code and determine the correct types of expressions and statements. 

With the help of sections 4.9 - 4.11 in Ranta's text, I was able to produce a skeleton of the Type Checker. The `compile`, `inferExp`, `inferBin`, `checkExp`, `checkStm`, `checkStms` functions are described in section 4.11. `Compile` work as the main entry point of the programme and houses other helper functions that assist the parser by type-checking the tree. These functions include: 

- `checkProgram`
- `checkDefs`
- `checkDef`
- `checkMain`

Additional helper functions were used to assist with error handling and messages. These functions, `handleErr` and `handleSuccess` are used to convert from type `Err ()`, produced by the error handling Monad, to `IO ()` for the output of the compile function.

Expanding upon the auxiliary operation types, as referenced by Ranta in section 4.11 of his publication, I proceeded to define and implement relevant functions that could facilitate the process of sequential checking and inference.

Below is a snippet of the `TypeChecker.hs` code describing the auxiliary operations.
```
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
```
The inference and checking rules work together to define the typing system of the target language. `inferExp`, `inferBin`, `checkExp`, `checkStm`, and `checkStms` work in this fashion to provide a typing system of C++ source code. Function `inferExp` infers the type of an expression from the given environment. `inferBin` function infers the type of binary expressions. `checkExp` function checks whether a given expression's type matches the type described in the environment's context. Functions `checkStm` and `checkStms` checks if the given types of statements match the types inferred in the environment's context.
## Testing the Code
To demonstrate the capability of the Haskell Type Checker, I created two samples of code to run through this programme. Located in the `Test_CPP_Code` directory, are two samples of C++ code: `Good.cpp` and `Bad.cpp`. The `Good.cpp` contains no typing errors therefore, it will go through the Haskell Type checker successfully, producing an `Ok` as output. The other file, `Bad.cpp`, contains a typing error; the Type Checker will produce a typing error.

To run the Type Checker against the code samples:

1. Download or Clone the repo to the directory of your choosing: `git clone https://github.com/DS-77/CPPTypeChecker.git`
2. Navigate to the directory that contains the source code.
3. Open a terminal and run the following in the root directory of the project:`ghc --make TypeChecker.hs`
4. Then run: `./TypeChecker /Test_CPP_Code/Bad.cpp` or `./TypeChecker /Test_CPP_Code/Good.cpp`

### Dependencies
At the time of this project I used: 
- ghc 8.8.4 
- Happy 1.19.12
- BNFC 2.83 
### Citations

- A. Ranta, *Implementing Programming Languages*, vol. 16. College Publication, 2012.

- https://www.haskell.org/documentation/
- https://hoogle.haskell.org/