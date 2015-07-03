TARGET := t2

all: $(TARGET).out $(TARGET).ll

$(TARGET).ll: $(TARGET).c
	clang -emit-llvm $(TARGET).c -S

$(TARGET).bc: $(TARGET).c
	clang -emit-llvm $(TARGET).c -c

$(TARGET).s: $(TARGET).bc
	llc $(TARGET).bc

$(TARGET).out: $(TARGET).s
	gcc $(TARGET).s -o $(TARGET).out

clean:
	rm -f *.s *.o *.ll *.bc *.out
