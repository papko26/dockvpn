# OpenVPN for Docker with https cloacking and scramblesuit support

Containers based on this image will serve openVPN on 443 port, and scramblesuit on 80 port.
All configs, certs and keypairs will be generated on fly, and placed in /etc/openvpn/ directory.
As a disguise, container will also serve web server on 443 port, and redirect any https requests to dummy site (can be set in envs).

Quick instructions:

```bash
#On server side
root@vpn-server:/# docker run -d --privileged -v /etc/openvpn:/etc/openvpn -p 443:443/tcp -p80:80  papko26/dockvpn \
 -e SERVER_DNS_NAME=vpn.example.com CLOACK_REDIRECT_HOST="http://www.deere.com"
123exa456ololo
root@vpn-server:/# curl -s ifconfig.co
x.x.x.x
#On client side
root@vpn-client:/$ scp root@x.x.x.x:/etc/openvpn/client.ovpn .
root@vpn-client:/$ openvpn --config client.ovpn
```

Regenerate certificates:
```bash
#On server side
root@vpn-server:/# rm -rf /etc/openvpn/*
root@vpn-server:/# docker run -d --privileged -v /etc/openvpn:/etc/openvpn -p 443:443/tcp -p80:80  papko26/dockvpn \
-e SERVER_DNS_NAME=vpn.example.com CLOACK_REDIRECT_HOST="http://www.deere.com"
root@vpn-server:/# curl -s ifconfig.co
x.x.x.x
#On client side
root@vpn-client:/$ scp root@x.x.x.x:/etc/openvpn/client.ovpn .
root@vpn-client:/$ openvpn --config client.ovpn
```
Scramblesuit channel to overcome DPI and other censorship systems, like china firewall. (Optional, you dont need it, if previus setup is working correctly)
```bash
#On client side
#replace "remote x.x.x.x 443 tcp-client" in client.ovpn to be like "remote 127.0.0.1 2626 tcp-client"
root@vpn-client:/$ apt install -y obfsproxy && mkdir /tmp/scramblesuit/
root@vpn-client:/$ obfsproxy --log-min-severity info --data-dir=/tmp scramblesuit --password KJHVGS2PJVHECRC2J5JFGT2TIFKDCMRS  --dest x.x.x.x:80 client 127.0.0.1:2626 &
root@vpn-client:/$ openvpn --config client.ovpn
```

## How does it work?

Logic is based on the `jpetazzo/dockvpn` image, but with fixes of major security issues (check Keys and Security section) so when it is started, it generates:

- Diffie-Hellman parameters,
- (added) Self signed CA cert and key,
- (added) Server cert and key,
- (added) Client cert and key,
- OpenVPN server configuration,
- an OpenVPN client profile.
- (added) haproxy self-signed certificates
- (added) haproxy config

Then, it starts OpenVPN server process (on 443/tcp), and haproxy (on 80 and 443 for http/s trafic).
The configuration is located (either on docker host and in container, mounted) in /etc/openvpn, so configs could be retrived from here. If directory is empty, certificates will be regenerated.

## OpenVPN details

We use `tun` mode, because it works on the widest range of devices.
`tap` mode, for instance, does not work on Android, except if the device
is rooted.

The topology used is `net30`, because it works on the widest range of OS.
`p2p`, for instance, does not work on Windows.

The TCP server uses `192.168.255.0/25` and the UDP server uses
`192.168.255.128/25`.

The client profile specifies `redirect-gateway def1`, meaning that after
establishing the VPN connection, all traffic will go through the VPN.
This might cause problems if you use local DNS recursors which are not
directly reachable, since you will try to reach them through the VPN
and they might not answer to you. If that happens, use public DNS
resolvers like those of Google (8.8.4.4 and 8.8.8.8) or OpenDNS
(208.67.222.222 and 208.67.220.220).

## Scramblesuit
Scramblesuit server is started on 80 port, when container is started. Its a great tool to overcome censure and other goverment things for restrictions of citizens rights and freedom.
So main idea is to hide (incapsulate) your vpn channel inside scramblesuit channel, so no one between you and server can assume you using VPN.
- Client->VPN->Scramblesuit---(CENSORED INTERNET)---Scrablesuit->VPN---(FREE INTERNET)
- [Learn more about scramblesuit](https://www.cs.kau.se/philwint/scramblesuit/)

https://www.cs.kau.se/philwint/scramblesuit/

## Keys and Security

When container is started for the first time, it generates self-signed CA, server key and client key pairs. For convenience ovpn client config (client.ovpn) is also compiled at container startup. Main idea, that openvpn config directory is mounted to the host server from container (-v /etc/openvpn:/etc/openvpn), so on all subsequent containers startups or restarts, it will use configs generated at first startup. So in case a client or server key is compromized, easiest (and most secure) way is to regenerate either server and client keypairs. You can achive it by removing all content from host /etc/openvpn (rm -rf /etc/openvpn/*) directory and starting/restarting container (check Quick instructions).
By the way, you can suppress mount option (-v /etc/openvpn:/etc/openvpn), to achive certificate regeneration every containter startup. It is not recommended until you surly know, why do you need to use this configuration (first of all, you should find a way to gather client certificate every time when container restarts).

Config file should be distributed over a secure channel, since anyone who owns that file can use your VPN as legal user. My wery best practice - to use scp (check Quick instructions).

## Verified to work with ...

People have successfully used this VPN server with clients such as:

- OpenVPN on Linux,
- OpenVPN on Iphone 6,
- OpenVPN Client on Mikrotik hAP

## TODO:
- Generate scramblesuit pass on fly
- May be letsencrypt support?..


## Credits to 
- [jpetazzo/dockvpn](https://github.com/jpetazzo/dockvpn)
- [x2q/dockvpn](https://github.com/x2q/dockvpn)
