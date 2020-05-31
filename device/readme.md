#Setting up Wireless AP

##1. Install missing OS packages:

    ### Armbian setup (Orange Pi):
    sudo apt update && sudo apt --yes --force-yes install dnsmasq
    ### sudo apt update && sudo apt --yes --force-yes install dnsmasq hostapd

    sudo apt --yes --force-yes install python3-dev python3-pip python3-venv
    sudo pip3 install setuptools distlib virtualenv

    ### Raspian setup (Raspberry Pi)
    1.1. Install NetworkManager:
       sudo apt update && sudo apt --yes --force-yes install dnsmasq hostapd \
            network-manager openvpn-systemd-resolved rng-tools

    1.2. Fix permissions for 'pi' account:
       cp ./Raspian/org.freedesktop.NetworkManager.pkla /var/lib/polkit-1/localauthority/50-local.d/

    1.3. Reboot
       sudo reboot

##2. Install Python packages:
    pip3 install wireless netifaces psutil pyaccesspoint packaging

##3. Start AP:
   sudo pyaccesspoint -w wlan0 --ssid "Sizaha1234" --password "sizaha2020" start


Building and Running Docker image on Raspberry Pi

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



6. Install network manager

    sudo apt-get install network-manager -y
