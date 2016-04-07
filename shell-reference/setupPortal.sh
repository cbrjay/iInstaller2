#!/bin/bash

uncompress(){
	tar zxvf $COMPONENT_PATH/tomcat.tar.gz -C $INTEGRATOR_HOME/
	chmod 755 $INTEGRATOR_HOME/tomcat -R
	echo
	echo
	echo
}

if [ -z $INTEGRATOR_HOME ]; then
	echo "Could not determine INTEGRATOR_HOME path, setup will exit!!!"
	echo "Please run 0.prepareEnv.sh first!"
	exit
fi

source $INTEGRATOR_HOME/bin/setEnv.sh
echo "Finish preparing system evnironment!!!"

echo "Checking License file..."
source $SCRIPT_PATH/checkLicense.sh
if [ $? -ne 0 ];then
	echo "License Check Failed! Please check the license file again!!!"
	exit 0
fi

######################### prepare tomcat
echo -n "Preparing Tomcat folder..."
basedir=$INTEGRATOR_HOME/tomcat

uncompress

#######################install intergrator portal
echo "Installing integrator portal to tomcat..."
mkdir -pv $basedir/webapps/integrator/
cp $RESOURCE_PATH/portal/integrator.war $basedir/webapps/integrator/
current_path=$PWD
cd $basedir/webapps/integrator/
jar -xvf integrator.war
rm -f integrator.war
cd $current_path

###########################create start/stop entry###############
echo "Creating Portal start entry file: [/bin/portal/start]......"
mkdir -pv $INTEGRATOR_HOME/bin/portal
cat > $INTEGRATOR_HOME/bin/portal/start << EOF
#!/bin/bash

source $INTEGRATOR_HOME/bin/setEnv.sh

current_path=\$PWD

cd $basedir
./bin/startup.sh
if [ \$? -eq 0 ];then
	echo
	echo "Integrator Portal has been started!!!!"
else
	echo
	echo "Integrator Portal start failed, please check the configuration and try again!"
	echo "If any problem please contact your service provider."
fi
cd \$current_path

echo
read -n1 -p "Do you want to start tailling log, you can quit tailling any time using CTRL+C (y/n)" continue
if [ ! -n "\$continue" ]; then
	tail -f $basedir/logs/catalina.out
elif [ "\$continue" == "y" ]; then
	tail -f $basedir/logs/catalina.out
fi

EOF

echo "Creating Portal stop entry file: [/bin/portal/stop]......"
cat > $INTEGRATOR_HOME/bin/portal/stop << EOF
#!/bin/bash
current_path=\$PWD
cd $basedir
./bin/shutdown.sh
cd \$current_path

EOF

echo "Creating Portal restart entry file: [/bin/portal/restart]......"
cat > $INTEGRATOR_HOME/bin/portal/restart << EOF
#!/bin/bash
. $INTEGRATOR_HOME/bin/portal/stop
sleep 3
. $INTEGRATOR_HOME/bin/portal/start
EOF

###########################Modify Permissions########################
echo "Setting Portal entry file permissions...."
chmod 755 $INTEGRATOR_HOME/bin/portal -R

echo "Integrator Portal has been installed, to start portal, please run $INTEGRATOR_HOME/bin/startPortal.sh"
echo
echo "Start Integrator Portal..."
$basedir/bin/startup.sh
read -n1 -r -s -p "Pless any key to continue..."
