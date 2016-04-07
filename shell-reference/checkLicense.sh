#!/bin/bash

LicenseFile=$INTEGRATOR_HOME/config/license.properties
publickeyFile=$INTEGRATOR_HOME/config/public.key
LicenseFileName=license.properties

checkLicenseFile(){
	read LicensePath
	last=${LicensePath: -18}
	if [ "x$last" != "x$LicenseFileName" ]; then
		echo "The license file is validated, please enter the full path of license file:"
		checkLicenseFile
	else
		echo "Checking public.key..."
		publickeyPath=${LicensePath/$LicenseFileName/public.key}
		echo "Checking "$publickeyPath
		if [  ! -f "$publickeyPath" ]; then
			echo "Cound not found the corresponding public.key, please check again!"
			exit 1
		else
			ConfigFolder=$(dirname ${LicenseFile})
			if [ ! -f "$ConfigFolder" ]; then
				echo "Config folder <$ConfigFolder> is not exsit, will create automatically..."
				mkdir -pv $ConfigFolder
			fi
			echo "Copy license file to config folder..."
			cp -ipv $LicensePath $LicenseFile
			cp -ipv $publickeyPath $publickeyFile
		fi
	fi
}

if [ ! -f "$LicenseFile" ]; then
	echo
	echo "Cound not found Integrator license file!"
	current_path=$PWD
	cd $SETUP_BASE/tool
	echo -n "MAC Address: "
	java ServerInfoUtils
	cd $current_path
	echo "Please enter the full path of license file:"
	checkLicenseFile
else
	echo
	echo "Exsting license file, install continue..."
fi
