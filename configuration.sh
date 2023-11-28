#!/bin/bash

# Necesarry to change if other shell is used

# TODO add coloring of outputs
# TODO add clearing whole infrastructure

# 1: sudo -s      # It will allow to run all comands with root privileges
# 2: chmod u+x configuration.sh     # For running this script

# # Downloading and installing latest version of Docker
# sudo apt update
# sudo apt install apt-transport-https ca-certificates curl software-properties-common
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -    # Official Docker repository
# sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"    # Adding Docker repository as default in apt sources
# apt-cache policy docker-ce  # Checking current cache of apt
# sudo apt install docker-ce
# sudo systemctl status docker    # Checking if Docker is running

# # Installing wireshark
# sudo apt install wireshark -y


# Creating network infrastructure
sysctl -w net.ipv4.ip_forward=0 # TODO check why it has to be configured like this
docker network create --driver=bridge --subnet=10.0.0.0/24 --gateway=10.0.0.1 pcyb-network  # Creating virtual network that docker container can connect to
# TODO add checking if network exists

# Cleaning environment
docker rm -f $(docker ps -aq)    # removing all containers
docker rmi -f $(docker images -q)   # removing all images

# Building images for hosts and running containers
docker image build -f dockerfiles/normal-host-Dockerfile -t normal-host-image .
docker image build -f dockerfiles/man-in-the-middle-Dockerfile -t man-in-the-middle-image .
docker images

docker container run -dt -e PS1='host-green # ' --network pcyb-network --ip 10.0.0.100 --hostname host-green --name normal-host-green normal-host-image
docker container run -dt -e PS1='host-blue # ' --network pcyb-network --ip 10.0.0.101 --hostname host-blue --name normal-host-blue normal-host-image
docker container run -dt -e PS1='host-red # ' --network pcyb-network --ip 10.0.0.102 --hostname host-red --name normal-host-red man-in-the-middle-image
docker container list

# docker exec -it <container-id> /bin/sh    # Entering container shell (sh, bash etc)

docker network list


