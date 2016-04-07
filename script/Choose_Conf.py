#!/usr/bin/python
# Filename : Choose_Conf.py
# -*- coding: utf-8 -*-

import math

class Choose_Conf():
	jdk = 0
	mysql = 0
	mongodb = 0
	prop = 0
	portal = 0
	dip = 0
	
	def __init__(self):
		jdk = 0
		mysql = 0
		mongodb = 0
		prop = 0
		portal = 0
		dip = 0
	
	def choose(self, key):
		if (key == "jdk"):
			self.jdk = int(math.fabs(int(self.jdk)-1))
		elif (key == "mysql"):
			self.mysql = int(math.fabs(int(self.mysql)-1))
		elif (key == "mongodb"):
			self.mongodb = int(math.fabs(int(self.mongodb)-1))
		elif (key == "prop"):
			self.prop = int(math.fabs(int(self.prop)-1))
		elif (key == "portal"):
			self.portal = int(math.fabs(int(self.portal)-1))
		elif (key == "dip"):
			self.dip = int(math.fabs(int(self.dip)-1))
