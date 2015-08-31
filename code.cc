#include "global.h"
#include "util.h"

#define SHOW(x) {if(!showed){showed=1;DEBUG_INFO(#x"\n");}}

Code TreeNode::genCode() {
    if (nodeKind == STMTKIND) {
        bool showed = 0;
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
                Builder.SetInsertPoint(BB);

                if(isFunction){
                    Value *retVal = CreateEntryBlockAlloca(
                        F, attr.symbolName, retType);
                }

                // Create an alloca for each argument and register the argument
                // in the symbol table so that references to it will succeed.
                AI = F->arg_begin();
                for (unsigned i=0; i < args.size(); ++i, ++AI) {
                    // Create an alloca for this variable.
                    yyinfo("VAR ");
                    yyinfo(names[i].c_str());
                    yyinfo("\n");
                    AllocaInst *alloca = CreateEntryBlockAlloca(
                        F, names[i].c_str(), args[i]
                    );
                }

                return Code(F);
            }


            //program_stmt: program_head  routine  DOT
            case PROGRAM_STMT: SHOW(PROGRAM_STMT);
                //$$->child = {program_head, routine}
            case FUNCTION_DECL: {
                //$$->child = {function_head, sub_routine};
                SHOW(FUNCTION_DECL);
                TreeNode *function_head = child[0],
                         *sub_routine   = child[1];

                pushFuncContext(function_head->attr.symbolName);
                Function *F = function_head->genCode().getFunction();
                sub_routine->genCode();
                if (kind.stmtType==FUNCTION_DECL) {
                    Builder.CreateRet(
                        getName(function_head->attr.symbolName).getValue());
                }

                // finish function implementation
                // Validate the generated code, checking for consistency.
                verifyFunction(*F);

                // Optimize the function.
                // TheFPM->run(*F); TODO

                TheModule->dump();

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
                    AllocaInst *alloca = CreateEntryBlockAlloca(
                        F, name->attr.symbolName, type
                    );
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
                        Value *var = getFuncContext()->getName(attr.symbolName).getValue();
                        Builder.CreateStore(val, var);
                        return Code(val);
                    }
                    default: yyerror("ASSIGN_STMT not found!");
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
                DEBUG_INFO("Ignore unrecorded statement type\n");
                return Code();
            }
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
