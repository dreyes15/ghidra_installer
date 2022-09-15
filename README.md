# ghidra_installer
Helper scripts to set up OpenJDK 11 and scale Ghidra for 4K on Ubuntu 16.x / 18.x / 19.x / 22.x
The script will automatically detect and download the latest reslease of Ghidra from the NSA's github account
Additionally, this scripts allows for for the ubstakk and the setup of custom Ghidra builds,
Finally for convenience, scripts to install Gradle are included.

# To install Ghidra:
   ```
   ~$ sudo apt install git
   ~$ cd /tmp
   /tmp$ git clone https://github.com/bkerler/ghidra_installer
   /tmp$ cd ghidra_installer
   /tmp/ghidra_installer$ ./install-ghidra.sh
   ```

# install gradle:
   ```
    ~$ cd /tmp
   /tmp$ git clone https://github.com/bkerler/ghidra_installer
   /tmp$ cd ghidra_installer
   /tmp/ghidra_installer$ ./install-gradle.sh
   ```