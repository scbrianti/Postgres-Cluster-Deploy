#!/bin/bash
#####################################################################################################
# OS: Debian 9
# PostgreSQL: 9.6
# Autor: Sidnei Brianti
#----------------------------------------------------------------------------------------------------
# wget https://raw.githubusercontent.com/scbrianti/Postgres-Cluster-Deploy/9.6/03-pgbouncer-install.sh
# Torne o arquivo executavel
# sudo chmod +x 03-pgbouncer-install.sh
# Altere as variáveis MASTER,SLAVE para os parametros de sua rede
# Execute o script para instalar PgBouncer:
# sudo ./02-slave-install.sh
#######################################################################################################

MASTER="psql1"
SLAVE="psql2"
ODOO_DB_USER="odoo"
ODOO_DB_PASS="odoo"

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt update
sudo apt upgrade -yV

#--------------------------------------------------
# Install PgBouncer
#--------------------------------------------------
echo -e "\n---- Install PgBouncer ----"
sudo apt install postgresql-client pgbouncer -yV

echo -e "\n---- Configure PgBouncer ----"
sudo sed -i "s/;\* = host=testserver/* = host=$MASTER/g" /etc/pgbouncer/pgbouncer.ini
sudo sed -i "s/listen_addr = 127.0.0.1/listen_addr = 0.0.0.0/g" /etc/pgbouncer/pgbouncer.ini
sudo sed -i "s/auth_type = trust/auth_type = md5/g" /etc/pgbouncer/pgbouncer.ini
echo "admin_users = odoo" | sudo tee -a /etc/pgbouncer/pgbouncer.ini
echo "\"$ODOO_DB_USER\" \"$ODOO_DB_PASS\"" | sudo tee -a /etc/pgbouncer/userlist.txt
sudo service pgbouncer restart

echo -e "\n---- Prepare Failover Scripts ----"
cat <<EOF > ~/switch-$MASTER
#!/bin/bash
sudo sed -i "s/\* = host=$SLAVE/* = host=$MASTER/g" /etc/pgbouncer/pgbouncer.ini
sudo service pgbouncer restart
EOF
cat <<EOF > ~/switch-$SLAVE
sudo sed -i "s/\* = host=$MASTER/* = host=$SLAVE/g" /etc/pgbouncer/pgbouncer.ini
sudo service pgbouncer restart
EOF
sudo chmod +x ~/switch-$MASTER
sudo chmod +x ~/switch-$SLAVE

echo -e "\n---- Completed PgBouncer Installation Successfully ----"
