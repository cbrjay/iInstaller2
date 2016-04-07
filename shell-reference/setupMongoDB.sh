#!/bin/bash

uncompressmongo(){
	tar zxvf $COMPONENT_PATH/mongodb.tar.gz -C $INTEGRATOR_HOME/
	chmod 755 $INTEGRATOR_HOME/mongodb -R
	echo
	echo
	echo
}

rotate(){
	INTERVAL=0.5
	RCOUNT="0"
	echo -n 'Processing'
	while true
	do
	    ((RCOUNT = RCOUNT + 1))
	    case $RCOUNT in
	        1) echo -e '-\b\c'
	            sleep $INTERVAL
	            ;;
	        2) echo -e '\\\b\c'
	            sleep $INTERVAL
	            ;;
	        3) echo -e '|\b\c'
	            sleep $INTERVAL
	            ;;
	        4) echo -e '/\b\c'
	            sleep $INTERVAL
	            ;;
	        *) RCOUNT=0
	            ;;
	    esac
	done
}

if [ -z $INTEGRATOR_HOME ]; then
	echo "Could not determine INTEGRATOR_HOME path, setup will exit!!!"
	echo "Please run 0.prepareEnv.sh first!"
	exit
fi

source $INTEGRATOR_HOME/bin/setEnv.sh
echo "Finish preparing system evnironment!!!"

uncompressmongo

######################### create mongodb data folder
echo "Preparing MongoDB folder..."
basedir=$INTEGRATOR_HOME/mongodb
datadir=$INTEGRATOR_HOME/mongodb/data
logdir=$INTEGRATOR_HOME/mongodb/log
echo "DONE"

###########################create start/stop entry###############
mkdir -pv $INTEGRATOR_HOME/bin/mongodb
echo "Creating MongoDB start entry file: [/bin/mongodb/start]......"
cat > $INTEGRATOR_HOME/bin/mongodb/start << EOF
#!/bin/bash

current_path=\$PWD

cd $basedir
./bin/mongod --fork -dbpath $datadir -port 27017 -logpath $logdir/mongodb.log -logappend
if [ \$? -eq 0 ];then
	echo
	echo "Integrator Database MongoDB has been started!!!!"
else
	echo
	echo "Integrator Database MongoDB start failed, please check the configuration and try again!"
	echo "If any problem please contact your service provider."
fi
cd \$current_path
EOF

echo "Creating MongoDB stop entry file: [/bin/mongodb/stop]......"
cat > $INTEGRATOR_HOME/bin/mongodb/stop << EOF
#!/bin/bash
current_path=\$PWD
cd $basedir
./bin/mongod -dbpath $datadir -port 27017 --shutdown
cd \$current_path
EOF

echo "Creating MongoDB restart entry file: [/bin/mongodb/restart]......"
cat > $INTEGRATOR_HOME/bin/mongodb/restart << EOF
#!/bin/bash
. $INTEGRATOR_HOME/bin/mongodb/stop
sleep 3
. $INTEGRATOR_HOME/bin/mongodb/start
EOF


###########################Modify Permissions########################
echo "Setting MongoDB entry file permissions...."
chmod 755 $INTEGRATOR_HOME/bin/mongodb -R

###########################start mongodb safe###########################
echo "Starting MongoDB for the 1st time..."
rm -rf $basedir/data
rm -rf $basedir/log
mkdir -pv $basedir/data
mkdir -pv $basedir/log
mkdir -pv $basedir/tmp/mongodb

rotate &
BG_PID=$!
trap "kill -9 $BG_PID" INT

$basedir/bin/mongod --repair -dbpath $datadir --repairpath $basedir/tmp/mongodb
if [ $? -eq 0 ]; then
	echo
	echo "Integrator Database MongoDB install successfully!!!!"
else
	echo
	echo "Integrator Database MongoDB could not be started after installation, please check it manually!!!"
fi

sleep 3
kill -9 $BG_PID
echo

rm -rf $basedir/tmp

rotate &
BG_PID=$!
trap "kill -9 $BG_PID" INT

source $INTEGRATOR_HOME/bin/mongodb/start

sleep 3
kill -9 $BG_PID
echo

echo "Creating database <INTEGRATOR_FS>......"
cd $basedir/bin
./mongo <<EOF
use INTEGRATOR_FS
EOF

read -n1 -r -s -p "Pless any key to continue..."
