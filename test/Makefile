TARGET := t1/t1.ll t2/t2.ll

all: $(TARGET)

%.ll: %.c
	clang -emit-llvm $< -S -o $@

clean:
	rm -f *.s *.o *.ll *.bc *.out */*.bc */*.ll */*.out */*.s
