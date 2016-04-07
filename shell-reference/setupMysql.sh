#!/bin/bash

uncompressmysql(){
	tar zxvf $COMPONENT_PATH/mysql.tar.gz -C $INTEGRATOR_HOME/
	chmod 755 $INTEGRATOR_HOME/mysql -R
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

mysql_user=$USER
echo
echo
read -e -p "Enter passowrd for MySQL local user <root> :" mysql_root_password
echo "Password of MySQL user <root> is set : $mysql_root_password <root> will be used as local MySQL management!"
echo
read -e -p "Enter passowrd for MySQL remote user <admin> :" mysql_admin_password
echo "Password of MySQL user <admin> is set : $mysql_admin_password <admin> will be used as remote connection!"

echo "Backup mysql user account to $INTEGRATOR_HOME/bin/mysql.info..."
cat > $INTEGRATOR_HOME/bin/mysql.info << EOF

LocalUser=root
LocalUserPassword=$mysql_root_password

RemoteUser=admin
RemoteUserPassword=$mysql_admin_password

EOF

uncompressmysql

#prepare db user##############only when running root#########
if [ $UID -eq 0 ];then
	echo
	echo
	echo "Preparing mysql user....."
	groupadd mysql
	useradd -g mysql -s /bin/nolog mysql
	mysql_user=mysql
	echo "Finish prepar mysql user!!!"
fi

######################### create mysql folder
echo
echo "Preparing mysql setup folder..."
basedir=$INTEGRATOR_HOME/mysql
datadir=$INTEGRATOR_HOME/mysql/data
confdir=$INTEGRATOR_HOME/mysql/etc
mkdir -pv $datadir
mkdir -pv $confdir
mkdir -pv $INTEGRATOR_HOME/mysql/sock
mkdir -pv $INTEGRATOR_HOME/mysql/log
mkdir -pv $INTEGRATOR_HOME/mysql/run
echo "Finish prepare mysql folder!!!"


##################create my.cnf profile##########################
echo
echo "Creating MySQL config file....."
echo "
[mysqld]
basedir	=	$basedir
datadir	=	$datadir
log-error	=	$basedir/log/mysql_error.log
pid-file	=	$basedir/run/mysql.pid
socket	=	$basedir/sock/mysql.sock
skip-external-locking
key_buffer_size	=	16M
max_allowed_packet	=	1M
table_open_cache	=	64
sort_buffer_size	=	512K
net_buffer_length	=	8K
read_buffer_size	=	256K
read_rnd_buffer_size	=	512K
myisam_sort_buffer_size	=	8M
skip-name-resolve
#log-bin=$basedir/log/mysql-bin
#binlog_format	=	mixed
server-id	=	1
symbolic-links	=	0
#innodb_force_recovery	=	1

[mysqldump]
quick
max_allowed_packet	=	16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size	=	20M
sort_buffer_size	=	20M
read_buffer	=	2M
write_buffer	=	2M

[mysqlhotcopy]
interactive-timeout
" > $basedir/etc/my.cnf


##########################create data file
echo
cd $basedir
./scripts/mysql_install_db --user=$mysql_usr --defaults-file=$basedir/etc/my.cnf
code=$?
if [ $code -ne 0 -a $code -lt 122 ]; then
	echo $?
	read -n1 -r -s -p "MySQL start failed, the installation will be exit!!!"
	echo && exit
else
	echo "DONE"
fi

###########################set mysql file privilege####################
if [ $UID -eq 0 ];then
	echo
	echo "Assigning permissions of folder to mysql user....."
	chown -R $USER:mysql $basedir
	chown -R mysql:mysql $datadir
	echo "DONE"
fi

##########################start mysql without logging#################
echo
echo
echo "Starting MySQL for the 1st time....."
cd $basedir
export PATH=$basedir/bin:$PATH
./bin/mysqld_safe --defaults-file=$basedir/etc/my.cnf --user=$USER --skip-grant-tables &

sleep 3

##########################set root password###########################
echo "Setting MySQL local user <root> password....."
./bin/mysql -u"root" -D --socket=$basedir/sock/mysql.sock mysql << EOF
UPDATE user SET Password=password('$mysql_root_password') where User='root';
FLUSH PRIVILEGES;
quit
EOF

#########################shutdown mysql###############################
echo "Shutdown MySQL......"
./bin/mysqladmin -u"root" -p"$mysql_root_password" --socket=$basedir/sock/mysql.sock shutdown
sleep 3

###########################create mysql start/stop entry###############
echo
echo
detectOS() {
    # OS specific support (must be 'true' or 'false').
    cygwin=false;
    darwin=false;
    aix=false;
    os400=false;
    case "`uname`" in
        CYGWIN*)
            cygwin=true
            ;;
        Darwin*)
            darwin=true
            ;;
        AIX*)
            aix=true
            ;;
        OS400*)
            os400=true
            ;;
    esac
}

unlimitFD() {
    # Use the maximum available, or set MAX_FD != -1 to use that
    if [ "x$MAX_FD" = "x" ]; then
        MAX_FD="maximum"
    fi

    # Increase the maximum file descriptors if we can
    if [ "$os400" = "false" ] && [ "$cygwin" = "false" ]; then
        MAX_FD_LIMIT=`ulimit -H -n`
        if [ "$MAX_FD_LIMIT" != 'unlimited' ]; then 
            if [ $? -eq 0 ]; then
                if [ "$MAX_FD" = "maximum" -o "$MAX_FD" = "max" ]; then
                    # use the system max
                    MAX_FD="$MAX_FD_LIMIT"
                fi
            else
                warn "Could not query system maximum file descriptor limit: $MAX_FD_LIMIT"
            fi
        fi
    fi
}

detectOS
unlimitFD
echo "Creating MySQL start entry file: [/bin/mysql/start]......"
mkdir -pv $INTEGRATOR_HOME/bin/mysql
cat > $INTEGRATOR_HOME/bin/mysql/start << EOF
#!/bin/bash

echo "Setting ulimit..."
ulimit -n $MAX_FD
echo "ulimit -n" \`ulimit -n\`

current_path=\$PWD

export PATH=$basedir/bin:$PATH

cd $basedir
./bin/mysqld_safe --defaults-file=$basedir/etc/my.cnf --user=$USER &
sleep 3
echo "Integrator Database MySQL has been started!!!!"
cd \$current_path
EOF

echo "Creating MySQL stop entry file: [/bin/mysql/stop]......"
cat > $INTEGRATOR_HOME/bin/mysql/stop << EOF
#!/bin/bash
current_path=\$PWD
export PATH=$basedir/bin:$PATH
cd $basedir
./bin/mysqladmin -u"root" -p"$mysql_root_password" --socket=$basedir/sock/mysql.sock shutdown
cd \$current_path
EOF

echo "Creating MySQL restart entry file: [/bin/mysql/restart]......"
cat > $INTEGRATOR_HOME/bin/mysql/restart << EOF
#!/bin/bash
. $INTEGRATOR_HOME/bin/mysql/stop
sleep 3
. $INTEGRATOR_HOME/bin/mysql/start
EOF

###########################Modify Permissions########################
echo "Setting MySQL entry file permissions...."
chmod 755 $INTEGRATOR_HOME/bin/mysql -R

###########################start mysql safe###########################
echo "Starting MySQL using start entry...."
source $INTEGRATOR_HOME/bin/mysql/start
sleep 5

##########################create admin user###########################
echo "Creating MySQL remote user <admin>........."
./bin/mysql -u"root" -p"$mysql_root_password" --socket=$basedir/sock/mysql.sock -D mysql << EOF
grant all privileges on *.* to admin @"%" identified by '$mysql_admin_password';
flush privileges;
quit
EOF


#########################initialize integrator_db#####################
echo "Initialize Integrator database......"
./bin/mysql -u"root" -p"$mysql_root_password" --socket=$basedir/sock/mysql.sock -D mysql << EOF
Create Database If Not Exists INTEGRATOR_DB Character Set UTF8;
use INTEGRATOR_DB;
source $RESOURCE_PATH/db/INTEGRATOR_DB_INIT.sql
quit
EOF


echo
echo
echo "MySQL finish setup, please using user<admin> and password<$mysql_admin_password> to connect!"
read -n1 -r -s -p "Pless any key to continue..."
echo
