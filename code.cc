#include "global.h"
#include "util.h"

Code TreeNode::genCode() {
    if (nodeKind == STMTKIND) {
        switch(kind.stmtType) {
            //FUNCTION  NAME  parameters  COLON  simple_type_decl
            case FUNCTION_HEAD: {
                // Make the function type:  double(double,double) etc.
                /*std::vector<Type*> funcType(Args.size(),
                                             Type::getDoubleTy(getGlobalContext()));
                FunctionType *FT = FunctionType::get(Type::getDoubleTy(getGlobalContext()),
                                                       Doubles, false);
                Function *F = Function::Create(FT, Function::ExternalLinkage, Name, TheModule);
                */
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
            default: yyerror("Unrecorded statement type");
        }
    } else {
        assert(nodeKind == EXPKIND);
        /*
         *  typedef enum {
         *  	OPKIND, CONSTKIND, IDKIND, FUNCKIND, ARRAYKIND, RECORDKIND
         *  } ExpKind;
         *
         */
        switch(kind.expKind) {
            case CONSTKIND: {
                DEBUG_INFO("generating CONSTKIND");
                //TYPE_VOID, TYPE_INTEGER, TYPE_BOOLEAN,
                //TYPE_REAL, TYPE_CHARACTER, TYPE_STRING
                switch(symbolType) {
                    case TYPE_INTEGER:
                        DEBUG_INFO("generating INTEGER");
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
                DEBUG_INFO("generating from NAME");
                return getName(child[0]->attr.symbolName);
            default: yyerror("Unrecorded expression type");
        }
    }
    yyerror("No code generated");
    return Code();
}
