#include "global.h"
#include "util.h"
#include "code.h"

#define SHOW(x) {if(!showed){showed=(x);DEBUG_INFO(#x"\n");}}

Code TreeNode::genCode() {
    unsigned showed = 0;
    if (nodeKind == STMTKIND) {
        switch(kind.stmtType) {
            //NAME  EQUAL  const_value($0)  SEMI
            case CONST_EXPR: {
                SHOW(CONST_EXPR);
                TreeNode *const_value = child[0];
                Value *val = const_value->genCode().getValue();
                getFuncContext()->insertName(attr.symbolName, val);
                return val;
            }
            //NAME  EQUAL  type_decl($0)  SEMI
            case TYPE_DEFINITION: {
                SHOW(TYPE_DEFINITION);
                TreeNode *type_decl = child[0];
                type_decl->attr.symbolName = attr.symbolName;
                Type *ty = type_decl->genCode().getType();
                if (debuginfo) ty->dump();
                getFuncContext()->insertName(attr.symbolName, ty);
                return ty;
            }
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
                vector<bool>   isVar;

                TreeNode *parameters       = child[0],
                         *simple_type_decl = isFunction ? child[1] : NULL;

                for (auto &para_type_list: parameters->child) {

                    TreeNode *var_para_list    = para_type_list->child[0],
                             *simple_type_decl = para_type_list->child[1];

                    Type *type = simple_type_decl->genCode().getType();
                    for (auto &name: var_para_list->child) {
                        isVar.push_back(var_para_list->derivation==1); //VAR
                        args.push_back(isVar.back() ? type->getPointerTo() : type);
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
                BasicBlock *BB;
                ASSERT(BB = BasicBlock::Create(getGlobalContext(), "entry", F));
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
                    DEBUG_INFO("VAR ");
                    DEBUG_INFO(names[i].c_str());
                    DEBUG_INFO("\n");
                    if(isVar[i]){
                        Value *var = AI;
                        getFuncContext()->insertName(names[i].c_str(), var);
                    } else {
                        AllocaInst *alloca = CreateEntryBlockAlloca(
                            F, names[i].c_str(), args[i]
                        );
                        Builder.CreateStore(AI, alloca);
                    }
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
                TheFPM->run(*F);

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
                Type *type = type_decl->genCode().getType();
                Function *F = Builder.GetInsertBlock()->getParent();
                for (auto name: name_list->child) {
                    if (isGlobal) {
                        GlobalVariable* gvar = new GlobalVariable(
                            *TheModule,
                            type,
                            false, // is constant
                            GlobalValue::CommonLinkage,
                            NULL, // initializer set later
                            name->attr.symbolName
                        );
                        if(type->isArrayTy() || type->isStructTy()){
                            ConstantAggregateZero* const_array;
                            const_array = ConstantAggregateZero::get(type);
                            gvar->setInitializer(const_array);
                        } else if(type->isIntegerTy()){
                            Constant* const_val;
                            const_val = ConstantInt::get( // initializer
                                TheModule->getContext(),
                                APInt(32, StringRef("0"), 10)
                            ),
                            gvar->setInitializer(const_val);
                        } else {
                            type->dump();
                            yyerror("Unsupported type initialization");
                        }
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
                                return Type::getInt32Ty(getGlobalContext());
                            case TYPE_BOOLEAN:
                                DEBUG_INFO("generated TYPE_BOOLEAN\n");
                                return Type::getInt32Ty(getGlobalContext());
                            case TYPE_REAL:
                                DEBUG_INFO("generated TYPE_REAL\n");
                                return Type::getDoubleTy(getGlobalContext());
                            case TYPE_CHARACTER:
                                DEBUG_INFO("generated TYPE_CHARACTER\n");
                                return Type::getInt8Ty(getGlobalContext());
                            case TYPE_STRING:
                                DEBUG_INFO("generated TYPE_STRING\n");
                                return ArrayType::get(Type::getInt8Ty(getGlobalContext()), 256);
                            default: yyerror("Undefined sys type!");
                        }
                    }
                    case 2: // NAME
                        DEBUG_INFO("generating NAME\n");
                        return getName(attr.symbolName);
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

            case ARRAY_TYPE_DECL: {
                //ARRAY  LB  simple_type_decl(child[0])  RB  OF  type_decl(child[1])
                SHOW(ARRAY_TYPE_DECL);
                TreeNode *range    = child[0],
                         *elemType = child[1];
                unsigned sz = range->attr.value.integer;
                Type *elemTy = elemType->genCode().getType();
                ArrayType* ArrayTy;
                ASSERT(ArrayTy = ArrayType::get(elemTy, sz));
                return ArrayTy;
            }

            case RECORD_TYPE_DECL: {
                SHOW(RECORD_TYPE_DECL);
                //RECORD  field_decl_list($0)  END
                //child = {field_decl1, field_decl2, ...}
                int id = 0;
                vector<Type *> fields;
                map<string, int> &fieldID = globalFuncContext->recType[attr.symbolName];
                for (auto field: child){
                    //name_list($0)  COLON  type_decl($1)  SEMI
                    TreeNode *name_list = field->child[0],
                             *type_decl = field->child[1];
                    Type *ty = type_decl->genCode().getType();
                    for (auto name: name_list->child) {
                        fields.push_back(ty);
                        fieldID[name->attr.symbolName] = id++;
                    }
                }
                StructType *StructTy = TheModule->getTypeByName(attr.symbolName);
                ASSERT(!StructTy);

                sprintf(buf, "New struct %s!\n", attr.symbolName);
                DEBUG_INFO(buf);

                ASSERT(StructTy = StructType::create(TheModule->getContext(), attr.symbolName));
                StructTy->setBody(fields, /*isPacked=*/false);
                return StructTy;
            }


            case ASSIGN_STMT: {
                SHOW(ASSIGN_STMT);
                TreeNode *exprVal = child[0];
                Value *var = getName(attr.symbolName).getValue();
                Value *val = exprVal->genCode().getValue();
                switch (derivation) {
                    case 1: {
                        DEBUG_INFO("name := exp\n");
                        // NAME ASSIGN expression($0)
                        Type *ty = var->getType();
                        if (ty->isPointerTy() && ty->getPointerElementType()->isArrayTy()) {
                            vector<Value*> ptr_params;
                            ptr_params.push_back(genElemPointer(var, genPrintf.const_int32_0));
                            ptr_params.push_back(val);
                            Builder.CreateCall(
                                TheModule->getFunction("strcpy"),
                                ptr_params
                            );
                        } else Builder.CreateStore(val, var);
                        return var;
                    }
                    case 2: {
                        DEBUG_INFO("name[exp] := exp\n");
                        // NAME LB expression RB ASSIGN expression($0)
                        TreeNode *exprIdx = child[1];
                        ASSERT(var->getType()->isPointerTy());
                        Value *ptr = genElemPointer(var, exprIdx->genCode().getValue());
                        Builder.CreateStore(val, ptr);
                        return ptr;
                    }
                    case 3: {
                        DEBUG_INFO("name.name := exp\n");
                        // NAME  DOT  NAME($1)  ASSIGN  expression($0)
                        TreeNode *expr  = child[0],
                                 *field = child[1];
                        Value *ptr = getRecFieldPointer(var, field->attr.symbolName);
                        Builder.CreateStore(val, ptr);
                        return ptr;
                    }
                    default: yyerror("ASSIGN_STMT not found!");
                }
            }

            case FOR_STMT: {
                //FOR  NAME  ASSIGN  expression($0)  direction($1)  expression($2)  DO stmt($3)
                TreeNode *initVal   = child[0],
                         *direction = child[1],
                         *stopVal   = child[2],
                         *stmt      = child[3];
                Value *var = getName(attr.symbolName).getValue();
                Builder.CreateStore(initVal->genCode().getValue(), var);
                Value *stop = stopVal->genCode().getValue();

                Function *F = Builder.GetInsertBlock()->getParent();
                BasicBlock *CondBB = BasicBlock::Create(getGlobalContext(), "for_cond", F);
                BasicBlock *BodyBB = BasicBlock::Create(getGlobalContext(), "for_body");
                BasicBlock *ContBB = BasicBlock::Create(getGlobalContext(), "for_cont");

                Builder.CreateBr(CondBB);
                Builder.SetInsertPoint(CondBB);
                Value *CondV, *varVal = Builder.CreateLoad(var);
                bool up;
                switch(direction->derivation) {
                    case 1: //TO
                        CondV = Builder.CreateICmpSLE(varVal, stop);
                        up = 1;
                        break;
                    case 2: //DOWNTO
                        CondV = Builder.CreateICmpSGE(varVal, stop);
                        up = 0;
                        break;
                    default:
                        sprintf(buf, "Invalid direction->derivation: %d\n", direction->derivation);
                        yyerror(buf);
                }
                Builder.CreateCondBr(CondV, BodyBB, ContBB);

                F->getBasicBlockList().push_back(BodyBB);
                Builder.SetInsertPoint(BodyBB);
                stmt->genCode();
                Value *const_1 = ConstantInt::get(
                        getGlobalContext(),
                        APInt(32, 1, true)
                );
                varVal = Builder.CreateLoad(var);
                if (up) {
                    Value *nextVal = Builder.CreateAdd(varVal, const_1);
                    Builder.CreateStore(nextVal, var);
                } else {
                    Value *nextVal = Builder.CreateSub(varVal, const_1);
                    Builder.CreateStore(nextVal, var);
                }
                Builder.CreateBr(CondBB);
                BodyBB = Builder.GetInsertBlock();

                F->getBasicBlockList().push_back(ContBB);
                Builder.SetInsertPoint(ContBB);

                return Code();
            }

            case WHILE_STMT: {
                //WHILE  expression($0)  DO stmt($1)
                TreeNode *cond = child[0],
                         *stmt = child[1];

                Function *F = Builder.GetInsertBlock()->getParent();
                BasicBlock *CondBB = BasicBlock::Create(getGlobalContext(), "while_cond", F);
                BasicBlock *BodyBB = BasicBlock::Create(getGlobalContext(), "while_body");
                BasicBlock *ContBB = BasicBlock::Create(getGlobalContext(), "while_cont");

                Builder.CreateBr(CondBB);
                Builder.SetInsertPoint(CondBB);
                Value *CondV = cond->genCode().getValue();
                if (CondV->getType()->isPointerTy()) {
                    CondV = Builder.CreateLoad(CondV);
                }
                Builder.CreateCondBr(CondV, BodyBB, ContBB);

                F->getBasicBlockList().push_back(BodyBB);
                Builder.SetInsertPoint(BodyBB);
                stmt->genCode();
                Builder.CreateBr(CondBB);
                BodyBB = Builder.GetInsertBlock();

                F->getBasicBlockList().push_back(ContBB);
                Builder.SetInsertPoint(ContBB);

                return Code();
            }

            case REPEAT_STMT: {
                //REPEAT  stmt_list($0)  UNTIL  expression($1)
                TreeNode *cond = child[1],
                         *stmt = child[0];

                Function *F = Builder.GetInsertBlock()->getParent();
                BasicBlock *BodyBB = BasicBlock::Create(getGlobalContext(), "repeat_body", F);
                BasicBlock *ContBB = BasicBlock::Create(getGlobalContext(), "repeat_cont");

                Builder.CreateBr(BodyBB);
                Builder.SetInsertPoint(BodyBB);
                stmt->genCode();
                Value *CondV = cond->genCode().getValue();
                if (CondV->getType()->isPointerTy()) {
                    CondV = Builder.CreateLoad(CondV);
                }
                Builder.CreateCondBr(CondV, ContBB, BodyBB);
                BodyBB = Builder.GetInsertBlock();

                F->getBasicBlockList().push_back(ContBB);
                Builder.SetInsertPoint(ContBB);

                return Code();
            }

            case CASE_STMT: {
                // CASE expression($0) OF case_expr_list($1)  END
                SHOW(CASE_STMT);
                TreeNode *expr      = child[0],
                         *case_list = child[1];

                BasicBlock *ContBB = BasicBlock::Create(getGlobalContext(), "switch_cont");
                SwitchInst* swi = Builder.CreateSwitch(
                    expr->genCode().getValue(),
                    ContBB,
                    case_list->child.size()
                );
                Function *F = Builder.GetInsertBlock()->getParent();
                for (auto cs: case_list->child) {
                    BasicBlock *CaseBB = BasicBlock::Create(getGlobalContext(), "case");
                    F->getBasicBlockList().push_back(CaseBB);
                    Value *val;
                    switch(cs->derivation) {
                        case 1: val = cs->child[0]->genCode().getValue(); break;
                        case 2: val = getName(cs->child[0]->attr.symbolName).getValue(); break;
                        default: ASSERT(0 && "case_list->derivation not found");
                    }
                    ConstantInt *const_int;
                    ASSERT(const_int = dynamic_cast<ConstantInt *>(val));
                    swi->addCase(const_int, CaseBB);
                    Builder.SetInsertPoint(CaseBB);
                    cs->child[1]->genCode();
                    Builder.CreateBr(ContBB);
                }
                F->getBasicBlockList().push_back(ContBB);
                Builder.SetInsertPoint(ContBB);
                return Code();
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
                    ASSERT(!args.empty());
                    Type *ty = args[0]->getType();
                    if (ty->isIntegerTy()) {
                        args.insert(args.begin(), genPrintf.const_ptr);
                    } else if (ty->isFloatingPointTy()) {
                        args.insert(args.begin(), genPrintf.const_ptr_f);
                    } else if (ty->isPointerTy()){
                        args.insert(args.begin(), genPrintf.const_ptr_s);
                    } else {
                        ty->dump();
                        yyerror("unsupported writeln type");
                    }

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
            case TYPE_DECL_LIST: SHOW(TYPE_DECL_LIST);
            case CONST_EXPR_LIST: SHOW(CONST_EXPR_LIST);
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
                        return ConstantInt::get(
                                getGlobalContext(),
                                APInt(32, attr.value.integer, true)
                        );
                    case TYPE_REAL:
                        SHOW(TYPE_REAL);
                        return ConstantFP::get(
                            getGlobalContext(),
                            APFloat(attr.value.real)
                        );
                    case TYPE_STRING: {
                        SHOW(TYPE_STRING);
                        Constant *const_arr = ConstantDataArray::getString(
                            TheModule->getContext(),
                            attr.symbolName,
                            true
                        );
                        ArrayType* ArrayTy = ArrayType::get(
                            IntegerType::get(TheModule->getContext(), 8),
                            strlen(attr.symbolName)+1
                        );
                        GlobalVariable *gvar_arr = new GlobalVariable(
                            /*Module=*/*TheModule,
                            /*Type=*/ArrayTy,
                            /*isConstant=*/true,
                            /*Linkage=*/GlobalValue::PrivateLinkage,
                            /*Initializer=*/const_arr
                        );
                        gvar_arr->setAlignment(1);
                        return genElemPointer(
                            gvar_arr,
                            ConstantInt::get(
                                TheModule->getContext(),
                                APInt(32, StringRef("0"), 10)
                            )
                        );
                    }
                    default:
                        sprintf(buf, "Not implemented Symbol Type %d\n", symbolType);
                        yyerror(buf);
                }
            }
            case NAMEKIND: {
                SHOW(NAMEKIND);
                Value *name = getName(attr.symbolName).getValue();
                switch(derivation){
                    case 1: { //NAME
                        Type *ty = name->getType();
                        if (ty->isPointerTy() && !ty->getPointerElementType()->isArrayTy()) {
                            name = Builder.CreateLoad(name, attr.symbolName);
                        }
                        return name;
                    }
                    case 9: //NAME LB expression($0) RB
                        return Builder.CreateLoad(
                            genElemPointer(name, child[0]->genCode().getValue()),
                            attr.symbolName
                        );
                    case 10: // NAME  DOT  NAME($0)
                        return Builder.CreateLoad(
                            getRecFieldPointer(
                                name,
                                child[0]->attr.symbolName
                            )
                        );
                    default:
                        sprintf(buf, "Not implemented derivation %d for NAMEKIND", derivation);
                        yyerror(buf);
                }
            }
            case OPKIND:
                Value *lval, *rval;
                ASSERT(lval = child[0]->genCode().getValue());
                ASSERT(rval = child[1]->genCode().getValue());
                if(lval->getType()->isIntegerTy()){
                    switch (attr.op) {
                        case OP_EQUAL: SHOW(OP_EQUAL);
                            return Builder.CreateICmpEQ(lval, rval);
                        case OP_PLUS: SHOW(OP_PLUS);
                            return Builder.CreateAdd(lval, rval);
                        case OP_MINUS: SHOW(OP_MINUS);
                            return Builder.CreateSub(lval, rval);
                        case OP_MUL: SHOW(OP_MUL);
                            return Builder.CreateMul(lval, rval);
                        case OP_GT: SHOW(OP_GT);
                            return Builder.CreateICmpSGT(lval, rval);
                        case OP_MOD: SHOW(OP_MOD);
                            return Builder.CreateSRem(lval, rval);
                        case OP_DIV: SHOW(OP_DIV);
                            return Builder.CreateSDiv(lval, rval);
                        case OP_LT: SHOW(OP_LT);
                            return Builder.CreateICmpSLT(lval, rval);
                        case OP_GE: SHOW(OP_GE);
                            return Builder.CreateICmpSGE(lval, rval);
                        default:
                            sprintf(buf, "OPKIND %d not implemented!", attr.op);
                            yyerror(buf);
                    }
                } else if(lval->getType()->isFloatingPointTy()){
                    switch (attr.op) {
                        case OP_EQUAL: SHOW(OP_EQUAL);
                            return Builder.CreateFCmpOEQ(lval, rval);
                        case OP_PLUS: SHOW(OP_PLUS);
                            return Builder.CreateFAdd(lval, rval);
                        case OP_MINUS: SHOW(OP_MINUS);
                            return Builder.CreateFSub(lval, rval);
                        case OP_MUL: SHOW(OP_MUL);
                            return Builder.CreateFMul(lval, rval);
                        case OP_GT: SHOW(OP_GT);
                            return Builder.CreateFCmpOGT(lval, rval);
                        case OP_DIV: SHOW(OP_DIV);
                            return Builder.CreateFDiv(lval, rval);
                        case OP_LT: SHOW(OP_LT);
                            return Builder.CreateFCmpOLT(lval, rval);
                        case OP_GE: SHOW(OP_GE);
                            return Builder.CreateFCmpOGE(lval, rval);
                        default:
                            sprintf(buf, "OPKIND %d not implemented!", attr.op);
                            yyerror(buf);
                    }
                } else {
                    lval->getType()->dump();
                    yyerror("unsupported lvalue type!\n");
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

                vector<Value *> args = genArgsList(args_list, true);
                ASSERT(args.size() == CalleeF->arg_size());
                auto AI = CalleeF->arg_begin();
                for (int i = 0; i < args.size(); ++i, ++AI) {
                    if (!AI->getType()->isPointerTy()
                            && args[i]->getType()->isPointerTy()) {
                        args[i] = Builder.CreateLoad(args[i]);
                    }
                    ASSERT(args[i]->getType() == AI->getType());
                }

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

Value *genArg(TreeNode *arg, bool enableVar=0){
    Value *val = arg->genCode().getValue();
    if (enableVar && arg->nodeKind == EXPKIND && arg->kind.expKind == NAMEKIND) {
        LoadInst *inst = dynamic_cast<LoadInst *>(val);
        if (inst) return inst->getPointerOperand();
    }
    return val;
}

vector<Value *> genArgsList(TreeNode *argsList, bool enableVar){
    vector<Value *> args;
    for(auto ch: argsList->child){
        args.push_back(genArg(ch, enableVar));
    }
    return args;
}

void Printf::init(){
    const_array = ConstantDataArray::getString(TheModule->getContext(), "%d\x0A", true);
    const_array_f = ConstantDataArray::getString(TheModule->getContext(), "%f\x0A", true);
    const_array_s = ConstantDataArray::getString(TheModule->getContext(), "%s\x0A", true);
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
    gvar_array__str_f = new GlobalVariable(
        /*Module=*/*TheModule,
        /*Type=*/ArrayTy,
        /*isConstant=*/true,
        /*Linkage=*/GlobalValue::PrivateLinkage,
        /*Initializer=*/const_array_f,
        /*Name=*/".str_f"
    );
    gvar_array__str_f->setAlignment(1);
    gvar_array__str_s = new GlobalVariable(
        /*Module=*/*TheModule,
        /*Type=*/ArrayTy,
        /*isConstant=*/true,
        /*Linkage=*/GlobalValue::PrivateLinkage,
        /*Initializer=*/const_array_s,
        /*Name=*/".str_s"
    );
    gvar_array__str_s->setAlignment(1);
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

    PointerType* PointerTy_6 = PointerType::get(
        IntegerType::get(TheModule->getContext(), 8),
        0
    );

    std::vector<Type*>FuncTy_8_args;
    FuncTy_8_args.push_back(PointerTy_6);
    FuncTy_8_args.push_back(PointerTy_6);
    FunctionType* FuncTy_8 = FunctionType::get(
     /*Result=*/PointerTy_6,
     /*Params=*/FuncTy_8_args,
     /*isVarArg=*/false
    );

    Function* func_strcpy = TheModule->getFunction("strcpy");
    if (!func_strcpy) {
        func_strcpy = Function::Create(
            /*Type=*/FuncTy_8,
            /*Linkage=*/GlobalValue::ExternalLinkage,
            /*Name=*/"strcpy", TheModule); // (external, no body)
            func_strcpy->setCallingConv(CallingConv::C);
    }
    AttributeSet func_strcpy_PAL;
    {
        SmallVector<AttributeSet, 4> Attrs;
        AttributeSet PAS;
        {
            AttrBuilder B;
            B.addAttribute(Attribute::NoUnwind);
            PAS = AttributeSet::get(TheModule->getContext(), ~0U, B);
        }
        Attrs.push_back(PAS);
        func_strcpy_PAL = AttributeSet::get(TheModule->getContext(), Attrs);
    }
    func_strcpy->setAttributes(func_strcpy_PAL);

    std::vector<Constant*> const_ptr_indices;
    const_int32_0 = ConstantInt::get(TheModule->getContext(), APInt(32, StringRef("0"), 10));
    const_ptr_indices.push_back(const_int32_0);
    const_ptr_indices.push_back(const_int32_0);
    const_ptr = ConstantExpr::getGetElementPtr(gvar_array__str, const_ptr_indices);
    const_ptr_f = ConstantExpr::getGetElementPtr(gvar_array__str_f, const_ptr_indices);
    const_ptr_s = ConstantExpr::getGetElementPtr(gvar_array__str_s, const_ptr_indices);
}

Value *genElemPointer(Value *name, Value *offset){
    ConstantInt* const_int32_0 = ConstantInt::get(
        TheModule->getContext(), APInt(32, StringRef("0"), 10));
    //CastInst* int64_17 = new SExtInst(int32_16, IntegerType::get(mod->getContext(), 64), "", label_13);
    std::vector<Value*> ptr_indices;
    ptr_indices.push_back(const_int32_0);
    if (offset->getType()->isPointerTy()) offset = Builder.CreateLoad(offset);
    ptr_indices.push_back(offset);
    Value* ptr;
    ASSERT(ptr = Builder.CreateGEP(name, ptr_indices));
    return ptr;
}

Value *getRecFieldPointer(Value *var, const char *field){
    ASSERT(var->getType()->isPointerTy());
    Type *recType = var->getType()->getPointerElementType();
    const char *typeName = recType->getStructName().data();
    int fieldID = globalFuncContext->recType[typeName][field];
    Value *const_id = ConstantInt::get(
        getGlobalContext(),
        APInt(32, fieldID, true)
    );
    return genElemPointer(var, const_id);
}

Printf genPrintf;

void init_sys_func(){
    genPrintf.init();
}
