#!/bin/bash

DIRNAME=$0

LEX_TARGET=lex.yy
YACC_TARGET=y.tab

if ["${DIRNAME:0:1}"="/"]; then
    CURDIR=`dirname $DIRNAME`
else
    CURDIR="`pwd`"/"`dirname $DIRNAME`"
fi

$CURDIR/$LEX_TARGET.out < $1 | $CURDIR/token.py $CURDIR/../$YACC_TARGET.h
