# Type Checkers

Type checking is a crucial process in programming that ensures that each operation executed in a program adheres to the type system of the underlying programming language. It is an essential component of compilers as it enables the detection of errors at compile time and helps to resolve ambiguities within the code, resulting in the generation of optimal machine code. Furthermore, type checkers provide valuable context for looking up variable types, thereby aiding the programmer in debugging and optimizing their code. 

This project showcases the implementation of a type checker in Haskell for parsing C++ code fragments. The development is based on the concepts and techniques described in Aarne Ranta's text, "Implementing Programming Languages"

## Project 
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
The Makefile, that was generated from previous command, can be used to further generate the rest of the required dependencies for the compiler. 

Once the necessary files were generated, I created a Haskell programme, `TypeChecker.hs`, to conduct the actual type checking for the given C++ code. In this file, I define various inference rules to guide the compiler. 

### Testing the Code
To demonstrate the capability of the Haskell Type Checker, I created two samples of code to run through this programme. Located in the `Test_CPP_Code` directory, are two samples of C++ code: `Good.cpp` and `Bad.cpp`. The `Good.cpp` contains no typing errors therefore, it will go through the Haskell Type checker successfully, producing an `Ok` as output. The other file, `Bad.cpp`, contains a typing error; the Type Checker will produce a typing error.

#### Citations

A. Ranta, *Implementing Programming Languages*, vol. 16. College Publication, 2012.