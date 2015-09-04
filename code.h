#include "util.h"
vector<Value *> genArgsList(TreeNode *argsList, bool enableVar=0);
Value *genElemPointer(Value *name, Value *offset);
Value *getRecFieldPointer(Value *var, const char *field);
void init_sys_func();
class Printf{
private:
    Constant *const_array, *const_array_f, *const_array_s;
    GlobalVariable *gvar_array__str, *gvar_array__str_f, *gvar_array__str_s;
public:
    Constant *const_ptr, *const_ptr_f, *const_ptr_s;
    ConstantInt *const_int32_0;
    void init();
};

extern Printf genPrintf;
