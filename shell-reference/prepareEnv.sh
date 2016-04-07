#!/bin/bash

# set Integrator root path
if [ -z $INTEGRATOR_HOME ]; then
	INTEGRATOR_HOME=$(dirname ${PWD})
fi

ask_for_continue(){
	read -n1 -p "Press y or <ENTER> to continue, or n to exit :(y/n) " continue
	if [ ! -n "$continue" ]
		then clear && echo next
	elif [ "$continue" == "y" ]
		then clear && echo next
	elif [ "$continue" == "n" ]
		then echo && echo "The Installation will be cancelled..." && exit
	else 
		clear && ask_for_continue
	fi
}

installjdk(){
	tar zxvf $COMPONENT_PATH/jdk.tar.gz -C $INTEGRATOR_HOME/
	chmod 755 $INTEGRATOR_HOME/jdk -R
}

echo "Integrator will be install to path : "$INTEGRATOR_HOME
ask_for_continue

installjdk

mkdir -pv $INTEGRATOR_HOME/bin

cat > $INTEGRATOR_HOME/bin/setEnv.sh << EOF
#!/bin/bash

export INTEGRATOR_HOME=$INTEGRATOR_HOME
echo -n "Setting environment variable <JAVA_HOME>: "
export JAVA_HOME=${INTEGRATOR_HOME}/jdk
echo \$JAVA_HOME
echo "Adding <JAVA_HOME> PATH... "
export PATH=\$JAVA_HOME/bin:\$PATH
echo "Adding <JAVA_HOME> CLASSPATH... "
export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
EOF

clear
source $INTEGRATOR_HOME/bin/setEnv.sh
echo "Setup Integrator Environment finished!"
read -n1 -r -s -p "Pless any key to continue..."
echo "Install JDK finished!"
#echo $JAVA_HOME
#echo $PATH
#echo $CLASSPATH


