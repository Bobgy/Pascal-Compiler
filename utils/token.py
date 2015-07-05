#!/usr/bin/python
import sys
D = {}
with open(sys.argv[1], 'r') as dic:
    for line in dic:
        str = line.split()
        if len(str)==3 and str[0] == '#define':
            D[str[1]]=str[2]
            D[str[2]]=str[1]
cnt = 0
while True:
    try:
        token = D[raw_input()]
        print token,
        cnt += 1
        if token == 'SEMI':
            print
    except:
        print
        break
