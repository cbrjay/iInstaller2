#!/usr/bin/python
# Filename : Install_Conf.py
# -*- coding: utf-8 -*-

import ConfigParser
import os

current_path = os.path.dirname(os.path.abspath(__file__))
root_path = os.path.abspath( os.path.join(current_path, os.pardir))
cp=ConfigParser.ConfigParser()
conf_file = os.path.join(current_path,"install.conf")
cp.read(conf_file)

class Install_Conf():
	jdk = 0
	mysql = 0
	mongodb = 0
	prop = 0
	portal = 0
	dip = 0
	def __init__(self):
		jdk=cp.get("install","jdk")
		mysql=cp.get("install","mysql")
		mongodb=cp.get("install","mongodb")
		prop=cp.get("install","prop")
		portal=cp.get("install","portal")
		dip=cp.get("install","dip")	
	
	def installed(self, key):
		if (key == "jdk"):
			jdk = 1
		elif (key == "mysql"):
			mysql = 1
		elif (key == "mongodb"):
			mongodb = 1
		elif (key == "prop"):
			prop = 1
		elif (key == "portal"):
			portal = 1
		elif (key == "dip"):
			dip = 1
		cp.write(open(conf_file))
	