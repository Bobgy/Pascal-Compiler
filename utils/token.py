#!/usr/bin/python
import sys
dic = open(sys.argv[1], 'r')
str = dic.readline().split()
D = {}
while str:
    # print str
    D[str[1]]=str[2]
    D[str[2]]=str[1]
    str=dic.readline().split()
# print D
dic.close()
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
