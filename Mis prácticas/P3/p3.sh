#!/bin/bash

rm lex.yy.c 2>/dev/null

rm p3 2>/dev/null


lex p3.l

gcc lex.yy.c -o p3 -ll -L/usr/lib/x86_64-linux-gnu -lcurl

./p3 $1 $2