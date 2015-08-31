#include "global.h"
#include "util.h"

Code TreeNode::genCode() {
    if (nodeKind == STMTKIND) {
        switch(kind.stmtType) {
            //PROGRAM NAME SEMI
            case PROGRAM_HEAD:
            //PROCEDURE  NAME  parameters($0)
            case PROCEDURE_HEAD:
            //FUNCTION  NAME  parameters($0)  COLON  simple_type_decl($1)
            case FUNCTION_HEAD: {
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

                // check whether F is conflicting existing functions
                if (F->getName() != attr.symbolName) {
                    sprintf(buf, "Redeclaration of function \"%s\"\n", attr.symbolName);
                    yyerror(buf);
                }

                auto AI = F->arg_begin();
                for (auto &name: names) {
                    AI->setName(name);
                    ++AI;
                }

                // Create a new basic block to start insertion into.
                BasicBlock *BB = BasicBlock::Create(getGlobalContext(), "entry", F);
                Builder.SetInsertPoint(BB);

                // Create an alloca for each argument and register the argument
                // in the symbol table so that references to it will succeed.
                AI = F->arg_begin();
                for (unsigned i=0; i < args.size(); ++i, ++AI) {
                    // Create an alloca for this variable.
                    IRBuilder<> tmp(&F->getEntryBlock(), F->getEntryBlock().begin());
                    AllocaInst *alloca = tmp.CreateAlloca(args[i], 0, names[i].c_str());

                    // Store the initial value into the alloca.
                    Builder.CreateStore(AI, alloca);

                    // Add arguments to variable symbol table.
                    getFuncContext()->insertName(names[i], alloca);
                }

                /* TODO: finish function implementation
                if (Value *RetVal = Body->Codegen()) {
                    // Finish off the function.
                    Builder.CreateRet(RetVal);

                    // Validate the generated code, checking for consistency.
                    verifyFunction(*TheFunction);

                    // Optimize the function.
                    TheFPM->run(*TheFunction);

                    return TheFunction;
                }
                */
                return Code(F);
            }

            case VAR_DECL: {
                //$$->child = {name_list, type_decl}
                DEBUG_INFO("generating VAR_DECL\n");
                TreeNode *name_list = child[0],
                         *type_decl = child[1];
                Code type = type_decl->genCode();
                Function *F = Builder.GetInsertBlock()->getParent();
                for (auto name: name_list->child) {
                    AllocaInst *alloca = CreateEntryBlockAlloca(
                        F, name->attr.symbolName, type
                    );
                    getFuncContext()->insertName(name->attr.symbolName, get<Value>(alloca));
                }
                return Code();
            }

            case SIMPLE_TYPE_DECL: {
                DEBUG_INFO("generating SIMPLE_TYPE_DECL\n");
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
                switch (derivation) {
                    // NAME ASSIGN expression($0)
                    case 1: {
                        TreeNode *expression = child[0];
                        Value *val = expression->genCode().getValue();
                        Value *var = getFuncContext()->getName(attr.symbolName).getValue();
                        Builder.CreateStore(val, var);
                        return Code(val);
                    }
                    default: yyerror("ASSIGN_STMT not found!");
                }
            }

            default: yyerror("Unrecorded statement type");
        }
    } else {
        assert(nodeKind == EXPKIND);
        /*
         *  typedef enum {
         *      OPKIND, CONSTKIND, IDKIND, FUNCKIND, ARRAYKIND, RECORDKIND
         *  } ExpKind;
         *
         */
        switch(kind.expKind) {
            case CONSTKIND: {
                DEBUG_INFO("generating CONSTKIND\n");
                //TYPE_VOID, TYPE_INTEGER, TYPE_BOOLEAN,
                //TYPE_REAL, TYPE_CHARACTER, TYPE_STRING
                switch(symbolType) {
                    case TYPE_INTEGER:
                        DEBUG_INFO("generating INTEGER\n");
                        return Code(
                            ConstantInt::get(
                                getGlobalContext(),
                                APInt(32, attr.value.integer, true)
                            )
                        );
                    default: yyerror("Unrecorded symbol type");
                }
            }
            case NAMEKIND:
                DEBUG_INFO("generating from NAME\n");
                return getName(child[0]->attr.symbolName);
            case OPKIND:
                switch (attr.op) {
                    default: yyerror("OPKIND not implemented!");
                }

            default: yyerror("Unrecorded expression type");
        }
    }
    yyerror("No code generated");
    return Code();
}
