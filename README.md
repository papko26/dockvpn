# OpenVPN for Docker with cloacking

Containers based on this image will serve openVPN on 443 port. All configs will be generated on fly, and placed in mounted directory on host (/etc/openvpn/ by default). As a disguise, container will also serve web server on 443 and 80 ports, and redirect http/s trafic to dummy site (can be set in args).

Quick instructions:

```bash
#On server side
root@vpn-server:/# docker run -d --privileged -v /etc/openvpn:/etc/openvpn -p 443:443/tcp -p80:80  papko26/dockvpn [ (optional) server.dns.name dummy-redirect.site ]
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
root@vpn-server:/# docker run -d --privileged -v /etc/openvpn:/etc/openvpn -p 443:443/tcp -p80:80  papko26/dockvpn [ (optional) server.dns.name dummy-redirect.site ]
root@vpn-server:/# curl -s ifconfig.co
x.x.x.x
#On client side
root@vpn-client:/$ scp root@x.x.x.x:/etc/openvpn/client.ovpn .
root@vpn-client:/$ openvpn --config client.ovpn
```

## How does it work?

Logic is based on the `jpetazzo/dockvpn` image? so when it is started, it generates:

- Diffie-Hellman parameters,
- a private key,
- a self-certificate matching the private key,
- two OpenVPN server configurations (for UDP and TCP),
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


## Security discussion

For simplicity, the client and the server use the same private key and
certificate. This is certainly a terrible idea. If someone can get their
hands on the configuration on one of your clients, they will be able to
connect to your VPN, and you will have to generate new keys. Which is,
by the way, extremely easy, since each time you `docker run` the OpenVPN
image, a new key is created. If someone steals your configuration file
(and key), they will also be able to impersonate the VPN server (if they
can also somehow hijack your connection).

It would probably be a good idea to generate two sets of keys.

It would probably be even better to generate the server key when
running the container for the first time (as it is done now), but
generate a new client key each time the `serveconfig` command is
called. The command could even take the client CN as argument, and
another `revoke` command could be used to revoke previously issued
keys.

## Verified to work with ...

People have successfully used this VPN server with clients such as:

- OpenVPN on Linux,
- OpenVPN on Iphone 6,
- OpenVPN Client on Mikrotik hAP


## All credits to 
[dockvpn](https://github.com/jpetazzo/dockvpn)