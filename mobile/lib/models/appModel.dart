import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http show get, post;
import 'package:mobile/models/deviceCreateRequest.dart';
import 'package:mobile/models/deviceSetupRequest.dart';
import 'package:wifi/wifi.dart';

import 'activateDeviceRequest.dart';
import 'deviceModel.dart';

// Account sign-in state
enum SignedinState {
  pendingAuthentication,
  authenticated,
  signedOut,
}

// Account sign-in state
enum DeviceListState {
  notStarted,
  inProgress,
  loaded,
}

enum DeviceSetupPhase {
  notStarted,
  searchingForNewDevice,
  cancellingSearch,
  deviceNotFound,
  foundNewDevice,
  deviceNaming,
  registeringDeviceAccount,
  bootstrappingDevice,
  completedSetup,
  cloudError,
  deviceError,
}

final FirebaseAuth _auth = FirebaseAuth.instance;

class AppModel extends ChangeNotifier {
  // API frontend URL.
  final String _sizahaFrontendUrl = 'https://api.sizaha.com/';

  // Device bootstrap SSID passkey.
  static const String _deviceSSIDPassphrase = 'sizaha123';

  // Make max 30 wifi scans, every 10 sec ~ 5 min total search time.
  final int maxWifiScanCount = 30;

  /// Internal, private state of the app.
  SignedinState _signinState = SignedinState.pendingAuthentication;
  DeviceListState _deviceListState = DeviceListState.notStarted;
  DeviceSetupPhase _deviceSetupPhase = DeviceSetupPhase.notStarted;
  List<DeviceModel> _devices = [];

  // Authentication data.
  User _user;
  String _userToken;
  String _deviceSSID = '';
  int _deviceSearchAttempt = 0;
  bool _deviceSearchStopped = false;
  String _newDeviceName;

  String _targetSsid;
  String _targetPassphrase;
  String _currentSsid;

  /// An unmodifiable view of the items in the cart.
  SignedinState get signinState => _signinState;
  DeviceListState get deviceListState => _deviceListState;
  DeviceSetupPhase get deviceSetupPhase => _deviceSetupPhase;
  UnmodifiableListView<DeviceModel> get devices =>
      UnmodifiableListView(_devices);
  String get userToken => _userToken;
  String get deviceSSID => _deviceSSID;
  String get currentSsid => _currentSsid;
  DeviceModel _newDeviceModel;

  String get newDeviceName {
    if (_newDeviceModel == null) return '';
    return _newDeviceModel.deviceId;
  }

  String get userDisplayName {
    if (_auth.currentUser == null) return '';
    return _auth.currentUser.displayName;
  }

  /// Adds [device] to the list. This and [removeAll] are the only ways to modify the
  /// cart from the outside.
  void addDevice(DeviceModel device) {
    _devices.add(device);
    // This call tells the widgets that are listening to this model to rebuild.
    notifyListeners();
  }

  /// Removes all items from the cart.
  void removeAllDevices() {
    _devices.clear();
    // This call tells the widgets that are listening to this model to rebuild.
    notifyListeners();
  }

  void setDeviceSetupPhase(DeviceSetupPhase phase) {
    if (_deviceSetupPhase == phase) return;
    if (_deviceSetupPhase == DeviceSetupPhase.notStarted ||
        _deviceSetupPhase == DeviceSetupPhase.completedSetup) {
      _deviceSSID = '';
      _deviceSearchAttempt = 0;
      _deviceSearchStopped = false;
      _newDeviceName = '';
      _targetSsid = '';
    }
    _deviceSetupPhase = phase;
    notifyListeners();
  }

  void setSigninState(SignedinState state, String token) {
    if (_signinState == state) return;
    _signinState = state;
    _userToken = token;
    _devices.clear();
    if (_signinState == SignedinState.authenticated) {
      getDevices();
      return;
    }
    notifyListeners();
  }

  void setDeviceRetrievalState(DeviceListState state) {
    if (_deviceListState == state) return;

    _deviceListState = state;
    notifyListeners();
  }

  // Example code for sign out.
  void signOut() async {
    await GoogleSignIn().disconnect();
    await _auth.signOut();
    setSigninState(SignedinState.signedOut, '');
  }

  initialize() async {
    try {
      _user = _auth.currentUser;
      if (_user == null) {
        setSigninState(SignedinState.signedOut, '');
      } else {
        var token = await _user.getIdToken();
        setSigninState(SignedinState.authenticated, token);
      }
    } catch (e) {
      setSigninState(SignedinState.signedOut, '');
    }
  }

  void getDevices() async {
    try {
      setDeviceRetrievalState(DeviceListState.inProgress);
      final response = await http.get('$_sizahaFrontendUrl/devices',
          headers: {'Authorization': 'Bearer ' + _userToken});
      if (response.statusCode != 200) {
        print('API call HTTP error = ${response.statusCode}');
        setDeviceRetrievalState(DeviceListState.notStarted);
        return;
      }

      List<dynamic> results = json.decode(response.body);
      List<DeviceModel> userDevices = [];
      for (dynamic res in results) {
        final deviceModel = new DeviceModel.fromJson(res);
        userDevices.add(deviceModel);
      }
      _devices.clear();
      _devices.addAll(userDevices);
      setDeviceRetrievalState(DeviceListState.loaded);
    } catch (e) {
      print('API call failed - $e');
      setDeviceRetrievalState(DeviceListState.notStarted);
    }
  }

  startNewDeviceSetup() {
    _newDeviceModel = null;
    setDeviceSetupPhase(DeviceSetupPhase.searchingForNewDevice);
    _detectDevice();
  }

  stopDeviceSearch() {
    _deviceSearchStopped = true;
    setDeviceSetupPhase(DeviceSetupPhase.cancellingSearch);
  }

  _detectDevice() async {
    // This will probaly only work on Android. Need to test iOS.
    _currentSsid = await Wifi.ssid;
    List<WifiResult> wifiList = await Wifi.list('');
    for (var wifi in wifiList) {
      print('Found ssid "${wifi.ssid}".');
      if (wifi.ssid.startsWith("Sizaha")) {
        this._deviceSSID = wifi.ssid;
        setDeviceSetupPhase(DeviceSetupPhase.foundNewDevice);
        return;
      }
    }

    // Wait 10 seconds and try the search again
    _deviceSearchAttempt++;
    if (_deviceSearchAttempt > maxWifiScanCount || _deviceSearchStopped) {
      setDeviceSetupPhase(DeviceSetupPhase.deviceNotFound);
      return;
    }

    // Repeat the search in 10s if we didn't find anything.
    Future.delayed(const Duration(milliseconds: 10000), () {
      if (_deviceSearchStopped) {
        setDeviceSetupPhase(DeviceSetupPhase.deviceNotFound);
        return;
      }

      _detectDevice();
    });
  }

  createCloudDevice(String newDeviceName) async {
    setDeviceSetupPhase(DeviceSetupPhase.registeringDeviceAccount);
    try {
      var request = DeviceCreateRequest(
        // TODO: Figure out what if anything is app_id going to be used for.
        appId: 'app123',
        deviceId: newDeviceName,
        deviceName: newDeviceName,
      );
      final response = await http.post('$_sizahaFrontendUrl/device',
          headers: {
            'Authorization': 'Bearer ' + _userToken,
            'Content-type': 'application/json; charset=utf-8',
          },
          body: json.encode(request.toJson()));
      if (response.statusCode != 200) {
        print('API call HTTP error = ${response.statusCode}');
        setDeviceSetupPhase(DeviceSetupPhase.cloudError);
        return;
      }

      Map<String, dynamic> results = json.decode(response.body);
      _newDeviceModel = new DeviceModel.fromJson(results);

      _devices.add(_newDeviceModel);
      _newDeviceName = newDeviceName;
      _startBootStrapping(_newDeviceModel);
    } catch (e) {
      print('API call failed - $e');
      setDeviceSetupPhase(DeviceSetupPhase.cloudError);
    }
  }

  _startBootStrapping(DeviceModel device) async {
    setDeviceSetupPhase(DeviceSetupPhase.bootstrappingDevice);

    // Connnect to the device's SSID.
    WifiState result =
        await Wifi.connection(_deviceSSID, _deviceSSIDPassphrase);
    switch (result) {
      case WifiState.already:
      case WifiState.success:
        // Get IP address of the device.
        String myIp = await Wifi.ip;
        _configureDevice(_getDeviceIpFromPhoneIp(myIp));
        break;
      case WifiState.error:
        setDeviceSetupPhase(DeviceSetupPhase.deviceError);
        break;
    }
  }

  String _getDeviceIpFromPhoneIp(String ip) {
    // Device's IP is always ending with .1
    return ip.substring(0, ip.lastIndexOf('.')) + '.1';
  }

  _configureDevice(String newDeviceIp) async {
    setDeviceSetupPhase(DeviceSetupPhase.registeringDeviceAccount);
    String deviceUrlBase = 'http://192.168.45.1:8080';
    var result = await _sendDeviceConfiguation(deviceUrlBase);
    if (result) {
      _rebootDevice(deviceUrlBase);
      _devices.add(_newDeviceModel);
      setDeviceRetrievalState(DeviceListState.loaded);
      setDeviceSetupPhase(DeviceSetupPhase.completedSetup);
    } else {
      setDeviceSetupPhase(DeviceSetupPhase.deviceError);
    }
  }

  _sendDeviceConfiguation(String deviceUrlBase) async {
    try {
      var request = DeviceSetupRequest(
        ssid: _targetSsid,
        passphrase: _targetPassphrase,
        inSub: _newDeviceModel.inSubscription,
        outSub: _newDeviceModel.outSubscription,
        serviceKeyBlob: _newDeviceModel.deviceAccount,
      );
      final response = await http.post('$deviceUrlBase/setup_device',
          headers: {
            'Content-type': 'application/json; charset=utf-8',
          },
          body: json.encode(request.toJson()));
      if (response.statusCode != 200) {
        print('API call HTTP error = ${response.statusCode}');
        return true;
      }
    } catch (e) {
      print('API call failed - $e');
    }
    return false;
  }

  _rebootDevice(String deviceUrlBase) async {
    try {
      await http.get('$deviceUrlBase/shutdown');
      // It does no matter what thr response is when device reboots.
    } catch (e) {
      print('API call failed - $e');
      setDeviceSetupPhase(DeviceSetupPhase.cloudError);
    }
  }

  void setWifiInfo(String ssid, String passphrase) {
    _targetSsid = ssid;
    _targetPassphrase = passphrase;
  }

  activateDevice(String deviceId) async {
    try {
      var request = ActivateDeviceRequest(
        command: 'OPEN',
      );
      final response = await http.post(
          '$_sizahaFrontendUrl//device/' + deviceId + '/run',
          headers: {'Authorization': 'Bearer ' + _userToken},
          body: json.encode(request.toJson()));

      if (response.statusCode != 200) {
        print('API call HTTP error = ${response.statusCode}');
        return true;
      }
    } catch (e) {
      print('API call failed - $e');
    }
    return false;
  }
}
