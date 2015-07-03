LEX_TARGET := lex.yy
YACC_TARGET := y.tab

all: $(YACC_TARGET).out

$(YACC_TARGET).out: $(LEX_TARGET).o $(YACC_TARGET).o util.o main.o
	gcc -o $(YACC_TARGET).out $(LEX_TARGET).o $(YACC_TARGET).o util.o main.o

$(LEX_TARGET).c: pascal.l
	flex pascal.l

$(LEX_TARGET).o: $(LEX_TARGET).c $(YACC_TARGET).c $(YACC_TARGET).h
	gcc -c $(LEX_TARGET).c

$(YACC_TARGET).c $(YACC_TARGET).h: pascal.y util.h
	yacc -dvt pascal.y

$(YACC_TARGET).o: $(YACC_TARGET).c $(YACC_TARGET).h
	gcc -c $(YACC_TARGET).c

util.o: util.c util.h
	gcc -c util.c

main.o: main.c global.h
	gcc -c main.c

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

utils/$(LEX_TARGET).out: $(LEX_TARGET).o utils/test_lex.c
	gcc -c utils/test_lex.c
	gcc test_lex.o $(LEX_TARGET).o -o utils/$(LEX_TARGET).out

test: utils/$(LEX_TARGET).out
