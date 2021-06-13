# Reverse proxying to a docker-container behind a firewall

Author: Tim Molteno tim@molteno.net. 


This demo shows how to connect a docker-container behind a firewall, to a container 
in front of the firewall runing nginx that reverse proxies back to the client server behind the firewall. 
Please let me know if you find other ways to do this.

## How it works

The server will operate an openvpn server container. This container will allow other hosts to connect and allocate them
an IP in the address range 10.0.0.0/24. OpenVPN credentials are created by the 'make client' command. 

## Client Setup

Each client has a service that is an openvpn client. This client will be running other services that should be connected to the
remote server. In this example that is just a small nginx webserver that contains a single static page.

### Client Credentials

The following shows the steps that are done to create a client configuration. This will create a file called signal.ovpn that 
will be needed by the client to authenticate to the server. These steps are carried out on the server container.


    CLIENTNAME=signal
    CLIENTIP=33

    mkdir -p vpn
    easyrsa build-client-full ${CLIENTNAME} nopass
    ovpn_getclient ${CLIENTNAME} > ./vpn/${CLIENTNAME}.ovpn
    mkdir -p /etc/openvpn/ccd
    touch /etc/openvpn/ccd/${CLIENTNAME}
    echo ifconfig-push 10.0.0.${CLIENTIP} 255.255.255.0 | tee /etc/openvpn/ccd/${CLIENTNAME}



### Server Setup

The server requires a suitable certificate authority (CA) and this is done by the 'make server_setup' command

    ovpn_genconfig -s "10.0.0.0/24" \
		-r "10.0.0.0/24" \
		-e 'topology subnet' -E 'topology "subnet"' \
		-D -z -b -c -u udp://${DOCKER_HOST}
    ovpn_genconfig -u udp://${DOCKER_HOST}
    ovpn_initpki


Each client is then allocated a hostname in the servers docker-compose.yml file. In the example below, the 10.0.0.33 host can be given the hostname
'client.a' which can be used for reverse proxying

    extra_hosts:
        - client.a:10.0.0.33
        - client.b:10.0.0.22

### Links

- https://www.youtube.com/watch?v=OXjrBvSYB9o
- https://github.com/kylemanna/docker-openvpn/issues/358
- https://openvpn.net/community-resources/how-to/#policy