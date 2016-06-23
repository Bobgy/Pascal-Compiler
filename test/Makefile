TARGET := test1.ll test2.ll test3.ll test4.ll test5.ll test6.ll test7.ll test8.ll

all: $(TARGET)

%.ll: %.pas ../y.tab.out Makefile
	@echo -n "Testing $@ -- "
	@../y.tab.out < $< > $@ || rm $@
	@lli-3.6 $@ > tmp || diff tmp $@.ans
	@rm tmp
	@echo "Passed"
	@rm $@

clean:
	rm -f *.ll *~
