FROM ubuntu:bionic
RUN apt-get update -q
RUN apt-get install -qy openvpn iptables haproxy curl
ADD ./bin /usr/local/sbin
VOLUME /etc/openvpn
EXPOSE 443/tcp
CMD run
