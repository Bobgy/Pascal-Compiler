#include "global.h"
#include "util.h"
#include "code.h"

#define SHOW(x) {if(!showed){showed=(x);DEBUG_INFO(#x"\n");}}

Code TreeNode::genCode() {
    unsigned showed = 0;
    if (nodeKind == STMTKIND) {
        switch(kind.stmtType) {
            //PROGRAM NAME SEMI
            case PROGRAM_HEAD: SHOW(PROGRAM_HEAD);
            //PROCEDURE  NAME  parameters($0)
            case PROCEDURE_HEAD: SHOW(PROCEDURE_HEAD);
            //FUNCTION  NAME  parameters($0)  COLON  simple_type_decl($1)
            case FUNCTION_HEAD: {
                SHOW(FUNCTION_HEAD);
                bool isFunction = kind.stmtType == FUNCTION_HEAD;

                // Make the function type
                vector<Type *> args;
                vector<string> names;

                TreeNode *parameters       = child[0],
                         *simple_type_decl = isFunction ? child[1] : NULL;

                for (auto &para_type_list: parameters->child) {

                    TreeNode *var_para_list    = para_type_list->child[0],
                             *simple_type_decl = para_type_list->child[1];

                    Type *type = simple_type_decl->genCode().getType();
                    for (auto &name: var_para_list->child) {
                        args.push_back(type);
                        names.push_back(name->attr.symbolName);
                    }
                }

                Type *retType = isFunction ?
                    simple_type_decl->genCode().getType()
                  : Type::getVoidTy(getGlobalContext());

                FunctionType *FT = FunctionType::get(
                    retType, args,
                    false //is parameter count variable
                );

                Function *F = Function::Create(
                    FT, Function::ExternalLinkage,
                    attr.symbolName, TheModule
                );
                ASSERT(F);

                // check whether F is conflicting existing functions
                if (!F->getName().equals(attr.symbolName)) {
                    sprintf(buf, "Redeclaration of function \"%s\"\n", attr.symbolName);
                    yyerror(buf);
                }

                auto AI = F->arg_begin();
                for (auto &name: names) {
                    AI->setName(name);
                    ++AI;
                }

                // Create a new basic block to start insertion into.
                BasicBlock *BB = BasicBlock::Create(
                    getGlobalContext(), "entry", F);
                ASSERT(BB);
                Builder.SetInsertPoint(BB);

                if(isFunction){
                    Value *retVal = CreateEntryBlockAlloca(
                        F, attr.symbolName, retType);
                }

                // Create an alloca for each argument and register the argument
                // in the symbol table so that references to it will succeed.
                AI = F->arg_begin();
                for (unsigned i = 0; i < args.size(); ++i, ++AI) {
                    // Create an alloca for this variable.
                    yyinfo("VAR ");
                    yyinfo(names[i].c_str());
                    yyinfo("\n");
                    AllocaInst *alloca = CreateEntryBlockAlloca(
                        F, names[i].c_str(), args[i]
                    );
                    Builder.CreateStore(AI, alloca);
                }

                return Code(F);
            }


            //program_stmt: program_head  routine  DOT
            case PROGRAM_STMT: SHOW(PROGRAM_STMT);
                //$$->child = {program_head, routine}
            case PROCEDURE_DECL: SHOW(PROCEDURE_DECL);
                //$$->child = {procedure_head, sub_routine}
            case FUNCTION_DECL: {
                //$$->child = {function_head, sub_routine}
                SHOW(FUNCTION_DECL);
                TreeNode *function_head = child[0],
                         *sub_routine   = child[1];

                pushFuncContext(function_head->attr.symbolName);
                Function *F = function_head->genCode().getFunction();
                sub_routine->genCode();
                if (kind.stmtType==FUNCTION_DECL) {
                    Value *val = Builder.CreateLoad(
                        getName(function_head->attr.symbolName).getValue(),
                        function_head->attr.symbolName
                    );
                    Builder.CreateRet(val);
                } else Builder.CreateRetVoid();

                // finish function implementation
                // Validate the generated code, checking for consistency.
                verifyFunction(*F);

                // Optimize the function.
                // TheFPM->run(*F); TODO

                popFuncContext();

                return F;
            }

            //routine: routine_head routine_body
            case ROUTINE: SHOW(ROUTINE);
            //sub_routine: routine_head routine_body
            case SUB_ROUTINE: {
                SHOW(SUB_ROUTINE);
                TreeNode *routine_head = child[0],
                         *routine_body = child[1];
                routine_head->genCode();
                routine_body->genCode();
                return Code();
            }

            case VAR_DECL: {
                //$$->child = {name_list, type_decl}
                SHOW(VAR_DECL);
                TreeNode *name_list = child[0],
                         *type_decl = child[1];
                Code type = type_decl->genCode();
                Function *F = Builder.GetInsertBlock()->getParent();
                for (auto name: name_list->child) {
                    if (isGlobal) {
                        GlobalVariable* gvar = new GlobalVariable(
                            *TheModule,
                            type.getType(),
                            false, // is constant
                            GlobalValue::CommonLinkage,
                            ConstantInt::get( // initializer
                                TheModule->getContext(),
                                APInt(32, StringRef("0"), 10)
                            ),
                            name->attr.symbolName
                        );
                        gvar->setAlignment(4);
                        getFuncContext()->insertName(name->attr.symbolName, gvar);
                    } else {
                        AllocaInst *alloca = CreateEntryBlockAlloca(
                            F, name->attr.symbolName, type);
                    }
                }
                return Code();
            }

            case SIMPLE_TYPE_DECL: {
                SHOW(SIMPLE_TYPE_DECL);
                switch(derivation) {
                    case 1: { //SYS_TYPE
                        DEBUG_INFO("generating SYS_TYPE\n");
                        switch(symbolType){
                            //case TYPE_VOID:
                            case TYPE_INTEGER:
                                DEBUG_INFO("generated TYPE_INTEGER\n");
                                return Code(Type::getInt32Ty(getGlobalContext()));
                            case TYPE_BOOLEAN:
                                DEBUG_INFO("generated TYPE_BOOLEAN\n");
                                return Code(Type::getInt32Ty(getGlobalContext()));
                            case TYPE_REAL:
                                DEBUG_INFO("generated TYPE_REAL\n");
                                return Code(Type::getDoubleTy(getGlobalContext()));
                            case TYPE_CHARACTER:
                                DEBUG_INFO("generated TYPE_CHARACTER\n");
                                return Code(Type::getInt8Ty(getGlobalContext()));
                            //case TYPE_STRING
                            default: yyerror("Undefined sys type!");
                        }
                    }
                    case 2: // NAME
                        DEBUG_INFO("generating NAME\n");
                        return getName(child[0]->attr.symbolName);
                    /*
                    case 3: LP name_list RP
                    case 4: const_value DOTDOT const_value
                    case 5: MINUS const_value DOTDOT const_value
                    case 6: MINUS const_value DOTDOT MINUS const_value
                    case 7: NAME DOTDOT NAME
                    */
                    default: yyerror("Not defined type.");
                }
            }

            case ASSIGN_STMT: {
                SHOW(ASSIGN_STMT);
                switch (derivation) {
                    // NAME ASSIGN expression($0)
                    case 1: {
                        TreeNode *expression = child[0];
                        Value *val = expression->genCode().getValue();
                        Value *var = getName(attr.symbolName).getValue();
                        Builder.CreateStore(val, var);
                        return Code(val);
                    }
                    default: yyerror("ASSIGN_STMT not found!");
                }
            }

            //if_stmt: IF  expression  THEN  stmt  else_clause
            case IF_STMT: {
                //$$->child = {expression, stmt, else_clause}
                SHOW(IF_STMT);
                TreeNode *expression  = child[0],
                         *stmt        = child[1],
                         *else_clause = child[2];
                Code exp = expression->genCode();
                Value *CondV = exp.getValue();
                /*
                Value *CondV = Builder.CreateICmpNE(
                    exp.getValue(),
                    ConstantInt::get(Type::getInt32Ty(getGlobalContext()), 0)
                );
                */
                Function *TheFunction = Builder.GetInsertBlock()->getParent();

                // Create blocks for the then and else cases.  Insert the 'then' block at the
                // end of the function.
                BasicBlock *ThenBB = BasicBlock::Create(getGlobalContext(), "then", TheFunction);
                BasicBlock *ElseBB = BasicBlock::Create(getGlobalContext(), "else");
                BasicBlock *MergeBB = BasicBlock::Create(getGlobalContext(), "ifcont");

                Builder.CreateCondBr(CondV, ThenBB, ElseBB);

                // Emit then value.
                Builder.SetInsertPoint(ThenBB);
                stmt->genCode();
                Builder.CreateBr(MergeBB);
                ThenBB = Builder.GetInsertBlock();

                // Emit else block.
                TheFunction->getBasicBlockList().push_back(ElseBB);
                Builder.SetInsertPoint(ElseBB);

                else_clause->genCode();

                Builder.CreateBr(MergeBB);
                ElseBB = Builder.GetInsertBlock();

                // Emit merge block.
                TheFunction->getBasicBlockList().push_back(MergeBB);
                Builder.SetInsertPoint(MergeBB);
                return Code();
            }

            case PROC_STMT: {
                //SYS_PROC(child[0])  LP  args_list(child[1])  RP
                SHOW(PROC_STMT);
                TreeNode *sys_proc  = child[0],
                         *args_list = child[1];

                if(strcmp(sys_proc->attr.symbolName, "writeln")==0){
                    Function *CalleeF;
                    ASSERT(CalleeF  = TheModule->getFunction("printf"));

                    // If argument mismatch error.

                    vector<Value *> args = genArgsList(args_list);
                    args.insert(args.begin(), genPrintf.const_ptr);

                    return Builder.CreateCall(CalleeF, args);
                } else { //if(strcmp(sys_proc->attr.symbolName, "write")==0){
                    sprintf(buf, "Not implemented %s!", sys_proc->attr.symbolName);
                    yyerror(buf);
                }
            }

            case ROUTINE_HEAD: SHOW(ROUTINE_HEAD);
            case VAR_PART: SHOW(VAR_PART);
            case ROUTINE_PART: SHOW(ROUTINE_PART);
            case VAR_DECL_LIST: SHOW(VAR_DECL_LIST);
            case STMT_LIST: SHOW(STMT_LIST);
                for(auto ch: child)
                    ch->genCode();
                return Code();

            default: {
                sprintf(buf, "Ignore unimplemented Statement Type %d\n", kind.stmtType);
                DEBUG_INFO(buf);
                return Code();
            }
        }
    } else {
        ASSERT(nodeKind == EXPKIND);
        /*
         *  typedef enum {
         *      OPKIND, CONSTKIND, IDKIND, FUNCKIND, ARRAYKIND, RECORDKIND
         *  } ExpKind;
         *
         */
        switch(kind.expKind) {
            case CONSTKIND: {
                //TYPE_VOID, TYPE_INTEGER, TYPE_BOOLEAN,
                //TYPE_REAL, TYPE_CHARACTER, TYPE_STRING
                switch(symbolType) {
                    case TYPE_INTEGER:
                        SHOW(TYPE_INTEGER);
                        return Code(
                            ConstantInt::get(
                                getGlobalContext(),
                                APInt(32, attr.value.integer, true)
                            )
                        );
                    default:
                        sprintf(buf, "Not implemented Symbol Type %d\n", symbolType);
                        yyerror(buf);
                }
            }
            case NAMEKIND: SHOW(NAMEKIND);
                return Builder.CreateLoad(
                    getName(attr.symbolName).getValue(),
                    attr.symbolName
                );
            case OPKIND:
                Value *lval, *rval;
                ASSERT(lval = child[0]->genCode().getValue());
                ASSERT(rval = child[1]->genCode().getValue());
                switch (attr.op) {
                    case OP_EQUAL: SHOW(OP_EQUAL);
                        return Builder.CreateICmpEQ(lval, rval);
                    case OP_PLUS: SHOW(OP_PLUS);
                        return Builder.CreateAdd(lval, rval);
                    case OP_MINUS: SHOW(OP_MINUS);
                        return Builder.CreateSub(lval, rval);
                    default:
                        sprintf(buf, "OPKIND %d not implemented!", attr.op);
                        yyerror(buf);
                }
            case FUNCKIND: {
                //NAME  LP  args_list(child[0])  RP
                SHOW(FUNCKIND);
                TreeNode *args_list = child[0];

                Function *CalleeF;
                ASSERT(CalleeF  = TheModule->getFunction(attr.symbolName));

                // If argument mismatch error.
                if (CalleeF->arg_size() != args_list->child.size()) {
                    yyerror("Incorrect # arguments passed");
                }

                vector<Value *> args = genArgsList(args_list);

                return Builder.CreateCall(CalleeF, args);
            }
            default:
                sprintf(buf, "Not implemented Expression Type %d\n", kind.expKind);
                yyerror(buf);
        }
    }
    yyerror("No code generated");
    return Code();
}

vector<Value *> genArgsList(TreeNode *argsList){
    vector<Value *> args;
    for(auto ch: argsList->child){
        args.push_back(ch->genCode().getValue());
    }
    return args;
}

void Printf::init(){
    const_array = ConstantDataArray::getString(TheModule->getContext(), "%d\x0A", true);
    ArrayType* ArrayTy = ArrayType::get(IntegerType::get(TheModule->getContext(), 8), 4);
    gvar_array__str = new GlobalVariable(
        /*Module=*/*TheModule,
        /*Type=*/ArrayTy,
        /*isConstant=*/true,
        /*Linkage=*/GlobalValue::PrivateLinkage,
        /*Initializer=*/const_array,
        /*Name=*/".str"
    );
    gvar_array__str->setAlignment(1);
    PointerType* PointerTy =
        PointerType::get(IntegerType::get(TheModule->getContext(), 8), 0);

    vector<Type*> FuncTy_args;
    FuncTy_args.push_back(PointerTy);
    FunctionType* FuncTy = FunctionType::get(
        /*Result=*/IntegerType::get(TheModule->getContext(), 32),
        /*Params=*/FuncTy_args,
        /*isVarArg=*/true
    );
    Function* func_printf = TheModule->getFunction("printf");
    if (!func_printf) {
        func_printf = Function::Create(
            /*Type=*/FuncTy,
            /*Linkage=*/GlobalValue::ExternalLinkage,
            /*Name=*/"printf",
            TheModule
        ); // (external, no body)
        func_printf->setCallingConv(CallingConv::C);
    }
    AttributeSet func_printf_PAL;
    {
        SmallVector<AttributeSet, 4> Attrs;
        AttributeSet PAS;
        {
             AttrBuilder B;
             B.addAttribute(Attribute::ReadOnly);
             B.addAttribute(Attribute::NoCapture);
             PAS = AttributeSet::get(TheModule->getContext(), 1U, B);
        }

        Attrs.push_back(PAS);
        {
             AttrBuilder B;
             B.addAttribute(Attribute::NoUnwind);
             PAS = AttributeSet::get(TheModule->getContext(), ~0U, B);
        }

        Attrs.push_back(PAS);
        func_printf_PAL = AttributeSet::get(TheModule->getContext(), Attrs);

    }
    func_printf->setAttributes(func_printf_PAL);

    std::vector<Constant*> const_ptr_indices;
    const_int32_0 = ConstantInt::get(TheModule->getContext(), APInt(32, StringRef("0"), 10));
    const_ptr_indices.push_back(const_int32_0);
    const_ptr_indices.push_back(const_int32_0);
    const_ptr = ConstantExpr::getGetElementPtr(gvar_array__str, const_ptr_indices);
    const_ptr_to_str =
        ConstantExpr::getGetElementPtr(gvar_array__str, const_ptr_indices);
}

Printf genPrintf;

void init_sys_func(){
    genPrintf.init();
}
