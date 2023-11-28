#!/bin/bash

# TODO add coloring of outputs
# TODO add clearing whole infrastructure

# 1: sudo -s      # It will allow to run all comands with root privileges
# 2: chmod u+x configuration.sh     # For running this script

configuration_type="$1"

case "$configuration_type" in
	"1") # Installation phase

        # Downloading and installing latest version of Docker
        sudo apt update
        sudo apt install apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -    # Official Docker repository
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"    # Adding Docker repository as default in apt sources
        apt-cache policy docker-ce  # Checking current cache of apt
        sudo apt install docker-ce
        sudo systemctl status docker    # Checking if Docker is running

        # Installing wireshark
        sudo apt install wireshark -y
		;;
	"2") # Preparing project environment

        # Creating network infrastructure
        sysctl -w net.ipv4.ip_forward=0 # It has to be disabled because routing will be determined by IP and MAC (not only mAC like we want)
        docker network create --driver=bridge --subnet=10.0.0.0/24 --gateway=10.0.0.1 pcyb-network  # Creating virtual network that docker container can connect to

        # Building images for hosts and running containers
        docker image build -f dockerfiles/normal-host-Dockerfile -t normal-host-image .
        docker image build -f dockerfiles/man-in-the-middle-Dockerfile -t man-in-the-middle-image .

        docker container run -dt -e PS1='host-green # ' --network pcyb-network --ip 10.0.0.100 --hostname host-green --name host-green normal-host-image
        docker container run -dt -e PS1='host-blue # ' --network pcyb-network --ip 10.0.0.101 --hostname host-blue --name host-blue normal-host-image
        docker container run -dt -e PS1='host-red # ' --network pcyb-network --ip 10.0.0.102 --hostname host-red --name host-red man-in-the-middle-image

        # docker exec -it <container-id> /bin/sh    # Entering container shell (sh, bash etc)

        docker images
        docker container list
        docker network list
		;;
	"3") # Managing hosts - Get networking info

        # Getting information about IP and MAC addresses of hosts containers
        green_id=$(docker ps -q --filter "name=host-green")
        blue_id=$(docker ps -q --filter "name=host-blue")
        red_id=$(docker ps -q --filter "name=host-red")

        echo -e "\nhost-green"
        docker exec -it "$green_id" /bin/sh -c "ip a"
        echo -e "\nhost-blue"
        docker exec -it "$blue_id" /bin/sh -c "ip a"
        echo -e "\nhost-red"
        docker exec -it "$red_id" /bin/sh -c "ip a"

        echo -e "\nhost-green"
        docker exec -it "$green_id" /bin/sh -c "arp"
        echo -e "\nhost-blue"
        docker exec -it "$blue_id" /bin/sh -c "arp"
        echo -e "\nhost-red"
        docker exec -it "$red_id" /bin/sh -c "arp"
        ;;
    "4") # Managing hosts - ARP spoofing
        
        red_id=$(docker ps -q --filter "name=host-red")
        docker exec -it "$red_id" /bin/sh -c "python3 Man-In-The-Middle.py eth0 10.0.0.100 10.0.0.101"
        # docker exec -it "$red_id" /bin/sh -c 'ps aux | grep "python3 arpPoisoner.py eth0 10.0.0.100 10.0.0.101" | grep -v grep | awk "{print \$1}" | xargs -r kill'
		
        ;;  
    "5") # Managing hosts - Transmitting packets through host-red

        red_id=$(docker ps -q --filter "name=host-red")
        docker exec -it "$red_id" /bin/sh -c "python3 Forwarding.py eth0 10.0.0.100 10.0.0.101"        
        ;;
    "6") # Cleanup
        # Cleaning environment
        red_id=$(docker ps -q --filter "name=host-red")
        docker exec -it "$red_id" /bin/sh -c 'ps aux | grep "python3 Man-In-The-Middle.py eth0 10.0.0.100 10.0.0.101" | grep -v grep | awk "{print \$1}" | xargs -r kill'
		docker exec -it "$red_id" /bin/sh -c 'ps aux | grep "python3 Forwarding.py eth0 10.0.0.100 10.0.0.101" | grep -v grep | awk "{print \$1}" | xargs -r kill'
		
        docker rm -f $(docker ps -aq)    # removing all containers
        docker rmi -f $(docker images -q)   # removing all images
        ;;
esac

