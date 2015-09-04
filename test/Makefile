TARGET := test2.ll test4.ll test5.ll test6.ll test7.ll test8.ll test1.ll

all: $(TARGET)

%.ll: %.pas ../y.tab.out Makefile
	../y.tab.out < $< > $@

clean:
	rm -f *.ll
