# Pascal Compiler for ZJU course project

## team member:
- 王力宁 3120000405
- 王睿   3120000305
- 朱稼乐 3120000346
- 龚源   3120000381

## Current status
- test1 passed
- test2 passed
- test3 passed
- test4 passed
- test5 passed
- test6 passed
- test7 passed
- test8 passed

## How to compile
You need to compile this project in Linux. The following instructions are for Ubuntu.

### dependencies
- yacc(bison)
- lex(flex)
- clang-3.6 && llvm-3.6
- python (a python script is used to test lex)
- libedit-dev may be needed if you encounter compilation errors (`sudo apt-get install libedit-dev zlib1g-dev` in ubuntu)

### instructions

Build the project
```
$> make
```

Build test programs for lex
```
$> make test
```

Clear built files
```
$> make clean
```

Show lex results for a pas file. See utils/README.md for an example.
```
$> utils/token.bash < path/to/pascal_file.pas
```

Setting YYDEBUG environment variable to 1 will enable debug info.
```
$> export YYDEBUG=1
```

Compile a pas file to llvm assembly.
```
./y.tab.out < test/test1.pas > path/to/llvm_assembly_file.ll
```

Run llvm assembly directly
```
lli path/to/llvm_assembly_file.ll
```

Run all test cases
```
cd test
make
```

Compile to masm and executable file
```
cd test
../y.tab.out < test1.pas > test1.ll
llc-3.6 test1.ll
clang-3.6 test1.s -o test1.out
./test1.out
```
