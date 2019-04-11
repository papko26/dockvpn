FROM ubuntu:bionic
RUN apt-get update -q
RUN apt-get install -qy openvpn iptables haproxy curl obfsproxy host
ADD ./bin /usr/local/sbin
VOLUME /etc/openvpn
EXPOSE 443/tcp 80/tcp
ENTRYPOINT ["bash", "/usr/local/sbin/run"]
