###################### 路由表设置
ip route add local default dev lo table 100
ip rule add fwmark 1 table 100


###################### 局域网流量设置
# 开启　net.ipv4.ip_forward=1
sysctl -w net.ipv4.ip_forward=1
# 设置iptables规则，排除掉一些特殊地址和内网地址的流量
iptables -t mangle -N SING_BOX
iptables -t mangle -A SING_BOX -d 100.64.0.0/10 -j RETURN
iptables -t mangle -A SING_BOX -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A SING_BOX -d 169.254.0.0/16 -j RETURN
iptables -t mangle -A SING_BOX -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A SING_BOX -d 192.0.0.0/24 -j RETURN
iptables -t mangle -A SING_BOX -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A SING_BOX -d 240.0.0.0/4 -j RETURN
iptables -t mangle -A SING_BOX -d 255.255.255.255/32 -j RETURN
# 修改为你的内网网段；也可以用10.0.0.0/8
iptables -t mangle -A SING_BOX -d 10.0.0.0/8 -p udp ! --dport 53 -j RETURN
# sing-box机器同时是网关，同时也是dns server，所以如果目标ip是自己的53端口，那么也要RETURN
# dns流量交给clash mihomo来处理，然后拿到结果后再返回给局域网其他机器
iptables -t mangle -A SING_BOX -d 10.0.1.114 -p udp --dport 53 -j RETURN
# 修改为你的透明代理程序的端口
iptables -t mangle -A SING_BOX -p tcp -j TPROXY --on-port 12345 --tproxy-mark 1
iptables -t mangle -A SING_BOX -p udp -j TPROXY --on-port 12345 --tproxy-mark 1
iptables -t mangle -A PREROUTING -j SING_BOX


###################### 本机流量设置
iptables -t mangle -N SING_BOX_SELF
iptables -t mangle -A SING_BOX_SELF -d 100.64.0.0/10 -j RETURN
iptables -t mangle -A SING_BOX_SELF -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A SING_BOX_SELF -d 169.254.0.0/16 -j RETURN
iptables -t mangle -A SING_BOX_SELF -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A SING_BOX_SELF -d 192.0.0.0/24 -j RETURN
iptables -t mangle -A SING_BOX_SELF -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A SING_BOX_SELF -d 240.0.0.0/4 -j RETURN
iptables -t mangle -A SING_BOX_SELF -d 255.255.255.255/32 -j RETURN
# 把ssh客户端通信的流量排除掉，防止把自己锁住无法登录
iptables -t mangle -A SING_BOX_SELF -p tcp --sport 22 -j RETURN
iptables -t mangle -A SING_BOX_SELF  -j RETURN -m mark --mark 1234

# 修改为你的内网网段
iptables -t mangle -A SING_BOX_SELF -d 10.0.0.0/8 -p udp ! --dport 53 -j RETURN
# sing-box机器同时是网关，同时也是dns server，所以如果目标ip是自己的53端口，那么也要RETURN
# dns流量交给clash mihomo来处理，然后拿到结果后再返回给局域网其他机器
# 出方向上放行，不要环路了
iptables -t mangle -A SING_BOX_SELF -s 10.0.1.114 -p udp --sport 53 -j RETURN
iptables -t mangle -A SING_BOX_SELF -p tcp -j MARK --set-mark 1
iptables -t mangle -A SING_BOX_SELF -p udp -j MARK --set-mark 1
iptables -t mangle -A OUTPUT -j SING_BOX_SELF

#如果本级也作为nat网关的话，也可以增加如下路由；默认启用吧
iptables -t nat -A POSTROUTING -j MASQUERADE