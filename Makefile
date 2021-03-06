LEX_TARGET := lex.yy
YACC_TARGET := y.tab
COMMON_HEADER := global.h util.h code.h
CC := clang++-3.6
LLVM_C_OP := `llvm-config-3.6 --cxxflags`
LLVM_LD_OP := `llvm-config-3.6 --ldflags --system-libs --libs core mcjit native`
NO_WARNING := -Wno-write-strings -Wno-deprecated-register
COP := -std=c++11 $(LLVM_C_OP) -O3 $(NO_WARNING)

OBJS := main.o util.o code.o

all: $(YACC_TARGET).out test

$(YACC_TARGET).out: $(YACC_TARGET).o $(LEX_TARGET).o $(OBJS)
	$(CC) -o $(YACC_TARGET).out $(LEX_TARGET).o $(YACC_TARGET).o $(OBJS) $(LLVM_LD_OP)

$(LEX_TARGET).cc: pascal.l
	flex pascal.l && mv $(LEX_TARGET).c $(LEX_TARGET).cc

$(LEX_TARGET).o: $(LEX_TARGET).cc $(YACC_TARGET).h $(COMMON_HEADER)
	$(CC) $(COP) -c $(LEX_TARGET).cc

$(YACC_TARGET).cc $(YACC_TARGET).h: pascal.y $(COMMON_HEADER)
	"yacc" -ydvt pascal.y && mv $(YACC_TARGET).c $(YACC_TARGET).cc

$(YACC_TARGET).o: $(YACC_TARGET).cc $(YACC_TARGET).h $(COMMON_HEADER)
	$(CC) $(COP) -c $(YACC_TARGET).cc

%.o: %.cc $(COMMON_HEADER)
	$(CC) $(COP) -c $< -o $@

clean_o:
	rm -f *.o

clean_tmp:
	rm -f *~ *.swp *.output

clean_exe:
	rm -f *.out

clean_gen_src:
	rm -f $(YACC_TARGET).cc $(LEX_TARGET).cc $(YACC_TARGET).h

clean: clean_tmp clean_o clean_exe clean_gen_src

clean_not_src: clean_tmp clean_o clean_exe

utils/$(LEX_TARGET).out: $(LEX_TARGET).o utils/test_lex.cc util.o $(COMMON_HEADER)
	$(CC) $(COP) -c utils/test_lex.cc -o utils/test_lex.o
	$(CC) -o utils/$(LEX_TARGET).out utils/test_lex.o $(LEX_TARGET).o util.o $(LLVM_LD_OP)

test: utils/$(LEX_TARGET).out
