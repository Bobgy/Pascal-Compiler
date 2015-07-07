#include "global.h"
#include "util.h"

CodeType TreeNode::genCode() {
    CodeType ret;
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
                        ret.value = ConstantInt::get(
                            getGlobalContext(),
                            APInt(32, attr.value.integer, true)
                        );
                        return ret;
                    default: yyerror("Unrecorded symbol type");
                }
            }
            default: yyerror("Unrecorded expression type");
        }
    }
    yyerror("No code generated");
    ret.value = NULL;
    return ret;
}
