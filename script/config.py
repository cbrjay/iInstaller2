#!/usr/bin/python
# Filename : install.py
# -*- coding: utf-8 -*-

import ConfigParser

current_path = os.path.dirname(os.path.abspath(__file__))
root_path = os.path.abspath( os.path.join(current_path, os.pardir))

cp=ConfigParser.ConfigParser()
cp.read(os.path.join(current_path,"install.conf"))

home = cp.get("sysenv","home")
	
cs = Choose()
it = InstallConf()

os.system('clear')
print "ENV:", os.environ["INTEGRATOR_HOME"]

def chooseConf(var):
	if var == 1:
		return u'[X]'
	else:
		return u'[ ]'
		
def installConf(var):
	if var == 0:
		return '[ Installed ]'
	else:
		return '[Uninstalled]'
		
def setChoose(val):
	val = int(math.fabs(int(val)-1))
	return val

