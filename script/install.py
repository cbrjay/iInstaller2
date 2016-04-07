#!/usr/bin/python
# Filename : install.py
# -*- coding: utf-8 -*-

import ConfigParser
import os
import sys
import math
import logging
import Choose_Conf
import Install_Conf

current_path = os.path.dirname(os.path.abspath(__file__))
root_path = os.path.abspath(os.path.join(current_path, os.pardir))

logging.basicConfig(level=logging.DEBUG,
          format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s',
          datefmt='%m-%d %H:%M',
          filename='install.log')

console = logging.StreamHandler()
console.setLevel(logging.INFO)
formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
console.setFormatter(formatter)
logging.getLogger('').addHandler(console)

cp=ConfigParser.ConfigParser()
conf_file = os.path.join(current_path,"install.conf")
print conf_file
cp.read(conf_file)
print cp.sections()
home = cp.get("sysenv","home")
print home
cs = Choose_Conf.Choose_Conf()
it = Install_Conf.Install_Conf()
os.system('clear')

def chooseConf(var):
	if var == 1:
		return u'[X]'
	else:
		return u'[ ]'

def installConf(var):
	if var == 0:
		return '[Uninstalled]'
	else:
		return '[ Installed ]'

def printSep():
	print
	print "============================================================"
	print

def printoption():
	print "============================================================"
	print
	print chooseConf(cs.jdk), '[1]. Setup Integrator Environment         ', installConf(it.jdk)
	print
	print chooseConf(cs.mysql), "[2]. Setup MySQL                          ", installConf(it.mysql)
	print
	print chooseConf(cs.mongodb), "[3]. Setup MongoDB                        ", installConf(it.mongodb)
	print
	print chooseConf(cs.prop), "[4]. Create system.properties             ", installConf(it.prop)
	print
	print chooseConf(cs.portal), "[5]. Setup Portal                         ", installConf(it.portal)
	print
	print chooseConf(cs.dip), "[6]. Setup DIP                            ", installConf(it.dip)
	#print
	#print chooseConf(), "[0]. Exit"
	print
	print "     [a]Select All      [n]Continue         [c]Cancel       "
	print "============================================================"
	print
	choose()

def choose():
	key = raw_input("Choose number to install or [n/c]>")
	if (key == '1'):
		os.system('clear')
		if (int(cs.jdk) == 1):
			if (int(cs.portal) == 1):
				cs.choose("portal")
			if (int(cs.dip) == 1):
				cs.choose("dip")
		cs.choose("jdk")
		printoption()
	elif (key == '2'):
		os.system('clear')
		cs.choose("mysql")
		printoption()
	elif (key == '3'):
		os.system('clear')
		cs.choose("mongodb")
		printoption()
	elif (key == '4'):
		os.system('clear')
		cs.choose("prop")
		printoption()
	elif (key == '5'):
		os.system('clear')
		if (int(cs.dip) == 0):
			if (int(it.jdk) == 0 and int(cs.jdk) == 0):
				cs.choose("jdk")
			if (int(it.prop) == 0 and int(cs.prop) == 0):
				cs.choose("prop")
		cs.choose("portal")
		printoption()
	elif (key == '6'):
		os.system('clear')
		if (int(cs.dip) == 0):
			if (int(it.jdk) == 0 and int(cs.jdk) == 0):
				cs.choose("jdk")
			if (int(it.prop) == 0 and int(cs.prop) == 0):
				cs.choose("prop")
		cs.choose("dip")
		printoption()
	elif (key == 'a'):
		os.system('clear')
		cs.jdk = 1
		cs.mysql = 1
		cs.mongodb = 1
		cs.prop = 1
		cs.portal = 1
		cs.dip = 1
		printoption()
	elif (key == 'n'):
		os.system('clear')
	elif (key == 'c'):
		exit()
	else:
		os.system('clear')
		printoption()

def install():
	if (int(cs.jdk) == 1):
		printSep()
		print "Start install JDK..."
	if (int(cs.mysql) == 1):
		printSep()
		print "Start install MySQL..."
	if (int(cs.mongodb) == 1):
		printSep()
		print "Start install MongoDB..."
	if (int(cs.prop) == 1):
		printSep()
		print "Start create System.Properties..."
	if (int(cs.portal) == 1):
		printSep()
		print "Start install Portal..."
	if (int(cs.dip) == 1):
		printSep()
		print "Start install DIP..."
	printSep()

def inputHome():
	global home
	home = raw_input("Enter the folder path to install Integrator:\n>")
	if (not home):
		inputHome()

def prepare_home():
	global home
	if (not home):
		inputHome()
	if (not os.path.exists(home)):
		os.makedirs(home)
	home = os.path.abspath(home)
	if (not home.endswith("integrator") and not home.endswith("Integrator")):
		home = os.path.abspath(os.path.join(home,"integrator"))
	printSep()
	print "Integrator will be install to : [", home, "]"

def install_license():
	global mac
	license_file = raw_input("Enter the full path of license file:\n>")
	if (not license_file):
		install_license()
	elif (not license_file.endswith("license.properties")):
		print "You must enter the FULL PATH of your license file!!!"
		install_license()
	elif (not os.path.exists(license_file)):
		print "Could not found the license file with your input!!!"
		install_license()
	else: 
		public_key_file = license_file.replace("license.properties","public.key")
		if (not os.path.exists(public_key_file)):
			print "Counld not found the corresponding publick.key file, please contact your service provider!!!"
			install_license()
		#elif (not checkMac(license_file)):
			#print "The MAC address could not match license file, please use [", mac, "] and contact your service provider!!!"
			#install_license()
		

def prepare_license():
	installed_license = os.path.abspath(os.path.join(home,"config","license.properties"))
	#check existing license
	if (os.path.exists(installed_license)):
		#if (not checkMac(installed_license)):
			#print "The installed license could not match MAC address, please contact your service provider!"
			#install_license()
		print
	else: 
		install_license()

def prepare_mysql():
	global mysql_root_psw, mysql_admin_psw
	printSep()
	print "To continue install process, setup the password for mysql"
	while (1): 
		mysql_root_psw = raw_input("Enter the password for mysql user <root>, root user will be used to manage mysql running!\nroot>")
		if (not mysql_root_psw):
			print "Password could not be null!!!"
		else: 
			break
	while (1): 
		mysql_admin_psw = raw_input("Enter the password for mysql user <admin>, admin user will be used for connecting!\nadmin>")
		if (not mysql_admin_psw):
			print "Password could not be null!!!"
		else: 
			break

def prepare_mail():
	global email_host, email_account, email_pwd, email_address
	print "If you need to send notification email during Integrator processing, you will need to provide an email account!!!"
	email_host = raw_input("Enter the email host (Press Enter to skip email setting!) >")
	if (email_host):
		while (1): 
			email_account = raw_input("Enter the email account >")
			if (not email_account):
				print "Email Account could not be null!!!"
			else: 
				break
		while (1): 
			email_pwd = raw_input("Enter the email password >")
			if (not email_pwd):
				print "Email Password could not be null!!!"
			else: 
				break
		while (1): 
			email_address = raw_input("Enter the email address to receive exceptions >")
			if (not email_address):
				print "Email Address could not be null!!!"
			else: 
				break
	else: 
		email_account = ""
		email_pwd = ""
		email_address = ""

def prepare():
	prepare_home()
	if (cs.portal or cs.dip):
		prepare_license()
	if (cs.mysql):
		prepare_mysql()
	if (cs.prop):
		prepare_mail()

def main():
	printoption()
	prepare()
	install()

if __name__ == '__main__':
	try:
		main()
	except KeyboardInterrupt: # Ctrl + C on console
		print
		sys.exit

