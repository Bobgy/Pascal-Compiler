#include "util.h"
vector<Value *> genArgsList(TreeNode *argsList, bool enableVar=0);
void init_sys_func();
class Printf{
private:
    Constant *const_array;
    GlobalVariable* gvar_array__str;
    Constant* const_ptr_to_str;
    ConstantInt* const_int32_0;
public:
    Constant* const_ptr;
    void init();
};

extern Printf genPrintf;
