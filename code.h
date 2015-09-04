#include "util.h"
vector<Value *> genArgsList(TreeNode *argsList, bool enableVar=0);
Value *genElemPointer(Value *name, Value *offset);
void init_sys_func();
class Printf{
private:
    Constant *const_array, *const_array_f;
    GlobalVariable *gvar_array__str, *gvar_array__str_f;
    ConstantInt *const_int32_0;
public:
    Constant *const_ptr, *const_ptr_f;
    void init();
};

extern Printf genPrintf;
