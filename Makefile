LEX_TARGET := lex.yy
YACC_TARGET := y.tab
COMMON_HEADER := global.h util.h
CC := clang++
LLVM_C_OP := `llvm-config --cxxflags`
LLVM_LD_OP := `llvm-config --ldflags --system-libs --libs core mcjit native`
NO_WARNING := -Wno-write-strings -Wno-deprecated-register
COP := -std=c++11 $(LLVM_C_OP) -O3 $(NO_WARNING)

all: $(YACC_TARGET).out test

$(YACC_TARGET).out: $(YACC_TARGET).o $(LEX_TARGET).o util.o main.o
	$(CC) -o $(YACC_TARGET).out $(LEX_TARGET).o $(YACC_TARGET).o util.o main.o $(LLVM_LD_OP)

$(LEX_TARGET).cc: pascal.l
	flex pascal.l && mv $(LEX_TARGET).c $(LEX_TARGET).cc

$(LEX_TARGET).o: $(LEX_TARGET).cc $(YACC_TARGET).h $(COMMON_HEADER)
	$(CC) $(COP) -c $(LEX_TARGET).cc

$(YACC_TARGET).cc $(YACC_TARGET).h: pascal.y $(COMMON_HEADER)
	"yacc" -ydvt pascal.y && mv $(YACC_TARGET).c $(YACC_TARGET).cc

$(YACC_TARGET).o: $(YACC_TARGET).cc $(YACC_TARGET).h $(COMMON_HEADER)
	$(CC) $(COP) -c $(YACC_TARGET).cc

util.o: util.cc $(COMMON_HEADER)
	$(CC) $(COP) -c util.cc

main.o: main.cc $(COMMON_HEADER)
	$(CC) $(COP) -c main.cc

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
	$(CC) $(COP) utils/test_lex.o $(LEX_TARGET).o util.o -o utils/$(LEX_TARGET).out

test: utils/$(LEX_TARGET).out
