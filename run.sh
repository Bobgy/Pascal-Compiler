#!/bin/sh
echo ============t8=============
./y.tab.out < test/t8/t8.pas || exit
echo =========simple============
./y.tab.out < test/simple/simple.pas || exit
#echo ===========t2==============
#./y.tab.out < test/t2/t2.pas || exit
