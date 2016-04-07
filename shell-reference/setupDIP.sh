#!/bin/bash

uncompress(){
	tar zxvf $COMPONENT_PATH/servicemix.tar.gz -C $INTEGRATOR_HOME/
	chmod 755 $INTEGRATOR_HOME/servicemix -R
	echo
	echo
	echo
}

function progress_bar()
{
	b=''
	let delay=$1*20000
	for ((i=0;$i<=100;i+=2))
	do
	printf "progress:[%-50s]%d%%\r" $b $i
	usleep ${delay}
	b=#$b
	done
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

source $SCRIPT_PATH/checkLicense.sh
if [ $? -ne 0 ];then
	echo "License Check Failed! Please check the license file again!!!"
	exit 0
fi

DIP_HOME=$INTEGRATOR_HOME/servicemix
DEPLOY_PATH=${DIP_HOME}/deploy
LIB_PATH=$RESOURCE_PATH/dip_lib
DIP_RES=$RESOURCE_PATH/dip

# prepare Karaf connection info
karaf_user=smx
karaf_pasw=smx
karaf_port=8101
karaf_host=localhost

echo Integrator Home: ${INTEGRATOR_HOME}
echo Integrator DIP: ${DIP_HOME}
echo Java Home: ${JAVA_HOME}
echo
echo

######################### prepare servicemix
echo -n "Preparing Servicemix folder..."
uncompress


# clear deploy
rm -rf ${DEPLOY_PATH}
mkdir ${DEPLOY_PATH}

chmod 755 $DIP_HOME -R

cd ${DIP_HOME}/bin
./start clean
echo ServiceMix Initializing......
progress_bar 30

echo Integrator Library Initializing......
cp -f ${LIB_PATH}/* ${DEPLOY_PATH}
progress_bar 15

#
echo Starting Integrator Library Bundle......
./client -u ${karaf_user} -p ${karaf_pasw} -a ${karaf_port} -h ${karaf_host} "start --force 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250"

#
echo Installing Integrator ORM......
cp $DIP_RES/sinoservices-wolfdip-orm* $DEPLOY_PATH
progress_bar 5

echo Installing Integrator CORE......
cp $DIP_RES/sinoservices-wolfdip-core* $DEPLOY_PATH
progress_bar 5

echo Installing Integrator Commons.......
cp $DIP_RES/sinoservices-wolfdip-cluster* $DEPLOY_PATH
cp $DIP_RES/sinoservices-wolfdip-cache* $DEPLOY_PATH
cp $DIP_RES/sinoservices-wolfdip-log4dip* $DEPLOY_PATH
cp $DIP_RES/sinoservices-wolfdip-mail* $DEPLOY_PATH
cp $DIP_RES/sinoservices-wolfdip-mapping* $DEPLOY_PATH
progress_bar 3

echo Installing Integrator Gateway......
cp $DIP_RES/sinoservices-wolfdip-gateway* $DEPLOY_PATH
progress_bar 5

echo Installing Integrator Integrator......
cp $DIP_RES/sinoservices-wolfdip-integrator* $DEPLOY_PATH
progress_bar 3

./client -u ${karaf_user} -p ${karaf_pasw} -a ${karaf_port} -h ${karaf_host} "list |grep wolfdip"

###########################create start/stop entry###############
echo "Creating DIP start entry file: [/bin/dip/start]......"
mkdir -pv $INTEGRATOR_HOME/bin/dip
cat > $INTEGRATOR_HOME/bin/dip/start << EOF
#!/bin/bash

source $INTEGRATOR_HOME/bin/setEnv.sh

current_path=\$PWD

cd $DIP_HOME
nohup ./bin/servicemix server >/dev/null 2>&1 &

cd \$current_path

echo
read -n1 -p "Do you want to start tailling log, you can quit tailling any time using CTRL+C (y/n)" continue
if [ ! -n "\$continue" ]; then
	tail -f $DIP_HOME/data/log/servicemix.log
elif [ "\$continue" == "y" ]; then
	tail -f $DIP_HOME/data/log/servicemix.log
elif [ "\$continue" == "n" ]; then
	echo next
fi

EOF

echo "Creating DIP stop entry file: [/bin/dip/stop]......"
cat > $INTEGRATOR_HOME/bin/dip/stop << EOF
#!/bin/bash
current_path=\$PWD
echo "Integrator DIP (Servicemix) Process ID :"
ps -ef | grep servicemix | grep -v grep | awk '{print \$2}' 
ps -ef | grep servicemix | grep -v grep | awk '{print \$2}' | sed -e "s/^/kill -9 /g" | sh -
EOF

echo "Creating DIP restart entry file: [/bin/dip/restart]......"
cat > $INTEGRATOR_HOME/bin/dip/restart << EOF
#!/bin/bash
. $INTEGRATOR_HOME/bin/dip/stop
sleep 3
. $INTEGRATOR_HOME/bin/dip/start
EOF

###########################Modify Permissions########################
echo "Setting DIP entry file permissions...."
chmod 755 $INTEGRATOR_HOME/bin/dip -R

#ip_addr=`ifconfig eth0 |grep "inet addr"| cut -f 2 -d ":"|cut -f 1 -d " "`
#echo Integrator DIP install finised! Open following address to check DIP Routing Service!
#echo http://${ip_addr}:9010/WolfDIPWebService/RouteManager?wsdl

###########################Modify JVM Parameter#######################
echo "Setting JVM Parameters for servicemix base on Total memory..."
TotalMem=`cat /proc/meminfo |grep 'MemTotal' |awk -F : '{print $2}' |sed 's/^[ \t]*//g' |sed 's/ kB//g'`
MemG=`echo "$TotalMem / 4000000 " | bc`;
if [ "x${MenG}" != "x" -a "x${MenG}" != "x0" ]; then
	cat >> $DIP_HOME/bin/setenv << EOF
	export JAVA_MIN_MEM=${MemG}G
	export JAVA_MAX_MEM=${MemG}G
	export JAVA_MAX_PERM_MEM=${MemG}G
EOF
fi

current_path=$PWD
cd $DIP_HOME
nohup ./bin/servicemix server >/dev/null 2>&1 &
cd $current_path

echo "Integrator DIP has been installed"

read -n1 -r -s -p "Pless any key to continue..."
