#!/bin/bash
#####################################################################################################
# OS: Debian 9
# PostgreSQL: 9.6
# Autor: Sidnei Brianti
#----------------------------------------------------------------------------------------------------
# wget https://raw.githubusercontent.com/scbrianti/Postgres-Cluster-Deploy/9.6/02-slave-install.sh
# Torne o arquivo executavel
# sudo chmod +x 02-slave-install.sh
# Altere as variáveis MASTER,SLAVE para os parametros de sua rede
# Execute o script para instalar Postgresql Master:
# sudo ./02-slave-install.sh
#######################################################################################################


MASTER="192.168.0.3"
SLAVE="192.168.0.4"

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt update
sudo apt upgrade -yV

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server ----"
sudo apt install postgresql-9.6 postgresql-9.6-repmgr postgresql-client-9.6 -yV

echo -e "\n---- Copy RSA keys sent from Node1 ----"
sudo chown postgres.postgres ~/authorized_keys ~/id_rsa.pub ~/id_rsa
sudo mkdir -p ~postgres/.ssh
sudo chown postgres.postgres ~postgres/.ssh
sudo mv ~/authorized_keys ~/id_rsa.pub ~/id_rsa ~postgres/.ssh
sudo chmod -R go-rwx ~postgres/.ssh

echo -e "\n---- Configure Replication Manager ----"
sudo mkdir -p /etc/repmgr
echo "cluster=Odoo
node=2
node_name=node2
use_replication_slots=1
conninfo='host=$SLAVE_IP user=repmgr dbname=repmgr'
pg_bindir=/usr/lib/postgresql/9.6/bin" | sudo tee -a /etc/repmgr/repmgr.conf

echo -e "\n---- Clone Master to Slave ----"
sudo su - postgres -c "ssh-keyscan -H $MASTER >> ~/.ssh/known_hosts"
sudo service postgresql stop
sudo su - postgres -c "repmgr -f /etc/repmgr/repmgr.conf --force --rsync-only -h $MASTER -d repmgr -U repmgr --verbose standby clone"
sudo service postgresql restart
sudo su - postgres -c "repmgr -f /etc/repmgr/repmgr.conf --force standby register"
sudo su - postgres -c "repmgr -f /etc/repmgr/repmgr.conf cluster show"
echo -e "\nAll nodes should be shown in the above table..."

echo -e "\n---- Prepare Failover Scripts ----"
cat <<EOF > ~/promote-server
#!/bin/bash
sudo su - postgres -c "repmgr -f /etc/repmgr/repmgr.conf standby promote"
EOF
cat <<EOF > ~/demote-server
#!/bin/bash
sudo service postgresql stop
sudo su - postgres -c "repmgr -f /etc/repmgr/repmgr.conf --force --rsync-only -h $MASTER -d repmgr -U repmgr --verbose standby clone"
sudo service postgresql restart
sudo su - postgres -c "repmgr -f /etc/repmgr/repmgr.conf --force standby register"
EOF
sudo chmod +x ~/promote-server
sudo chmod +x ~/demote-server

echo -e "\n---- Completed Slave Configuration Successfully ----"
echo -e "\n---- Go & Start Configuring PgBouncer Server ----"
