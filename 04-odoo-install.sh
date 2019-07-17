
#!/bin/bash
################################################################################
# Script para instalacao Odoo Debian 9
# Author: Sidnei Brianti
# wget https://raw.githubusercontent.com/scbrianti/Postgres-Cluster-Deploy/9.6/04-odoo-install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x 04-odoo-install.sh
# Execute the script to install Odoo:
# ./04-odoo-install.sh
################################################################################

OE_USER="odoo"
OE_HOME="/$OE_USER"
OE_HOME_EXT="/$OE_USER/${OE_USER}-server"
OE_EXTRA="$OE_HOME/extra"
OE_ADDONS_PATH="$OE_HOME_EXT/addons,$OE_HOME/custom/addons,$OE_EXTRA/oca-server-tools/,\
$OE_EXTRA/oca-connector-telephone/,$OE_EXTRA/oca-web/,$OE_EXTRA/oca-partner-contact/,\
$OE_EXTRA/oca-crm/,$OE_EXTRA/oca-l10n-brazil/,$OE_EXTRA/oca-helpdesk/,$OE_EXTRA/oca-social/,\
$OE_EXTRA/oca-server-auth/"

INSTALL_WKHTMLTOPDF="True"

PGBOUNCER="x.x.x.x"
PGBOUNCER_PORT="6432"


# Odoo Port
OE_PORT="8069"
# Odoo Version
OE_VERSION="12.0"

OE_SUPERADMIN="admin"
OE_CONFIG="${OE_USER}-server"

#PostgreSQL Version
OE_POSTGRESQL_VERSION="10"

###  WKHTMLTOPDF download links
WKHTMLTOX_X64=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb
WKHTMLTOX_X32=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_i386.deb

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n--- Installing Python 3 + pip3 --"
sudo apt-get install python3 python3-pip -y

echo -e "\n---- Install tool packages ----"
sudo apt-get install wget git bzr python-pip gdebi-core -y

echo -e "\n---- Install python packages ----"
sudo apt-get install libxml2-dev libxslt1-dev zlib1g-dev -y
sudo apt-get install libsasl2-dev libldap2-dev libssl-dev -y
sudo apt-get install python-dateutil python-feedparser python-ldap python-libxslt1 python-lxml \
python-mako python-openid python-psycopg2 python-pychart python-pydot python-pyparsing python-reportlab \
python-simplejson python-tz python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt \
python-yaml python-zsi python-docutils python-psutil python-mock python-unittest2 python-jinja2 \
python-decorator python-requests python-passlib python-pil -y

echo -e "\n---- Install pip packages ----"
sudo pip3 install -r https://raw.githubusercontent.com/OCA/OCB/$OE_VERSION/requirements.txt 

echo -e "\n---- Install python libraries ----"
sudo apt-get install python3-suds

echo -e "\n--- Install other required packages"
sudo apt-get install node-clean-css -y
sudo apt-get install node-less -y
sudo apt-get install python-gevent -y

#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO 12 ----"
  #pick up correct one from x64 & x32 versions:
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=$WKHTMLTOX_X64
  else
      _url=$WKHTMLTOX_X32
  fi
  sudo wget $_url
  sudo gdebi --n `basename $_url`
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
fi

echo -e "\n---- Create ODOO system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER
#The user should also be added to the sudo'ers group.
sudo adduser $OE_USER sudo

echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --depth 1 --branch $OE_VERSION https://github.com/OCA/OCB $OE_HOME_EXT/


echo -e "\n---- Create custom module directory ----"
sudo su $OE_USER -c "mkdir $OE_HOME/custom"
sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons"

echo -e "\n---- Create Extra addons directory ----"
sudo su $OE_USER -c "mkdir $OE_EXTRA"

echo -e "\n==== Installing ODOO Extra Addons ===="
sudo git clone --depth 1 --branch $OE_VERSION https://github.com/OCA/server-tools.git $OE_EXTRA/oca-server-tools/
sudo git clone --depth 1 --branch $OE_VERSION https://github.com/OCA/connector-telephony.git $OE_EXTRA/oca-connector-telephone/
sudo git clone --depth 1 --branch $OE_VERSION https://github.com/OCA/web.git $OE_EXTRA/oca-web/
sudo git clone --depth 1 --branch $OE_VERSION https://github.com/OCA/partner-contact.git $OE_EXTRA/oca-partner-contact/
sudo git clone --depth 1 --branch $OE_VERSION https://github.com/OCA/crm.git $OE_EXTRA/oca-crm/
sudo git clone --depth 1 --branch $OE_VERSION https://github.com/OCA/l10n-brazil.git $OE_EXTRA/oca-l10n-brazil/
sudo git clone --depth 1 --branch $OE_VERSION https://github.com/OCA/helpdesk.git $OE_EXTRA/oca-helpdesk/
sudo git clone --depth 1 --branch $OE_VERSION https://github.com/OCA/server-auth.git $OE_EXTRA/oca-server-auth/
sudo git clone --depth 1 --branch $OE_VERSION https://github.com/OCA/social.git $OE_EXTRA/oca-social/



echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "* Create server config file"

sudo touch /etc/${OE_CONFIG}.conf
echo -e "* Creating server config file"
sudo su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'xmlrpc_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'logfile = /var/log/${OE_USER}/${OE_CONFIG}.log\n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'addons_path = ${OE_ADDONS_PATH}\n' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "printf 'db_host = ${PGBOUNCER}\n' >>  /etc/${OE_CONFIG}.conf" #PgBouncer IP
sudo su root -c "printf 'db_port = ${PGBOUNCER_PORT}\n' >>  /etc/${OE_CONFIG}.conf"  # PgBouncer port
sudo su root -c "printf 'db_user = ${OE_USER}\n' >>  /etc/${OE_CONFIG}.conf"  # DB user
sudo su root -c "printf 'db_password =${ODOO_DB_PASS}\n' >> /etc/${OE_CONFIG}.conf"   # DB user's password


sudo chown $OE_USER:$OE_USER /etc/${OE_CONFIG}.conf
sudo chmod 640 /etc/${OE_CONFIG}.conf

echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/openerp-server --config=/etc/${OE_CONFIG}.conf' >> $OE_HOME_EXT/start.sh"
sudo chmod 755 $OE_HOME_EXT/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"
cat <<EOF > ~/$OE_CONFIG
#!/bin/sh
### BEGIN INIT INFO
# Provides: $OE_CONFIG
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: ODOO Business Applications
### END INIT INFO
PATH=/bin:/sbin:/usr/bin
DAEMON=$OE_HOME_EXT/odoo-bin
NAME=$OE_CONFIG
DESC=$OE_CONFIG
# Specify the user name (Default: odoo).
USER=$OE_USER
# Specify an alternate config file (Default: /etc/openerp-server.conf).
CONFIGFILE="/etc/${OE_CONFIG}.conf"
# pidfile
PIDFILE=/var/run/\${NAME}.pid
# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \$CONFIGFILE"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}
case "\${1}" in
start)
echo -n "Starting \${DESC}: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
stop)
echo -n "Stopping \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\${NAME}."
;;
restart|force-reload)
echo -n "Restarting \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 1
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
*)
N=/etc/init.d/\$NAME
echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;
esac
exit 0
EOF

echo -e "* Security Init File"
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Start ODOO on Startup"
sudo update-rc.d $OE_CONFIG defaults

echo -e "* Starting Odoo Service"
sudo su root -c "/etc/init.d/$OE_CONFIG start"
echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: $OE_PORT"
echo "User service: $OE_USER"
echo "User PostgreSQL: $OE_USER"
echo "Code location: $OE_USER"
echo "Addons folder: $OE_USER/$OE_CONFIG/addons/"
echo "Start Odoo service: sudo service $OE_CONFIG start"
echo "Stop Odoo service: sudo service $OE_CONFIG stop"
echo "Restart Odoo service: sudo service $OE_CONFIG restart"
echo "-----------------------------------------------------------"
