#include "global.h"
#include "util.h"
#include "code.h"
#include <fstream>

extern int yydebug;
int debuginfo;

TreeNode *syntaxTreeRoot;
FuncContext *globalFuncContext;

Module *TheModule;
IRBuilder<> Builder(getGlobalContext());
FunctionPassManager *TheFPM;
void init_template_expr();

void loadConfig() {
    fstream config;
    config.open(".config", ios::in);
    yydebug = 0;
    debuginfo = 0;
    if (config.is_open()) {
        string a, b, c;
        while (config >> a >> b >> c) {
            if (b != "=") continue;
            if (a == "YYDEBUG") {
                yydebug = atoi(c.c_str());
                cerr << "CONFIG: YYDEBUG = " << yydebug << endl;
            } else if (a == "DEBUGINFO") {
                debuginfo = atoi(c.c_str());
                cerr << "CONFIG: DEBUGINFO = " << debuginfo << endl;
            }
        }
    }
}

int main()
{
    loadConfig();
    init_template_expr();

    LLVMContext &Context = getGlobalContext();

    // the target module to generate
    TheModule = new Module("pascal", Context);

    FunctionPassManager OurFPM(TheModule);

    // Set up the optimizer pipeline.  Start with registering info about how the
    // target lays out data structures.
    // TheModule->setDataLayout(TheExecutionEngine->getDataLayout());
    OurFPM.add(new DataLayoutPass());
    // Provide basic AliasAnalysis support for GVN.
    OurFPM.add(createBasicAliasAnalysisPass());
    // Promote allocas to registers.
    OurFPM.add(createPromoteMemoryToRegisterPass());
    // Do simple "peephole" optimizations and bit-twiddling optzns.
    OurFPM.add(createInstructionCombiningPass());
    // Reassociate expressions.
    OurFPM.add(createReassociatePass());
    // Eliminate Common SubExpressions.
    OurFPM.add(createGVNPass());
    // Simplify the control flow graph (deleting unreachable blocks, etc).
    OurFPM.add(createCFGSimplificationPass());

    OurFPM.doInitialization();

    // Set the global so the code gen can use this.
    TheFPM = &OurFPM;

    init_sys_func();

    yyparse();

    TheFPM = NULL;

    error_code EC;
    raw_fd_ostream std_output("-", EC, sys::fs::F_None);

    TheModule->print(std_output, NULL);

    return 0;
}
