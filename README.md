pwsh-vault - Basic Password Manager written in Bash+Dmenu
=========================================================

### Dependencies:
  
  * **Arch Linux:**
    * `sudo pacman -S git gcc make coreutils sed expat zip unzip freetype2 libxinerama brotli fontconfig libbsd libmd libpng libx11 libxau libxdmcp libxft libxrender` 

  * **Debian/Ubuntu:**
    * `sudo apt install git gcc make coreutils sed zip unzip libexpat1-dev libfreetype-dev libxinerama-dev x11-utils libxft-dev libfreetype6-dev libfontconfig1-dev libpng-dev libbrotli-dev libxrender-dev libmd-dev libxau-dev libbsd-dev libxdmcp-dev`

  * **Windows Cygwin ([apt-cyg](https://github.com/transcode-open/apt-cyg)):**
    * `apt-cyg install git make coreutils sed zip unzip`
    
  * **Android ([Termux](https://termux.com/)):**
    * `pkg install git make coreutils sed zip unzip`

### Build and install (Unix/Linux Posix):

* Open terminal and run the following commands:

  ```shell
  $ git clone https://github.com/q3aql/pwsh-vault.git
  $ cd pwsh-vault
  $ sudo make install clean
  ````

### Download & install (Windows Cygwin):

* Open terminal and run the following commands:

  ```shell
  $ git clone https://github.com/q3aql/pwsh-vault.git
  $ cd pwsh-vault
  $ make cygwin
  ````

### Download & install (Android Termux):

* Open terminal and run the following commands:

  ```shell
  $ git clone https://github.com/q3aql/pwsh-vault.git
  $ cd pwsh-vault
  $ make termux
  ````

### GUI Version (only for Linux):

  ```shell
  pwsh-vault
  ```

<img src="examples/pwsh-vault.png" /> 

 
### CLI Version:

  ```shell
  pwsh-vault-cli
  ```

<img src="examples/pwsh-vault-cli.png" /> 


  ```shell
  pwsh-vault (or pwsh-vault-cli) --help
  ```

<img src="examples/pwsh-vault-help.png" /> 


### External links:

  * [dmenu homepage](https://tools.suckless.org/dmenu/)
  * [apt-cyg](https://github.com/transcode-open/apt-cyg)
  * [Cygwin](https://www.cygwin.com/)
