#include "global.h"
#include "util.h"

Code TreeNode::genCode() {
    Code ret;
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
                switch(derivation) {
                    case 1: { //SYS_TYPE
                        switch(symbolType){
                            //case TYPE_VOID:
                            case TYPE_INTEGER:
                                ret.setType(Type::getInt32Ty(getGlobalContext()));
                                return ret;
                            case TYPE_BOOLEAN:
                                ret.setType(Type::getInt32Ty(getGlobalContext()));
                                return ret;
                            case TYPE_REAL:
                                ret.setType(Type::getDoubleTy(getGlobalContext()));
                                return ret;
                            //case TYPE_CHARACTER:
                            //case TYPE_STRING
                            default: yyerror("Undefined sys type!");
                        }
                    }
                    case 2: { // NAME
                        ret = getName(child[0]->attr.symbolName);
                        return ret;
                    }
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
                //TYPE_VOID, TYPE_INTEGER, TYPE_BOOLEAN,
                //TYPE_REAL, TYPE_CHARACTER, TYPE_STRING
                switch(symbolType) {
                    case TYPE_INTEGER:
                        ret.setValue(ConstantInt::get(
                            getGlobalContext(),
                            APInt(32, attr.value.integer, true)
                        ));
                        return ret;
                    default: yyerror("Unrecorded symbol type");
                }
            }
            default: yyerror("Unrecorded expression type");
        }
    }
    yyerror("No code generated");
    ret.setValue(NULL);
    return ret;
}
