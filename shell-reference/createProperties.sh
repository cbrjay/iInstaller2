#!/bin/bash

PropertiesFile=$INTEGRATOR_HOME/config/system.properties
customFile=$INTEGRATOR_HOME/config/custom.properties
DATA_DIR=$INTEGRATOR_HOME/data
Upload_DIR=$DATA_DIR/uploadfiles
LocalIP=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
DB_IP=$LocalIP

CheckIPAddr()
{
	ANSWER=$(echo $1 | awk -F '.' '$1 < 255 && $1 >= 0 && $2 < 255 && $2 >= 0 && $3 < 255 && $3 >= 0 && $4 < 255 && $4 >= 0 {print 1}')
	if [ "$ANSWER" == "1" ]; then
		return 1
	else
		return 0
	fi
}

getLocalIP(){
	echo "Getting local IP Address......"
	echo $LocalIP
	if [ "x$LocalIP" == "x" ]; then
		read -p "Please enter the IP Address of this server: " LocalIP
		getLocalIP
	else
		len=`echo ${LocalIP} | wc -L` 
		if [ $len -gt 15 ]; then
			echo "Please select and enter the IP address used:"
			echo $LocalIP
			read -p "Used : " LocalIP
			getLocalIP
		fi
	fi
}

getDBIp(){
	echo 
	echo "Setting database IP Address......"
	echo
	echo "If you install database and application in the same server, please enter to continue!!!"
	echo "If not, please enter the database server IP address:"
	read DB_IP
	if [ -z ${DB_IP} ]; then
		DB_IP=$LocalIP
	else
		CheckIPAddr $DB_IP
		if [ $# -ne 0 ]; then
			echo "Please enter valid IP Address!!!"
			getDBIp
		fi
		
	fi
}

getMySQLUser(){
	if [ "x$LocalIP" = "x$DB_IP" ]; then
		mysql_user=admin
		if [ "x$mysql_admin_password" = "x" ]; then
			read -p "Enter the password of MySQL User <admin> : " mysql_admin_password
		fi
		mysql_password=$mysql_admin_password
	else
		mysql_user=admin
		if [ "x$mysql_admin_password" = "x" ]; then
			read -p "Enter the password of MySQL User <admin> : " mysql_admin_password
		fi
		mysql_password=$mysql_admin_password		
	fi
}

warningEmail(){
	echo
	echo "You need to enter the email host and account used to send warning emails during Integrator processing."
	echo "If you do not want to set it now, you can modify the properties file manually."
	echo "Note: if you do not set the email infomations, the warning emails will not be sent!"
	read -p "Enter the email host (such as <mail.sinoservices.com> or <139.392.48.2>) :" email_warning_host
	read -p "Enter the email account (such as <sino.admin>) :" email_warning_username
	read -p "Enter the password of email account :" email_warning_password
	read -p "Enter the emaill address where to send to transaction exception mails :" transaction_exception_email_to
}

createPropertiesFile(){
CONFIG_PATH=$(dirname ${PropertiesFile})
if [ ! -d "$CONFIG_PATH" ]; then
	mkdir -pv $CONFIG_PATH
fi

cat > $PropertiesFile << EOF

project.name=wolf-framework
common.local.ip=$LocalIP
common.cluster.isactive=false
user.default.password=666666
interceptor.checklogin.exclude.action=com.sinoservices.wolflite.controller.LoginAction
interceptor.checkauthority.exclude.action=com.sinoservices.wolflite.controller.LoginAction,com.sinoservices.wolflite.controller.IndexAction

common.directory.uploadfiles.wsdl=$Upload_DIR/wsdl/
common.directory.uploadfiles.resource=$Upload_DIR/resource/
common.directory.servicemix.deploy=$INTEGRATOR_HOME/servicemix/deploy/

common.webservice.routemanager.port=9010
common.webservice.routemanager.resource=/WolfDIPWebService/RouteManager
common.webservice.routemanager.username=portal2dip
common.webservice.routemanager.password=portal2dip

route.doc_flow.uri.prefix=activemq:DOC_FLOW_
route.doc_flow.uri.consumer.parameters=
route.doc_flow.uri.producer.parameters=?requestTimeout=599999
route_manager.producer.parameters=?requestTimeout=360000
route_manager.stop_timeout=60
common.log_transaction.route_count=50

jdbc.driverClassName=com.mysql.jdbc.Driver
jdbc.url=jdbc\\:mysql\\://$DB_IP\\:3306/INTEGRATOR_DB?useUnicode\\=true&characterEncoding\\=UTF-8
jdbc.username=$mysql_user
jdbc.password=$mysql_password
jdbc.initial_size=10
jdbc.max_idle=20
jdbc.min_idle=5
jdbc.max_active=50
jdbc.remove_abandoned=true
jdbc.remove_abandoned_timeout=180
jdbc.max_wait=3000
jdbc.pool_prepared_statements=true
jdbc.max_open_prepared_statements=200
jdbc.test_while_idle=true
jdbc.test_on_borrow=false
jdbc.test_on_return=false
jdbc.timeBetweenEvictionRunsMillis=30000
jdbc.numTestsPerEvictionRun=30
jdbc.minEvictableIdleTimeMillis=1800000
jdbc.db=INTEGRATOR_DB

common.connection_pool.pool_timeout=86400000
common.connection_pool.dbcp.initial_size=10
common.connection_pool.dbcp.max_idle=10
common.connection_pool.dbcp.min_idle=2
common.connection_pool.dbcp.max_active=40
common.connection_pool.dbcp.remove_abandoned=true
common.connection_pool.dbcp.remove_abandoned_timeout=300
common.connection_pool.dbcp.max_wait=60000

common.connection_pool.dbcp.pool_prepared_statements=true
common.connection_pool.dbcp.max_open_prepared_statements=200
common.connection_pool.dbcp.test_while_idle=true
common.connection_pool.dbcp.test_on_borrow=false
common.connection_pool.dbcp.test_on_return=false
common.connection_pool.validationQuery4Oracle=SELECT 1 FROM DUAL
common.connection_pool.validationQuery4MySQL=SELECT 1
common.connection_pool.dbcp.timeBetweenEvictionRunsMillis=30000
common.connection_pool.dbcp.numTestsPerEvictionRun=30
common.connection_pool.dbcp.minEvictableIdleTimeMillis=1800000

common.connection_pool.druid.pool_timeout=3600000
common.connection_pool.druid.maxActive=20
common.connection_pool.druid.initialSize=10
common.connection_pool.druid.maxWait=12000
common.connection_pool.druid.minIdle=5
common.connection_pool.druid.timeBetweenEvictionRunsMillis=6000
common.connection_pool.druid.validationQuery4Oracle=SELECT 1 FROM DUAL
common.connection_pool.druid.validationQuery4MySQL=SELECT 1
common.connection_pool.druid.testWhileIdle=true
common.connection_pool.druid.testOnBorrow=false
common.connection_pool.druid.testOnReturn=false
common.connection_pool.druid.removeAbandoned=true
common.connection_pool.druid.removeAbandonedTimeout=180
common.connection_pool.druid.logAbandoned=true

common.mongodb.host=$DB_IP
common.mongodb.port=27017
common.mongodb.poolsize=100
common.mongodb.blocksize=100
common.mongodb.connect-timeout=1000
common.mongodb.max-wait-time=1500
common.mongodb.auto-connect-retry=true
common.mongodb.socket-keep-alive=true
common.mongodb.socket-timeout=1500
common.mongodb.slave-ok=true
common.mongodb.write-number=1
common.mongodb.write-timeout=0
common.mongodb.write-fsync=true
common.mongodb.dbname=INTEGRATOR_FS
common.mongodb.backup.datetime=11:11:13
common.mongodb.backup.pagesize=3
common.mongodb.backup.remove=false

gateway.httpclient.oauth.getoauthcode.url=https://oauth.tbsandbox.com/authorize
gateway.httpclient.oauth.getaccesstoken.url=https://oauth.tbsandbox.com/token
gateway.httpclient.oauth.getaccesstoken.grant_type=authorization_code
gateway.httpclient.oauth.getaccesstoken.client_id=1023061909
gateway.httpclient.oauth.getaccesstoken.client_secret=sandbox5b9b5d0dc3963da95207d2e35
gateway.httpclient.oauth.getaccesstoken.redirect_uri=http://$LocalIP:9180/integrator/gateway/oauth.shtml

gateway.alibabaadapter.oauth.getoauthcode.host=gw.open.1688.com
gateway.alibabaadapter.oauth.getoauthcode.site=china
gateway.alibabaadapter.oauth.getoauthcode.client_id=1017386
gateway.alibabaadapter.oauth.getoauthcode.appSecret=VSb5Lw1KOIC
gateway.alibabaadapter.oauth.getoauthcode.redirect_uri=http://$LocalIP:8080/integrator/gateway/alioauth.shtml
gateway.alibabaadapter.oauth.getoauthcode.state=test
adapter.alibaba.directory.backupfiles=$DATA_DIR/adapter/alibaba/orders
adapter.taobao.directory.backupfiles=$DATA_DIR/adapter/taobao/trades

gateway.httpclient.oauth.dangdang.getoauthcode.url=http://oauth.dangdang.com/authorize
gateway.httpclient.oauth.dangdang.getaccesstoken.url=http://oauth.dangdang.com/token 
gateway.httpclient.oauth.dangdang.getaccesstoken.grant_type=code
gateway.httpclient.oauth.dangdang.getaccesstoken.app_id=2100003719
gateway.httpclient.oauth.dangdang.getaccesstoken.app_secret=C6C332E2161411543449AF984E4B4C32
gateway.httpclient.oauth.dangdang.api.url=http://api.open.dangdang.com/openapi/rest?v=1.0
gateway.httpclient.oauth.dangdang.getaccesstoken.redirect_uri=http://$LocalIP:9180/integrator/gateway/oauth.shtml
adapter.dangdang.directory.backupfiles=$DATA_DIR/adapter/dangdang/trades

gateway.httpclient.oauth.jindong.api.url=http://gw.api.jd.com/routerjson
gateway.httpclient.oauth.jindong.getoauthcode.url=https://oauth.jd.com/oauth/authorize
gateway.httpclient.oauth.jindong.getoauthcode.response_type=code
gateway.httpclient.oauth.jindong.getoauthcode.appkey=50CB27D1BE8A1C4809BBF7C2FF4E07C4
gateway.httpclient.oauth.jindong.getoauthcode.app_Secret=7a5f817691054577b200cc764a5314d3
gateway.httpclient.oauth.jindong.getoauthcode.state=Dustin
gateway.httpclient.oauth.jindong.getoauthcode.redirect_uri=http://$LocalIP:8080/integrator/gateway/oauth.shtml
adapter.jindong.directory.backupfiles=$DATA_DIR/adapter/jindong/trades

gateway.httpclient.oauth.vip.getoauthcode.appkey=dc8eba3a
gateway.httpclient.oauth.vip.getoauthcode.app_Secret=06BCB91602A8B0AEFAC80F0BE5E314BB
gateway.httpclient.oauth.vip.api.url=http://sandbox.vipapis.com
adapter.vip.directory.backupfiles=$DATA_DIR/adapter/vip/trades

email_warning.host=$email_warning_host
email_warning.username=$email_warning_username
email_warning.password=$email_warning_password
email_warning.producer.uri=vm:WOLF_EMAIL_WARNING?pollTimeout=60000
email_warning.consumer.uri=vm:WOLF_EMAIL_WARNING?size=100000&timeout=6000000&blockWhenFull=true

jetty.https.ssl.password=password
jetty.https.ssl.keyPassword=password
jetty.https.ssl.keystore=$DATA_DIR/keystore/cherry.jks
jetty.https.ssl.needClientAuth=false

jetty.https.ssl.mutual.password=password
jetty.https.ssl.mutual.keyPassword=password
jetty.https.ssl.mutual.keystore=$DATA_DIR/keystore/cherry.jks
jetty.https.ssl.mutual.needClientAuth=true
jetty.https.ssl.mutual.truststore=$DATA_DIR/keystore/truststore.jks
jetty.https.ssl.mutual.trustPassword=password

jetty.http.name=wolf-framework
jetty.http.config=$DATA_DIR/keystore/realm.properties
jetty.https.sslSocketConnectors.config=$DATA_DIR/keystore/sslSelectChannelConnector/
jetty.https.socketConnectors.config=$DATA_DIR/keystore/selectChannelConnector/
selectChannelConnector.requestBufferSize=1048576
selectChannelConnector.responseBufferSize=1048576
jetty.threadPool.minThreads=100
jetty.threadPool.maxThreads=5000
jetty.threadPool.detailedDump=false
jetty.threadPool.daemon=true
jetty.maxIdleTime=3000
jetty.Acceptors=4
jetty.acceptQueueSize=40960
jetty.statsOn=false
jetty.lowResourcesConnections=20000
jetty.lowResourcesMaxIdleTime=3000

jetty.https.port1=8555
jetty.https.port2=8556
jetty.https.port3=8557
jetty.https.port4=8558
jetty.https.port5=8559

jetty.http.port1=9016
jetty.http.port2=9017
jetty.http.port3=9018
jetty.http.port4=9019
jetty.http.port5=9020

gateway.ftps.truststore.file.path=$DATA_DIR/keystore/default.keystore
gateway.ftps.truststore.pwd.trueth=123456
gateway.ftp.cilent.keystore.file.path=$DATA_DIR/keystore/default.keystore
gateway.ftp.client.keystore.pwd.trueth=123456
gateway.ftp.client.keystore.key.pwd.trueth=123456

gateway.localfile.directory.basic=$DATA_DIR

gateway.webservice.cxf.wssecurity.truststore.file=$DATA_DIR/keystore/default.keystore
gateway.webservice.cxf.wssecurity.truststore.password=123456
gateway.webservice.cxf.wssecurity.keystore.file=$DATA_DIR/keystore/default.keystore

gateway.webservice.cxf.wssecurity.keystore.password=123456
gateway.webservice.cxf.wssecurity.keystore.alias=server
gateway.webservice.server.wsdl_uri_params={"10"\\:{"WS_HTTP_SIMPLE"\\:"http\\://%1\$s\\:9060/WolfService4Chainwork?wsdl"},"20"\\:{"WS_HTTP_SIMPLE"\\:"http\\://%1\$s\\:9080/WolfService4Sfwl?wsdl"},"21"\\:{"WS_HTTP_SIMPLE"\\:"http\\://%1\$s\\:9081/SfwlWebService?wsdl"},"99"\\:{"WS_HTTP_SIMPLE"\\:"http\\://%1\$s\\:9050/WolfDIPWebService/GatewayIn?wsdl", "WS_HTTP_U_D"\\:"http\\://%1\$s\\:9030/WolfDIPWebService/GatewayIn?wsdl", "WS_HTTP_U_T"\\:"http\\://%1\$s\\:9033/WolfDIPWebService/GatewayIn?wsdl"},"61"\\:{"WS_HTTP_SIMPLE"\\:"http\\://%1\$s\\:9061/WolfService4FluxWMS?wsdl"},"62"\\:{"WS_HTTP_SIMPLE"\\:"http\\://%1\$s\\:9062/WolfService4BSPWMS?wsdl"},"63"\\:{"WS_HTTP_SIMPLE"\\:"http\\://%1\$s\\:9063/WolfService4MDCWMS?wsdl"}}

gateway.webservice.port.http.u=9030
gateway.webservice.port.http.se=9031
gateway.webservice.port.http.use=9032
gateway.webservice.port.http.u2=9033
gateway.webservice.port.http.u2se=9034
gateway.webservice.port.https=9040
gateway.webservice.port.http.simple=9050
gateway.webservice.resource.inbound=/WolfDIPWebService/GatewayIn
camel.cxf.interceptor.signaturePropFile=wssecurity-truststore.properties
camel.cxf.interceptor.decryptionPropFile=wssecurity-keystore.properties

gateway.webservice.port.adapter.chainwork=9060
gateway.webservice.resource.adapter.chainwork=/WolfService4Chainwork

gateway.webservice.port.adapter.sfwl=9080
gateway.webservice.resource.adapter.sfwl=/WolfService4Sfwl

gateway.webservice.port.adapter.edi=9081
gateway.webservice.resource.adapter.edi=/SfwlWebService

gateway.webservice.port.adapter.fluxwms=9061
gateway.webservice.resource.adapter.fluxwms=/WolfService4FluxWMS
gateway.webservice.resource.adapter.fluxwms.xpath=/RequestEntity/functionalArea

gateway.webservice.port.adapter.bspwms=9062
gateway.webservice.resource.adapter.bspwms=/WolfService4BSPWMS

gateway.webservice.port.adapter.mdcwms=9063
gateway.webservice.resource.adapter.mdcwms=/WolfService4MDCWMS
gateway.webservice.resource.adapter.mdcwms.xpath=/Request/Header/DocumentType

camel.cxf.tslClient.keyPassword=666666
camel.cxf.tslClient.keyStore.password=666666
camel.cxf.tslClient.keyStore.file=$DATA_DIR/keystore/server.keystore
camel.cxf.tslClient.trustStore.password=123456
camel.cxf.tslClient.trustStore.file=$DATA_DIR/keystore/truststore.jks
camel.cxf.tslClient.disableCNCheck=true

org.apache.ws.security.crypto.provider=org.apache.ws.security.components.crypto.Merlin
org.apache.ws.security.crypto.merlin.keystore.type=jks
org.apache.ws.security.crypto.merlin.keystore.password=123456
org.apache.ws.security.crypto.merlin.file=$DATA_DIR/keystore/truststore.jks

event.archive.file.base.path=$DATA_DIR/archive/

mapping.log.file.path=$DATA_DIR/mapping/

activemq.broker_url=failover:(tcp://localhost:61616?wireFormat.maxInactivityDuration=0&?tcpNoDelay=true,tcp://localhost:61617?wireFormat.maxInactivityDuration=0&?tcpNoDelay=true)?randomize=false&maxReconnectDelay=10000&jms.prefetchPolicy.queuePrefetch=50
activemq.username=smx
activemq.password=smx
activemq.dispatch_async=true
activemq.use_async_send=true
activemq.max_thread_pool_size=1000
activemq.optimize_acknowledge=true
activemq.pool.idle_timeout=0
activemq.pool.max_connections=200
activemq.pool.maximum_active=2000
activemq.jms.concurrent_consumers=20
activemq.jms.max_concurrent_consumers=100
activemq.jms.delivery_persistent=false
activemq.component.transacted=false
activemq.component.cache_level_name=CACHE_CONSUMER
activemq.component.acknowledgement_mode=1
activemq.redelivery_policy.maximum_redeliveries=-1
activemq.redelivery_policy.redelivery_delay=5000
activemq.redelivery_policy.initial_redelivery_delay=1000
activemq.redelivery_policy.use_exponential_back_off=false
activemq.redelivery_policy.back_off_multiplier=5

redis.pool.maxActive=1024
redis.pool.maxIdle=200
redis.pool.maxWait=1000  
redis.pool.testOnBorrow=false 
redis.pool.testOnReturn=false
redis.jedis.master.host=$LocalIP
redis.jedis.master.port=6379
redis.jedis.slave.host=$LocalIP
redis.jedis.slave.port=6379
redis.jedis.lock.count.express=1
redis.jedis.cluster.count=4

common.camel.thread.poolSize=10
common.camel.thread.maxPoolSize=50

cert.common.keystore.password=123456
cert.common.keystore.trustedstore.path=$DATA_DIR/keystore/default.keystore
cert.common.keystore.userstore.path=$DATA_DIR/keystore/userstore.keystore
cert.common.uploadfiles.cert=$DATA_DIR/uploadfiles/cert/

wolfdip.mq.config.concurrentconsumer=50
wolfdip.mq.config.maxconcurrentconsumer=100

system.user.limit.logincount=6
system.user.limit.intervaltime=24
transaction.exception.email.to=$transaction_exception_email_to
transaction.monitor.longtime=5
transaction.monitor.isopen=true
transaction.monitor.jobtime=0 0 2 * * ? *

wolfdip.httpsqs.core_pool_size=10
wolfdip.httpsqs.delay_time=1

monitor.server.ip=127.0.0.1

gateway.threadPoolProfile.poolSize=10
gateway.threadPoolProfile.maxPoolSize=20
gateway.threadPoolProfile.maxQueueSize=1000

gateway.threadPoolProfile.rejectedPolicy=CallerRuns
gateway.threadPoolProfile.keepAliveTime=30000

integration.threadPoolProfile.poolSize=30
integration.threadPoolProfile.maxPoolSize=50
integration.threadPoolProfile.maxQueueSize=1000

integration.threadPoolProfile.rejectedPolicy=CallerRuns
integration.threadPoolProfile.keepAliveTime=30000

EOF
}

docreate(){
	getLocalIP
	getDBIp
	getMySQLUser
	warningEmail
	createPropertiesFile
}

createCustome(){
	touch $customFile
}

if [ ! -f "$PropertiesFile" ]; then
	docreate
	createCustome
else
	read -n1 -p "System Properties exists, do you want to create properties base on current settings? (y/n)" continue
	if [ "$continue" == "n" ]; then
		echo next
	else
		rm -f $PropertiesFile
		docreate
	fi
fi
