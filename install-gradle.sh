#!/bin/bash

# Inspiration came from the website below:
# https://www.0x90.se/build-ghidra-10-from-source/#build-ghidra


export SUDO=`which sudo 2> /dev/null`


function install_java {

  echo "Checking to see if Java is installed..."
  PKG_OK=$(dpkg-query -W --showformat='${Status}\n' openjdk-11-jdk | grep "install ok installed")

  if [ "" == "$PKG_OK" ]; then
    echo "Downloading JDK .. please wait..."
    sudo add-apt-repository ppa:openjdk-r/ppa -y > /dev/null 2>&1
    sudo apt update
    sudo apt install openjdk-11-jdk -y
  fi
}


#Checking to see if Java JDK is installed if not Install it first
install_java


wget https://services.gradle.org/distributions/gradle-7.1-bin.zip
unzip gradle-7.1-bin.zip

$SUDO cp -R gradle-7.1 /usr/local/gradle
$SUDO echo "export PATH=/usr/local/gradle/bin:$PATH" > /etc/profile.d/gradle.sh
source /etc/profile.d/gradle.sh