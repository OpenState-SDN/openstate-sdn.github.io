#!/usr/bin/env bash

# OpenState install script for Mininet 2.2.1 on Ubuntu 14.04
# (https://github.com/mininet/mininet/wiki/Mininet-VM-Images)
# This script is based on "Mininet install script" by Brandon Heller
# (brandonh@stanford.edu)
#
# Authors: Davide Sanvito, Luca Pollini, Carmelo Cascone

# Exit immediately if a command exits with a non-zero status.
set -e

# Exit immediately if a command tries to use an unset variable
set -o nounset

function of13 {
    echo "Installing OpenState switch implementation based on ofsoftswitch13..."
    
    cd ~/
    sudo apt-get -y install git-core autoconf automake autotools-dev pkg-config \
        make gcc g++ libtool libc6-dev cmake libpcap-dev libxerces-c2-dev  \
        unzip libpcre3-dev flex bison libboost-dev

    # Install netbee
    NBEEURL="http://www.nbee.org/download/"
    NBEESRC="nbeesrc-feb-24-2015"
    NBEEDIR="netbee"

    if [ ! -d ${NBEEDIR} ]; then
        wget -nc ${NBEEURL}${NBEESRC}.zip
        unzip ${NBEESRC}.zip
    fi
    cd ${NBEEDIR}/src
    cmake .
    make
    cd ~/
    sudo cp ${NBEEDIR}/bin/libn*.so /usr/local/lib
    sudo ldconfig
    sudo cp -R ${NBEEDIR}/include/ /usr/

    if [ -d "ofsoftswitch13" ]; then
        read -p "A directory named ofsoftswitch13 already exists, by proceeding \
it will be deleted. Are you sure? (y/n) " -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf ~/ofsoftswitch13
        else
            echo "User abort!"
            return -1
        fi
    fi
    git clone https://github.com/OpenState-SDN/ofsoftswitch13.git

    # Resume the install:
    cd ~/ofsoftswitch13
    ./boot.sh
    ./configure
    make
    sudo make install
    cd ~/
    
    sudo chown -R mininet:mininet ~/ofsoftswitch13
}

# Install RYU
function ryu {
    echo "Installing RYU controller with OpenState support..."

    # install Ryu dependencies"
    sudo apt-get -y install autoconf automake g++ libtool python make libxml2 \
        libxslt-dev python-pip python-dev python-matplotlib

    sudo pip install gevent pbr==0.11 pulp networkx fnss
    sudo pip install -I six==1.9.0

    # fetch RYU
    cd ~/
    if [ -d "ryu" ]; then
        read -p "A directory named ryu already exists, by proceeding it will be \
deleted. Are you sure? (y/n) " -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf ~/ryu
        else
            echo "User abort!"
            return -1
        fi
    fi
    git clone https://github.com/OpenState-SDN/ryu.git ryu
    cd ryu
    
    # install ryu
    sudo python ./setup.py install

    # Add symbolic link to /usr/bin
    # sudo ln -fs ./bin/ryu-manager /usr/local/bin/ryu-manager
    sudo chown -R mininet:mininet ~/ryu
}

sudo apt-get update
~/mininet/util/install.sh -nt
ryu
of13

echo "All set! To start using OpenState please refer to \
http://openstate-sdn.org for some example applications."
