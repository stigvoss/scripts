#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

cd /tmp

install()
{
    init

    sudo apt update
    sudo apt upgrade -y

    add_typora_repo
    add_microsoft_repo
    add_signal_repo
    add_wireguard_repo

    install_apt_packages

    replace_system_snap_packages
    install_snap_packages

    install_virtualbox

    install_vscode
    install_discord
    install_viber

    install_teamviewer

    install_minecraft

    install_keepass2_plugins
    install_typora_themes

    install_extensions

    install_tresorit
    install_keybase
    install_protonmail_bridge

    install_dotbash

    if [[ -n $LAPTOP ]]; then
        install_laptop_apt_packages
        install_laptop_extensions
    fi

    sudo apt autoremove -y
}

init()
{
    if [ "$EUID" -eq 0 ]; then
        echo "Please run unprivileged."
        exit
    fi

    if [[ -x "$(command -v gnome-shell)" ]]; then
        GDM_VERSION=$(gnome-shell --version)
        GDM_VERSION=${GDM_VERSION:12}
    fi

    CHASSIS_TYPE=$(sudo dmidecode --string chassis-type)

    LAPTOP=
    if [[ $CHASSIS_TYPE =~ "Laptop" ]] || [[ $CHASSIS_TYPE =~ "Notebook" ]]; then
        LAPTOP=$CHASSIS_TYPE
    fi

    . /etc/lsb-release
}

add_wireguard_repo()
{
    sudo add-apt-repository -y ppa:wireguard/wireguard
}

add_signal_repo()
{
    wget -qO - https://updates.signal.org/desktop/apt/keys.asc | sudo apt-key add -
    echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
}

add_typora_repo()
{
    wget -qO - https://typora.io/linux/public-key.asc | sudo apt-key add -
    sudo add-apt-repository 'deb https://typora.io/linux ./'
}

add_microsoft_repo()
{
    wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb

    sudo add-apt-repository universe

    sudo apt install -y apt-transport-https
}

replace_system_snap_packages()
{
    sudo snap remove gnome-calculator \
        gnome-system-monitor \
        gnome-characters
    sudo apt install -y gnome-calculator \
        gnome-system-monitor \
        gnome-characters
}

install_laptop_apt_packages()
{
    sudo apt install -y \
        tlp \
        tlp-rdw \
        tp-smapi-dkms \
        acpi-call \
        dkms
}

install_snap_packages()
{
    sudo snap install telegram-desktop

    if [[ $DISTRIB_RELEASE == "18.04" ]]; then
        sudo snap install communitheme
    fi
}

install_apt_packages()
{
    sudo apt update

    sudo apt install -y \
        keepass2 \
        libreoffice \
        kolourpaint \
        gnome-tweaks \
        gnome-calendar \
        compizconfig-settings-manager \
        gnome-photos \
        xdotool \
        yubikey-personalization-gui \
        typora \
        remmina \
        curl \
        openssh-server \
        dotnet-sdk-3.0 \
        powershell \
        git \
        net-tools \
        xclip \
        debconf-utils \
        signal-desktop \
        htop \
        wireguard \
        lm-sensors \
        qrencode \
        gnome-weather \
        cryptsetup
}

install_protonmail_bridge()
{
    PKGBUILD=$(curl https://protonmail.com/download/beta/PKGBUILD)

    PACKAGE_VERSION=$(echo "$PKGBUILD" | head -n 4 | tail -n 1)
    PACKAGE_RELEASE=$(echo "$PKGBUILD" | head -n 5 | tail -n 1)

    wget https://protonmail.com/download/beta/protonmail-bridge_${PACKAGE_VERSION#pkgver=}-${PACKAGE_RELEASE#pkgrel=}_amd64.deb -O protonmail-bridge.deb

    sudo apt install -y ./protonmail-bridge.deb
}

install_minecraft()
{
    wget https://launcher.mojang.com/download/Minecraft.deb
    sudo apt install -y ./Minecraft.deb
}

install_virtualbox()
{
    # Automatically accept virtualbox-ext-pack license agreement
    echo virtualbox-ext-pack virtualbox-ext-pack/license select true | sudo debconf-set-selections

    sudo apt install -y virtualbox \
        virtualbox-guest-additions-iso \
        virtualbox-ext-pack
    sudo modprobe vboxdrv
}

install_vscode()
{
    wget -O vscode.deb https://go.microsoft.com/fwlink/?LinkID=760868
    sudo apt install -y ./vscode.deb
}

install_discord()
{
    wget https://dl.discordapp.net/apps/linux/0.0.9/discord-0.0.9.deb
    sudo apt install -y ./discord-0.0.9.deb
}

install_viber()
{
    wget https://download.cdn.viber.com/cdn/desktop/Linux/viber.deb
    sudo apt install -y ./viber.deb
}

install_teamviewer()
{
    wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb -O teamviewer.deb
    sudo apt install -y ./teamviewer.deb
}

install_keybase()
{
    curl --remote-name https://prerelease.keybase.io/keybase_amd64.deb
    sudo apt install -y ./keybase_amd64.deb
    run_keybase
}

install_tresorit()
{
    wget https://installerstorage.blob.core.windows.net/public/install/tresorit_installer.run
    sh ./tresorit_installer.run
}

install_keepass2_plugins()
{
    install_keyotp_plugin
    install_keechallenge_plugin
}

install_keyotp_plugin()
{
    wget https://bitbucket.org/devinmartin/keeotp/downloads/KeeOtp-1.3.9.zip
    unzip KeeOtp-1.3.9.zip
    sudo mv ./dlls/* /usr/lib/keepass2/Plugins/
}

install_keechallenge_plugin()
{
    wget https://github.com/brush701/keechallenge/releases/download/1.5/KeeChallenge_1.5.zip
    unzip KeeChallenge_1.5.zip
    sudo mv ./KeeChallenge_1.5/64bit/* /usr/lib/keepass2/Plugins/
    sudo mv ./KeeChallenge_1.5/* /usr/lib/keepass2/Plugins/
}

install_typora_themes()
{
    if [[ ! -e ~/.config/Typora/themes/ ]]; then
        mkdir -p ~/.config/Typora/themes/
    fi

    wget https://github.com/troennes/quartz-theme-typora/archive/master.zip
    unzip master.zip

    mv ./quartz-theme-typora-master/theme/*  ~/.config/Typora/themes/
}

install_extensions() {
    if [[ -x "$(command -v gnome-shell)" ]]; then
        EXTENSIONS=(
            "caffeine@patapon.info"
            "clock-override@gnomeshell.kryogenix.org"
            "freon@UshakovVasilii_Github.yahoo.com"
            "dash-to-panel@jderose9.github.com"
            "gsconnect@andyholmes.github.io"
            "lockkeys@vaina.lt"
            "noannoyance@sindex.com"
            "panel-osd@berend.de.schouwer.gmail.com"
            "sound-output-device-chooser@kgshank.net"
            "suspend-button@laserb"
            "tweaks-system-menu@extensions.gnome-shell.fifi.org"
            "weatherintheclock@JasonLG1979.github.io"
        )

        for extension_uuid in ${EXTENSIONS[@]}; do
            install_gnome_extension $extension_uuid
            gnome-shell-extension-tool -e $extension_uuid
        done
    fi    
}

install_laptop_extensions()
{
    if [[ -x "$(command -v gnome-shell)" ]]; then
            gnome-shell-extension-tool -d "dash-to-panel@jderose9.github.com"

            install_gnome_extension "dash-to-dock@micxgx.gmail.com"
            gnome-shell-extension-tool -e "dash-to-dock@micxgx.gmail.com"
    fi
}

install_gnome_extension()
{
    EXTENSION_UUID=$1

    mkdir -p ~/.local/share/gnome-shell/extensions/$EXTENSION_UUID

    wget -qO /tmp/$EXTENSION_UUID.zip https://extensions.gnome.org/download-extension/$EXTENSION_UUID.shell-extension.zip?shell_version=$GDM_VERSION
    unzip -n /tmp/$EXTENSION_UUID.zip -d ~/.local/share/gnome-shell/extensions/$EXTENSION_UUID
    rm /tmp/$EXTENSION_UUID.zip
}

install_dotbash()
{
    # TODO: Download and install dotbash from Git.

    # bash <(curl -s https://dotbash.stigvoss.dk/install.sh)

    echo "Install dotbash"
}

fetch_sensitive_setup_items()
{
    wget -q https://setup.stigvoss.dk/setup-items.luks

    sudo mkdir -p /mnt/setup-items

    sudo cryptsetup luksOpen setup-items.luks setup-items
    sudo mount /dev/mapper/setup-items /mnt/setup-items

    gedit --new-window /mnt/setup-items/passwords.txt &

    sleep 0.5s

    sudo umount /mnt/setup-items
    sudo cryptsetup luksClose setup-items

    sudo rm -R /mnt/setup-items
    rm setup-items.luks
}

install
