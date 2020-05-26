import json
import http.client
import os
import time

SETTINGS_FILE = "{}.tmp".format(os.environ.get('SETTINGS_FILE'))

class WifiFinder:
    def __init__(self, ssid, password):
        self.server_name = ssid
        self.password = password
        self.main_dict = {}

    def find_wifi(self):
        command = """sudo iwlist wlan0 scan | grep -ioE 'ssid:"(.*{}.*)'"""
        result = []
        while True:
            result = os.popen(command.format(self.server_name))
            result = list(result)
            # Sleep 10 seconds before attemting another scan.
            if "Device or resource busy" in result:
                time.sleep(10)
                continue

            break

        ssid_list = [item.lstrip('SSID:').strip('"\n') for item in result]
        print("Found SSIDs {}".format(str(ssid_list)))

        connect_result = False
        for name in ssid_list:
            try:
                connect_result = self.connect(name)
            except Exception as exp:
                print("Couldn't connect to SSID - {}. {}".format(name, exp))
                return False

            if connect_result:
                print("Successfully connected to SSID - {}".format(name))
                return True

        return False

    def connect(self, name):
        try:
            if (os.system("nmcli d wifi connect {} password {}".format(
                    name, self.password))) == 0:
                return True
        except:
            raise

        return False


# Start WiFi with params from the temp settings file, return true if we can connect
def start_wifi():
    fp = open(SETTINGS_FILE)
    settings = json.load(fp)
    f = WifiFinder(ssid = settings['ssid'],
                   password = settings['password'])
    return f.find_wifi()

# Checks if we can access Google servers.
def check_connection():
    conn = http.client.HTTPSConnection("www.google.com", 443)
    conn.request("GET","/generate_204")
    r = conn.getresponse()
    return r.status == 204

def main():
    print('Initializing WiFi...')
    if start_wifi():
        if check_connection():
            # Successfully connected to WiFi, accept temp settings file.
            os.system("mv {} {}".format(
                SETTINGS_FILE,
                os.environ.get('SETTINGS_FILE')))

if __name__ == "__main__":
    main()        