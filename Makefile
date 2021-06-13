#
#  This makefile shows how to build a server and two clients. The clients will connect
#  from different hosts to the server and all share the same docker-compose network on the server.
#
#  Author: Tim Molteno tim@molteno.net.
#  Copyright (C) 2021
#

DCOMPOSE=docker-compose -f docker-compose-server.yml
DRUN=${DCOMPOSE} run --rm openvpn

all:
	make certs
	make client CLIENTNAME=signal CLIENTIP=33
	make client CLIENTNAME=tartza CLIENTIP=22
	

# The directory of openvpn configuration information that is persistent. It is
# Mounted on the server's docker-compose file.
OVPN_DATA=openvpn-data

REMOTE_HOST=tart.elec.ac.nz
certs:
	${DRUN} ovpn_genconfig -s "10.0.0.0/24" \
		-r "10.0.0.0/24" \
		-e 'topology subnet' -E 'topology "subnet"' \
		-D -z -b -c -u udp://${REMOTE_HOST}
	${DRUN} ovpn_genconfig -u udp://${REMOTE_HOST}
	${DRUN} ovpn_initpki nopass

CLIENTNAME=signal
CLIENTIP=33
# https://openvpn.net/community-resources/how-to/#policy
client:
	mkdir -p vpn
	${DRUN} easyrsa build-client-full ${CLIENTNAME} nopass
	${DRUN} ovpn_getclient ${CLIENTNAME} > ./vpn/${CLIENTNAME}.ovpn
	${DRUN} mkdir -p /etc/openvpn/ccd
	${DRUN} touch /etc/openvpn/ccd/${CLIENTNAME}
	echo ifconfig-push 10.0.0.${CLIENTIP} 255.255.255.0 | ${DRUN}  tee /etc/openvpn/ccd/${CLIENTNAME}

run_server:
	${DCOMPOSE} up -d
	${DCOMPOSE} logs -f
	

CLIENT_HOST=kaka

client_setup:
	rsync -rvz ./vpn ./client_content ./nginx_client.conf ${CLIENT_HOST}:demo/
# 	rsync -rvz ./client_content ${CLIENT_HOST}:demo/
# 	rsync -rvz ./nginx_client.conf ${CLIENT_HOST}:demo/
	rsync -rvz ./docker-compose-client.yml ${CLIENT_HOST}:demo/docker-compose.yml

run_client:
	ssh ${CLIENT_HOST} 'cd demo; docker-compose -f docker-compose-client.yml up'
	
clean:
	${DCOMPOSE} down --remove-orphans
	rm -rf vpn
	rm -rf openvpn-data

	
# Utilities for checking the configuration

clients:
	${DRUN} ovpn_listclients

bash:
	${DCOMPOSE} exec openvpn bash -l


reload:
	${DRUN} ovpn_genconfig

upload:
	sudo chown -R tim:tim ${OVPN_DATA}
	rsync -rvz ${OVPN_DATA} tart@tart.elec.ac.nz:openvpn/
