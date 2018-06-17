#!/bin/sh
FLAGS=${FLAGS:-"-td"}
NETWORK=${NETWORK:-"kazoo"}
NAME=${NAME:-"freeswitch.$NETWORK"}
KAMAILIO=${KAMAILIO:-"kamailio.$NETWORK"}
RABBITMQ=${RABBITMQ:-"rabbitmq.$NETWORK"}
RTP_START_PORT=${RTP_START_PORT:-"10000"}

if [ -n "$(docker ps -aq -f name=$NAME)" ]
then
   echo -n "stopping: "
   docker stop -t 1 $NAME
   echo -n "removing: "
   docker rm -f $NAME
fi
echo -n "starting: $NAME "
docker run $FLAGS \
	--net $NETWORK \
	-h $NAME \
	--name $NAME \
	--env RABBITMQ=$RABBITMQ \
	--env RTP_START_PORT=$RTP_START_PORT \
	--env EXT_IP=$EXT_IP \
	2600hz/freeswitch:alpine-edge

echo -n "adding dispatcher $NAME to kamailio $KAMAILIO "
docker exec $KAMAILIO dispatcher_add.sh 1 $NAME

# idk why do i need this, but kamailio forwards to $EXT_IP:11000
IP=$(bin/get-ip.sh $NETWORK $NAME)
IF=$(ip route get $IP | grep dev | awk '{ print $3 }')
iptables -t nat -A PREROUTING -i $IF -p udp --dport 11000 -j DNAT --to-destination $IP:11000
