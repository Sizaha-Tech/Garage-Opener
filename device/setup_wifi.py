import json
import http.client
import os
import re
import time

SETTINGS_FILE = "{}.tmp".format(os.environ.get('SETTINGS_FILE'))

CONNECTION_SUCCESS = 0
CONNECTION_BAD_PASSWORD = -1
CONNECTION_NO_SSID = -2
CONNECTION_UNKOWN_ERROR = -3

class WifiFinder:
    def __init__(self, ssid, password):
        self.server_name = ssid
        self.password = password
        self.main_dict = {}

    def find_wifi(self):
        ssid_list = self.scan_ssid()
        if len(ssid_list) > 0:
            return self.try_connecting(ssid_list)
        return

    def scan_ssid(self):
        command = """sudo iwlist wlan0 scan | grep -ioE 'ssid:"(.*{}.*)'"""
        result = []
        ssid_list = []
        while True:
            attempt = 0
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
            if len(ssid_list) == 0 and attempt <= 10:
                time.sleep(8)
                continue

            break

        return ssid_list
    
    def try_connecting(self, ssid_list):
        connect_result = False
        for name in ssid_list:
            attempt = 0
            while True:
                try:
                    (connect_result, info) = self.connect(name)
                    if connect_result == CONNECTION_SUCCESS:
                        print("Successfully connected to SSID - {}".format(name))
                        return True
                    elif connect_result == CONNECTION_NO_SSID and attempt <= 10:
                        # If it can't find SSID somehow, wait 1
                        attempt = attempt + 1
                        time.sleep(8)
                        continue
                    else:
                        print('Cannot connect to SSID - %s, error = %d, info = %s' %
                                (name, connect_result, info))
                        return False

                except Exception as exp:
                    print("Couldn't connect to SSID - {}. {}".format(name, exp))
                    return False

        return False

    def connect(self, name):
        command = "nmcli d wifi connect {} password {}".format(
            name, self.password)
        success_regex = re.compile(r"Device \'(.*)\' successfully activated with \'(.*)\'\.")
        bad_password_regex = re.compile(r"Error\: Connection activation failed: \(([0-9]+)\) Secrets were required\, but not provided\.")
        no_ssid_regex = re.compile(r"Error\: No network with SSID \'(.*)\' found\.")
        try:
            results = os.popen(command)
            results = list(results)
            for result_line in results:
                match = success_regex.match(result_line)
                if match is not None:
                    connection_guid = match[2]
                    return (CONNECTION_SUCCESS, connection_guid)

                match = bad_password_regex.match(result_line)
                if match is not None:
                    error_code = match[1]
                    return (CONNECTION_BAD_PASSWORD, error_code)

                match = no_ssid_regex.match(result_line)
                if match is not None:
                    ssid_name = match[1]
                    return (CONNECTION_NO_SSID, ssid_name)
        except:
            raise

        return (CONNECTION_UNKOWN_ERROR, "")


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
    print('Searching for WiFi connection...')
    if not start_wifi():
        print('Could not connenct to SSID specified in %s' % SETTINGS_FILE)
        exit(1)

    if not check_connection():
        print('No connectivity for SSID specified in %s' % SETTINGS_FILE)
        exit(1)

    # Successfully connected to WiFi, accept temp settings file.
    os.system("mv {} {}".format(
        SETTINGS_FILE,
        os.environ.get('SETTINGS_FILE')))

if __name__ == "__main__":
    main()        