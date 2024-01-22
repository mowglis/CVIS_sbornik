#!/usr/bin/env python3
# -*- coding: ISO-8859-2 -*-
"""
vytvoří soubor pro opravu názvů dle vstupních čísel akcí
"""
akce_fmt = lambda x: "-".join([x[0:1],x[1:3],x[3:4],x[4:6]])

akce = []
while True:
	try:
		c_akce = input()
		akce += [c_akce.strip()]
	except EOFError:
		break

for c_akce in akce:
	#print("číslo akce: {} ({})".format(c_akce, akce_fmt(c_akce)))
	f = open('data_'+c_akce[0:3]+'.tex')
	for line in f:
		line = line.strip()
		if akce_fmt(c_akce) in line:
			print(line)
			line = next(f)
			print(line.strip())

