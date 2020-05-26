import fcntl
import socket
import struct
import base64

from flask import Flask, json, jsonify, request
import flask_cors

def getHwAddr(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    info = fcntl.ioctl(s.fileno(), 0x8927,  struct.pack('256s', bytes(ifname, 'utf-8')[:15]))
    return ':'.join('%02x' % b for b in info[18:24])

def setup_ap():
    return

@app.route('/hello', methods=['GET])
def hello(device_id):
    # TODO: Return MAC address
    mac = getHwAddr('wlan0')
    return jsonify({'device': mac}), 200

@app.route('/setup_device', methods=['POST', 'PUT'])
def setup_device(device_id):
    """
    Sets up garage :
        {
            "service_key_blob": "...",
            "in_sub": "...",
            "out_sub": "...",
            "ssid": "...",
            "psk": "..."
        }
    """
    data = request.get_json()
    service_key_blob = data['service_key_blob']
    ssid = data['ssid']
    psk = data['psk']
    in_sub = data['in_sub']
    out_sub = data['out_sub']
    # TODO: Check validity of params
    device_config = {
        "in_subscription": in_sub,
        "out_subscription": out_sub,
        'ssid': ssid,
        'psk': psk
    }
    settings_file_name = os.environ.get('SETTINGS_FILE')
    with open(settings_file_name, 'w', encoding='utf-8') as f:
        json.dump(device_config, f, ensure_ascii=False, indent=4)
    
    service_file_name = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
    with open(service_file_name, 'w', encoding='utf-8') as f:
        f.write(base64.b64decode(service_key_blob))

    exit(0)
    return "OK", 200

@app.errorhandler(500)
def server_error(e):
    # Log the error and stacktrace.
    logging.exception('An error occurred during a request.')
    return 'An internal error occurred.', 500

if __name__ == '__main__':
    for v in ['BOOTSTRAP_PORT','SETTINGS_FILE','GOOGLE_APPLICATION_CREDENTIALS']:
        if os.environ.get(v) is None:
            print("error: {} environment variable not set".format(v))
            exit(1)

    # start Flask server
    # Flask's debug mode is unrelated to ptvsd debugger used by Cloud Code
    app.run(debug=False, port=int(os.environ.get('BOOTSTRAP_PORT')), host='0.0.0.0')
