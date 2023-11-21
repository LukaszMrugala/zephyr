# zabbix UI service installer

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install docker.io
sudo systemctl enable docker.service
sudo systemctl start docker.service
sudo nano /etc/group

# some assembly required here...
#   this was written prior to the 2019 introduction of docker.hub rate-throttling
#   now, pulling from inside intel won't work & zabbix is absent from caas.intel mirror
#   so need to manually download .tar from docker.hub & inject them to PWD before running this script
#		--OR--
#   login to docker.hub with even a free account to bypass the rate-throttling
#
#if have docker.hub login
#  sudo docker pull zabbix/zabbix-server-pgsql
#
#else using manually downloaded tars 
gunzip zabbix-*
sudo docker load -i zabbix-server-pgsql-alpine52.tar
sudo docker load -i zabbix-web-nginx-pgsql-alpine52.tar
sudo docker load -i zabbix-server-snmptraps-alpine52.tar
sudo docker load -i postgres-latest.tar
#end if


sudo docker network create --subnet 172.20.0.0/16 --ip-range 172.20.240.0/20 zabbix-net

sudo docker run --name postgres-server -t -e POSTGRES_USER="zabbix" -e POSTGRES_PASSWORD="zabbix_pwd" -e POSTGRES_DB="zabbix" \
        --network=zabbix-net --restart unless-stopped \
        -d postgres:latest

sudo docker run --name zabbix-snmptraps -t -v /zbx_instance/snmptraps:/var/lib/zabbix/snmptraps:rw \
        -v /var/lib/zabbix/mibs:/usr/share/snmp/mibs:ro \
        --network=zabbix-net -p 162:1162/udp --restart unless-stopped \
        -d zabbix/zabbix-snmptraps:alpine-5.2-latest

sudo docker run --name zabbix-server-pgsql -t -e DB_SERVER_HOST="postgres-server" \
        -e POSTGRES_USER="zabbix" -e POSTGRES_PASSWORD="zabbix_pwd" \
        -e POSTGRES_DB="zabbix" -e ZBX_ENABLE_SNMP_TRAPS="true" \
        --network=zabbix-net -p 10051:10051 \
        --volumes-from zabbix-snmptraps \
        --restart unless-stopped \
        -d zabbix/zabbix-server-pgsql:alpine-5.2-latest

sudo docker run --name zabbix-web-nginx-pgsql -t \
        -e ZBX_SERVER_HOST="zabbix-server-pgsql" -e DB_SERVER_HOST="postgres-server" \
           -e POSTGRES_USER="zabbix" -e POSTGRES_PASSWORD="zabbix_pwd" \
        -e POSTGRES_DB="zabbix" --network=zabbix-net -p 443:8443 -p 80:8080 -v /etc/ssl/nginx:/etc/ssl/nginx:ro \
        --restart unless-stopped \
        -d zabbix/zabbix-web-nginx-pgsql:alpine-5.2-latest

