## Reverse proxying to a docker-container behind a firewall

This demo shows how to connect a docker-container behind a firewall, to a container 
in front of the firewall runing nginx that reverse proxies back to the client server behind the firewall.

## How it works

The server will operate an openvpn server container. This container will allow other hosts to connect and allocate them
an IP in the address range 10.0.0.0/24. OpenVPN credentials are created by the 'make client' command. 

The following shows the steps that are done to create a client configuration. This will create a file called signal.ovpn that 
will be needed by the client to authenticate to the server.


	CLIENTNAME=signal
	CLIENTIP=33

	mkdir -p vpn
	${DRUN} easyrsa build-client-full ${CLIENTNAME} nopass
	${DRUN} ovpn_getclient ${CLIENTNAME} > ./vpn/${CLIENTNAME}.ovpn
	${DRUN} mkdir -p /etc/openvpn/ccd
	${DRUN} touch /etc/openvpn/ccd/${CLIENTNAME}
	echo ifconfig-push 10.0.0.${CLIENTIP} 255.255.255.0 | ${DRUN}  tee /etc/openvpn/ccd/${CLIENTNAME}


    make server_setup

### Links

- https://www.youtube.com/watch?v=OXjrBvSYB9o
- https://github.com/kylemanna/docker-openvpn/issues/358
- https://openvpn.net/community-resources/how-to/#policy