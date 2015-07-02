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
		print D[raw_input()], 
		cnt += 1
		if cnt % 10 == 0:
			print
	except:
		print
		break