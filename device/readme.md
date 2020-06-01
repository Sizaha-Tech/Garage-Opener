#Setting up Wireless AP

##0. Configure Raspbian OS
    0.1. Brun the image
    0.2. Mount the image on PC/Mac. Add 'ssh' file to boot partition.
    0.3. Reboot Pi, log in with ssh.
    0.4. Change pi password with
        passwd
    0.5. 

##1. Install missing OS packages:

    ### Armbian setup (Orange Pi):
    sudo apt update && sudo apt --yes --force-yes install dnsmasq
    ### sudo apt update && sudo apt --yes --force-yes install dnsmasq hostapd

    sudo apt --yes --force-yes install python3-dev python3-pip python3-venv
    sudo pip3 install setuptools distlib virtualenv

    ### Raspian setup (Raspberry Pi)
    1.1. Install NetworkManager:
       sudo apt update && sudo apt --yes --force-yes install dnsmasq hostapd \
            network-manager openvpn-systemd-resolved rng-tools lsof

        sudo apt purge openresolv dhcpcd5

    1.2. Fix permissions for 'pi' account (not needed for root)
       cp ./Raspian/org.freedesktop.NetworkManager.pkla /var/lib/polkit-1/localauthority/50-local.d/

    1.3. Reboot
       sudo reboot

    ### Install Python goodies:
    
    2.1. Get the latest pip:
        sudo apt --yes --force-yes install python3-distutils python3-venv

        apt-get remove python-pip python3-pip
        wget https://bootstrap.pypa.io/get-pip.py
        python3 get-pip.py
    
    2.2. Create virtual env

        sudo -s
        mkdir -p /app/garage
        cd /app/garage
        python3 -m venv env
        source env/bin/activate

        pip3 install -r device/requirements.txt


##Building and Running Docker image on Raspberry Pi

Needs to be done on Raspberry Pi. 

1. Copy ./device files over to Pi.

2. ssh into Pi and run the following command:

    docker build --pull --rm -f "device/Dockerfile" -t garage_device:latest "device"

3. Save the built image as:

    docker save garage_device:latest | gzip > garage_device_latest.tar.gz

4. Copy the container .tar.gz file to another Pi and import it with:

    docker import ./garage_device_latest.tar.gz

5. Run docker container locally with:

    docker run -v /garage_settings:/garage_settings \
       --env "SETTINGS_FILE=/garage_settings/settings.json" \
       --env "GOOGLE_APPLICATION_CREDENTIALS=/garage_settings/service_account.json" \
       --device=/dev/gpiomem:/dev/gpiomem \
       -it garage_device:latest

before device is bootstrapped, run with this command instead

    docker run -v /garage_settings:/garage_settings \
       -v /sys:/sys \
       -v /usr/sbin:/usr/sbin \
       --env "SETTINGS_FILE=/garage_settings/settings.json" \
       --env "GOOGLE_APPLICATION_CREDENTIALS=/garage_settings/service_account.json" \
       --privileged \
       -it garage_device:latest

IMPORTANT: Content of /garage_settings/service.json is BASE64 decoded value of 'privateKeyData' from JSON blob stored as 'device_key' field in
Firebase (stored within users/<user-email>/devices/<device_id> document).

settings.json file has the following structure:

{
  "in_subscription": "<incoming-subscription-id>",
  "out_subscription": "<outgoing-subscription-id>"
}

incoming-subscription-id and outgoing-subscription-id values correspond to in_sub and out_sub file values from
Firebase (stored as properties of users/<user-email>/devices/<device_id> document).


6. Setup boot script
    cp <project>/etc/init.d/sizaha_garage <device>/etc/init.d
    chmod 755 /etc/init.d/sizaha_garage

Once that is done create a symbolic link in the run level directory you would like to use. We need runlevel 3 (multiple user mode under the command line interface and not under the graphical user interface., so the script shoud be places it in the /etc/rc3.d directory. You just cannot place it the directory, you must signify when it will run by indicating the startup with an “S” and the execution order is important. Place it after everything else that is in the directory by giving it a higher number. If the last script to be run is rc.local and it is named S99rc.local then you need to add your script as S99sizaha_garage.

   sudo ln -s /etc/init.d/sizaha_garage /etc/rc3.d/S99sizaha_garage

Each backward compatible /etc/rc*.d directory has symbolic links to the /etc/init.d/ directory.


