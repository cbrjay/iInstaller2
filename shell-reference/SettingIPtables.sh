#!/bin/bash

portPortal=9143
portDIP=8181
portHttp1=9016
portHttp2=9017
portHttp3=9018
portHttp4=9019
portHttp5=9020

iptableRules=

function addRule(){
        port=$1
	desc=$2
	iptableRules="$iptableRules
-A INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT"
}

###########backup iptables
echo "Backup iptables to $PWD ......"

cp /etc/sysconfig/iptables $PWD/iptables

#########$ preparing rules
addRule $portPortal "Integrator Portal"
addRule $portDIP "Integrator DIP"
addRule $portHttp1 "Integrator HTTP Port"
addRule $portHttp2 "Integrator HTTP Port"
addRule $portHttp3 "Integrator HTTP Port"
addRule $portHttp4 "Integrator HTTP Port"
addRule $portHttp5 "Integrator HTTP Port"

cat >> /etc/sysconfig/iptables <<EOF
$iptableRules
COMMIT
EOF

########## Restart iptables

service iptables stop
service iptables start

