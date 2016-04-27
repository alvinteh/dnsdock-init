#!/bin/bash

# Setup docker machine for Mac platforms
if [[ "$(uname -s)" == *"Darwin"* ]]; then
    # Create a default docker machine if one doesn't already exist
    [[ $(docker-machine ls) != *default* ]] && docker-machine create --driver=virtualbox default

    # Run the default docker machine if it isn't already running
    [[ $(docker-machine status default) != *Running* ]] && docker-machine start default

    # Configure the docker machine environment
    eval "$(docker-machine env default)"
fi

# Extract the IP address of the docker host
if [[ "$(uname -s)" == *"Darwin"* ]]; then
    # Use the IP address of the default docker machine
    DOCKER_HOST_IP="$(docker-machine ip default)"
else
    # Use the IP address of the machine
    DOCKER_HOST_IP="127.0.0.1"
fi

# Determine docker bridge address, bridge network address and bridge subnet mask
# Note that the network bridge IP may not be fixed, to be safe, check the IP by running:
# docker-machine ssh default
# ifconfig docker0 | grep "inet addr"
DOCKER_BRIDGE_IP=172.17.0.1
DOCKER_BRIDGE_NETWORK_ADDRESS=
DOCKER_BRIDGE_NETWORK_SUBNET_MASK=
if [[ $DOCKER_BRIDGE_IP == "192."* ]]; then
    DOCKER_BRIDGE_NETWORK_ADDRESS="$(cut -d'.' -f 1-3 <<< $DOCKER_BRIDGE_IP)"
    DOCKER_BRIDGE_NETWORK_ADDRESS+=".0"
    DOCKER_BRIDGE_NETWORK_SUBNET_MASK=24
elif [[ $DOCKER_BRIDGE_IP == "172."* ]]; then
    DOCKER_BRIDGE_NETWORK_ADDRESS="$(cut -d'.' -f 1-2 <<< $DOCKER_BRIDGE_IP)"
    DOCKER_BRIDGE_NETWORK_ADDRESS+=".0.0"
    DOCKER_BRIDGE_NETWORK_SUBNET_MASK=16
elif [[ $DOCKER_BRIDGE_IP == *"10."* ]]; then
    DOCKER_BRIDGE_NETWORK_ADDRESS="$(cut -d'.' -f 1 <<< $DOCKER_BRIDGE_IP)"
    DOCKER_BRIDGE_NETWORK_ADDRESS+=".0.0.0"
    DOCKER_BRIDGE_NETWORK_SUBNET_MASK=8
fi

# Create the DNS resolver if it doesn't already exist
sudo mkdir -p /etc/resolver >/dev/null 2>&1

# Add nameserver for *.docker URLs
echo "nameserver $DOCKER_BRIDGE_IP" | sudo tee /etc/resolver/docker > /dev/null

# Remove old route entries for DNSDock in case the docker machine IP has changed
sudo route -n delete -net $DOCKER_BRIDGE_NETWORK_ADDRESS

# Add route entries for DNSDock
sudo route -n add $DOCKER_BRIDGE_NETWORK_ADDRESS/$DOCKER_BRIDGE_NETWORK_SUBNET_MASK $DOCKER_HOST_IP
sudo route -n add $DOCKER_BRIDGE_IP/32 $DOCKER_HOST_IP

# Run DNSDock container if it doesn't already exist, or start it otherwise
if [[ $(docker ps -a) != *"tonistiigi/dnsdock"* ]]; then
    docker run --restart=always -d -v /var/run/docker.sock:/var/run/docker.sock --name dnsdock -p $DOCKER_BRIDGE_IP:53:53/udp tonistiigi/dnsdock:v1.10.0
else
    docker start $(docker ps -a | grep -F 'tonistiigi/dnsdock' | awk -F" " '{print $1}')
fi
