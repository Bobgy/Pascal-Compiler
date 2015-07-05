LEX_TARGET := lex.yy
YACC_TARGET := y.tab
COP := -std=c99

all: $(YACC_TARGET).out

$(YACC_TARGET).out: $(YACC_TARGET).o $(LEX_TARGET).o util.o main.o
	gcc -o $(YACC_TARGET).out $(LEX_TARGET).o $(YACC_TARGET).o util.o main.o

$(LEX_TARGET).c: pascal.l
	flex pascal.l

$(LEX_TARGET).o: $(LEX_TARGET).c $(YACC_TARGET).c $(YACC_TARGET).h
	gcc $(COP) -c $(LEX_TARGET).c

$(YACC_TARGET).c $(YACC_TARGET).h: pascal.y util.h
	"yacc" -dvt pascal.y

$(YACC_TARGET).o: $(YACC_TARGET).c $(YACC_TARGET).h
	gcc $(COP) -c $(YACC_TARGET).c

util.o: util.c util.h
	gcc $(COP) -c util.c

main.o: main.c global.h
	gcc $(COP) -c main.c

clean_o:
	rm -f *.o

clean_tmp:
	rm -f *~ *.swp *.output

clean_exe:
	rm -f *.out

clean_gen_src:
	rm -f $(YACC_TARGET).c $(LEX_TARGET).c $(YACC_TARGET).h

clean: clean_tmp clean_o clean_exe clean_gen_src

clean_not_src: clean_tmp clean_o clean_exe

utils/$(LEX_TARGET).out: $(LEX_TARGET).o utils/test_lex.c util.o util.h
	gcc $(COP) -c utils/test_lex.c -o utils/test_lex.o
	gcc $(COP) utils/test_lex.o $(LEX_TARGET).o util.o -o utils/$(LEX_TARGET).out

test: utils/$(LEX_TARGET).out
