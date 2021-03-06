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

    install_apt_packages
    install_microsoft_apt_packages

    replace_system_snap_packages
    install_snap_packages

    install_vscode
    install_discord
    install_viber

    install_teamviewer

    install_minecraft

    install_typora_themes

    install_extensions
    configure_extensions

    install_tresorit

    install_dotbash

    if [[ -n $LAPTOP ]]; then
        install_laptop_apt_packages
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

add_signal_repo()
{
    if [[ ! -e /etc/apt/sources.list.d/signal-xenial.list ]]; then
        wget -qO - https://updates.signal.org/desktop/apt/keys.asc | sudo apt-key add -
        echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
    fi
}

add_typora_repo()
{
    wget -qO - https://typora.io/linux/public-key.asc | sudo apt-key add -
    sudo add-apt-repository 'deb https://typora.io/linux ./'
}

add_microsoft_repo()
{
    wget -q https://packages.microsoft.com/config/ubuntu/${DISTRIB_RELEASE}/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
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

install_microsoft_apt_packages()
{
    if [[ $(apt-cache search "^dotnet-sdk-3.1$") ]]; then
        sudo apt install -y dotnet-sdk-3.1
    else
        echo ".NET Core SDK 3.1 cannot be found."
    fi
    
    if [[ $(apt-cache search "^dotnet-sdk-5.0$") ]]; then
        sudo apt install -y dotnet-sdk-5.0
    else
        echo ".NET Core SDK 5.0 cannot be found."
    fi

    if [[ $(apt-cache search "^powershell$") ]]; then
        sudo apt install -y powershell
    else
        echo "PowerShell Core cannot be found."
    fi
}

install_snap_packages()
{
    sudo snap install telegram-desktop
}

install_apt_packages()
{
    sudo apt update

    sudo apt install -y \
        keepassxc \
        libreoffice \
        kolourpaint \
        gnome-tweaks \
        gnome-calendar \
        compizconfig-settings-manager \
        gnome-photos \
        yubikey-personalization-gui \
        typora \
        remmina \
        curl \
        openssh-server \
        git \
        net-tools \
        xclip \
        debconf-utils \
        signal-desktop \
        htop \
        lm-sensors \
        qrencode \
        gnome-weather \
        cryptsetup \
        wireguard-dkms
}

install_minecraft()
{
    wget https://launcher.mojang.com/download/Minecraft.deb
    sudo apt install -y ./Minecraft.deb
}

install_vscode()
{
    wget -O vscode.deb https://go.microsoft.com/fwlink/?LinkID=760868
    sudo apt install -y ./vscode.deb
}

install_discord()
{
    wget https://dl.discordapp.net/apps/linux/0.0.13/discord-0.0.13.deb -O discord.deb
    sudo apt install -y ./discord.deb
}

install_viber()
{
    wget https://download.cdn.viber.com/cdn/desktop/Linux/viber.deb
    if [[ $(apt-cache search "^libssl1.0.0$") ]]; then
        sudo apt install -y ./viber.deb
    elif [[ $(apt-cache search "^libssl1.1$") ]]; then
        dpkg-deb -x viber.deb viber
        dpkg-deb --control viber.deb viber/DEBIAN
        sed -i -e 's/libssl1.0.0/libssl1.1/g' viber/DEBIAN/control
        dpkg -b viber viber-with-libssl1.1.deb
        sudo apt install ./viber-with-libssl1.1.deb
    fi
}

install_teamviewer()
{
    wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb -O teamviewer.deb
    sudo apt install -y ./teamviewer.deb
}

install_tresorit()
{
    wget https://installerstorage.blob.core.windows.net/public/install/tresorit_installer.run
    sh ./tresorit_installer.run
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
            "lockkeys@vaina.lt"
            "panel-osd@berend.de.schouwer.gmail.com"
            "sound-output-device-chooser@kgshank.net"
            "tweaks-system-menu@extensions.gnome-shell.fifi.org"
            "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
            "remove-alt-tab-delay@tetrafox.pw"
        )

        for extension_uuid in ${EXTENSIONS[@]}; do
            install_gnome_extension $extension_uuid
            enable_gnome_extension $extension_uuid
        done
    fi    
}

install_gnome_extension()
{
    EXTENSION_UUID=$1

    wget -qO /tmp/$EXTENSION_UUID.zip https://extensions.gnome.org/download-extension/$EXTENSION_UUID.shell-extension.zip?shell_version=$GDM_VERSION

    if [[ -x "$(command -v gnome-extensions)" ]]; then
        gnome-extensions install /tmp/$EXTENSION_UUID.zip
    else
        mkdir -p ~/.local/share/gnome-shell/extensions/$EXTENSION_UUID
        unzip -n /tmp/$EXTENSION_UUID.zip -d ~/.local/share/gnome-shell/extensions/$EXTENSION_UUID
    fi

    rm /tmp/$EXTENSION_UUID.zip
}

enable_gnome_extension()
{
    EXTENSION_UUID=$1

    if [[ -x "$(command -v gnome-extensions)" ]]; then
        gnome-extensions enable $EXTENSION_UUID
    else
        gnome-shell-extension-tool -e $EXTENSION_UUID
    fi
}

disable_gnome_extensions()
{
    EXTENSION_UUID=$1

    if [[ -x "$(command -v gnome-extensions)" ]]; then
        gnome-extensions disable $EXTENSION_UUID
    else
        gnome-shell-extension-tool -d $EXTENSION_UUID
    fi
}

configure_extensions()
{
    wget -qO /tmp/dash-to-panel.conf https://raw.githubusercontent.com/stigvoss/dconf-files/master/dash-to-panel.conf
    dconf load /org/gnome/shell/extensions/dash-to-panel/ < /tmp/dash-to-panel.conf
}

install_dotbash()
{
    # TODO: Download and install dotbash from Git.

    # bash <(curl -s https://dotbash.stigvoss.dk/install.sh)

    echo "Install dotbash"
}

install
