#!/bin/bash
INSTALL_DIR=/usr/share

export WGET=`which wget`
export SUDO=`which sudo 2> /dev/null`
test -e ./install-ghidra.sh || { echo Error: you must run the script from the ./install_ghidra/ directory ; exit 1 ; }
test -z "$WGET" && { echo Error: wget not found ; exit 1 ; }


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

#Turning off 4K scaling
function 4k_scaling {
  
  read -p "Shall I change scaling to factor 2 for 4K [Y/N]? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
      sed -i 's/VMARGS_LINUX=-Dsun.java2d.uiScale=1/VMARGS_LINUX=-Dsun.java2d.uiScale=2/g' /opt/ghidra/support/launch.properties
  fi

}

#Allow for .desktop file to execute without having to right click and slect "Alow Launching"
function allow_desktop_launching {
  
  #This is for Ubuntu 22.04 might throw an error on Xubuntu
  cp ghidra.desktop $HOME/.local/share/applications/ghidra.desktop
  #Allow for launching without having to right click on the desktop file and select "Allow Launching"
  gio set ~/Desktop/ghidra.desktop metadata::trusted true
  chmod a+x ~/Desktop/ghidra.desktop

}

function download_ghidra {

  #Link where to find Ghidra
  export GHIDRA_LINK=`$WGET -O - --quiet  https://github.com/NationalSecurityAgency/ghidra/releases/latest | grep 'releases/download/' | sed 's/.*href=..//' | sed 's/".*//' | tail -1`
  test -z "$GHIDRA_LINK" && { echo Error: could not find ghidra to download ; exit 1 ; }

  #Strip the link parts to just keep the zip file name
  export GHIDRA=`echo $GHIDRA_LINK | sed 's/^.*\(ghidra.*\).*$/\1/' `

  # This should result in the unpack directory in the ZIP
  export GHIDRA_DIR=`echo $GHIDRA | sed 's/_20[12][0-9].*//' `

  # This should be the Ghidra Version
  export GHIDRA_VER=`echo $GHIDRA | sed 's/_PUBLIC_.*//' | sed 's/_DEV_.*//' | sed 's/-BETA_.*//'`

  # Check for common errors
  echo " $GHIDRA" | sed 's/^.*\(ghidra.*\).*$/\1/' | egrep -q '/' && { echo Error: invalid ghidra filename ; exit 1 ; }
  echo " $GHIDRA" | sed 's/^.*\(ghidra.*\).*$/\1/' | egrep -q '.zip' || { echo Error: invalid ghidra filename ; exit 1 ; }
  test -d "$INSTALL_DIR" || { echo Error: install directory $INSTALL_DIR does not exist ; exit 1 ; }

  # Print the latest version of Ghidra, and check if it is already installed
  echo "Checking to see if $GHIDRA_VER is already installed..."
  #Check to see if this version is already installed
  test -e $INSTALL_DIR/$GHIDRA_VER && { echo Error: $GHIDRA_VER is already installed ; exit 1 ; }

  echo "Downloading $GHIDRA with version $GHIDRA_VER"
  echo
  wget -c --quiet "https://github.com/$GHIDRA_LINK" || exit 1

  echo "Checking Hashes..."
  export DOWNLOADHASH=`wget -O - --quiet  https://github.com/NationalSecurityAgency/ghidra/releases/latest | grep 'SHA-256:' | grep 'code' | sed 's:.*<code>\(.*\)</code>.*:\1:p' | tail -1`
  test -z "$DOWNLOADHASH $GHIDRA | sha256sum --check" && { echo Error: hashes do not match ; exit 1; }
  echo $DOWNLOADHASH $GHIDRA | sha256sum --check

}

function unzip_ghidra {

  unzip "$GHIDRA" > /dev/null || exit 1
  mv "$GHIDRA_DIR" "$GHIDRA_VER"
  
  cp -f ghidra $GHIDRA_VER/
  cp -f ghidra.png $GHIDRA_VER/
  
  #Removing the symlink ghidra
  $SUDO rm -rf $INSTALL_DIR/ghidra
  $SUDO mv $GHIDRA_VER $INSTALL_DIR/ || exit 1
  #Remove the unzipped Ghidra folder
  rm $GHIDRA

}

function copy_desktop_file {

  for dir in Desktop ; do
    test -d $HOME/$dir && {
      cp ghidra.desktop $HOME/$dir/ghidra.desktop
      chown $USER:$USER $HOME/$dir/ghidra.desktop
    }
  done
  
}

function final_setup {

  $SUDO rm -f /usr/bin/ghidra /usr/local/bin/ghidra 
  $SUDO ln -s $INSTALL_DIR/ghidra/ghidraRun /usr/local/bin/ghidra

  cd $INSTALL_DIR || exit 1
  OLD_DIR=`readlink ghidra`
  $SUDO ln -sf $GHIDRA_VER ghidra

  test -n "$OLD_DIR" && {
    echo "Syncing from previous ghidra direcory: $OLD_DIR"
    RSYNC=`command -v rsync 2> /dev/null`
    test -n "$RSYNC" && {
      echo "Running $RSYNC to synchronize custom scripts to the new installation"
      rsync -v -r --ignore-existing --exclude='*/jython*' "$DIR/Ghidra/" "$GHIDRA_VER/Ghidra/"
    }
    test -z "$RSYNC" && {
      echo "Warning: rsync not found, using old and incomplete copy process ..."
      echo "Copying customized scripts from $DIR to $GHIDRA_VER"
      for dir in $OLD_DIR/Ghidra/*/*/ghidra_scripts/; do
        cp -nrv "$DIR/$dir"/* "$GHIDRA_VER/$dir/" 2> /dev/null
      done
    }
  }

  GHIDRACFG=`echo .$GHIDRA_VER | tr _ -`
  cd $HOME/.ghidra && {
    DIR=
    rm -rf $GHIDRACFG
    ls -td .ghidra-* | while read dir; do
      test '!' -L "$dir" -a -d "$dir" -a -z "$DIR" && {
        DIR=$dir
        ln -s $dir $GHIDRACFG
        echo "Symlinking $HOME/.ghidra/$dir to $HOME/.ghidra/$GHIDRACFG"
      }
    done
  }

}

function setup_ghidra_folder {

  cp $Custom_Zip .
  export GHIDRA=`echo $Custom_Zip | sed 's/^.*\(ghidra.*\).*$/\1/' `
  export GHIDRA_DIR=`echo $GHIDRA | sed 's/_20[12][0-9].*//' `
  export GHIDRA_VER=`echo $GHIDRA | sed 's/_PUBLIC_.*//' | sed 's/_DEV_.*//' | sed 's/-BETA_.*//'`
  
}

#Checking to see if Java JDK is installed if not Install it first
install_java

#Y/N prompt to install ghidra
while true; do

  read -p "Do you want to use your custom Ghidra build (y/n) " yn

  case $yn in 
  	[yY] )
      read -p "Input the filepath to your custom Ghidra zipfile " Custom_Zip
      echo "Installing custom Ghidra to $INSTALL_DIR ..."
      echo "Unpacking Ghidra ..."
      setup_ghidra_folder
      unzip_ghidra
      echo "Copying .desktop file and allowing for execution ..."
      copy_desktop_file
      allow_desktop_launching
      final_setup
      4k_scaling
      echo "Successfully installed custom Ghidra version $GHIDRA_VER to $INSTALL_DIR/$GHIDRA_DIR"
      echo "Run using: ghidra"
  		break;;

  	[nN] ) 
      echo "Downloading Ghidra and installing to $INSTALL_DIR"
      echo "Downloading Official release from Github ...";
      download_ghidra
      echo "Unpacking Ghidra ..."
      unzip_ghidra
      echo "Copying .desktop file and allowing for execution ..."
      copy_desktop_file
      allow_desktop_launching
      final_setup
      4k_scaling
      echo "Successfully installed Ghidra version $GHIDRA_VER to $INSTALL_DIR/$GHIDRA_DIR"
      echo "Run using: ghidra"
      exit;;

  	* ) echo invalid response;;
  esac
done
