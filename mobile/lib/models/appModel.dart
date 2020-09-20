import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http show get, post;
import 'package:mobile/models/deviceCreteRequest.dart';
import 'package:wifi/wifi.dart';

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
  cloudError
}

final FirebaseAuth _auth = FirebaseAuth.instance;

class AppModel extends ChangeNotifier {
  final String _sizahaFrontendUrl = 'https://api.sizaha.com/';

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

  /// An unmodifiable view of the items in the cart.
  SignedinState get signinState => _signinState;
  DeviceListState get deviceListState => _deviceListState;
  DeviceSetupPhase get deviceSetupPhase => _deviceSetupPhase;
  UnmodifiableListView<DeviceModel> get devices =>
      UnmodifiableListView(_devices);
  String get userToken => _userToken;
  String get deviceSSID => _deviceSSID;

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
    setDeviceSetupPhase(DeviceSetupPhase.searchingForNewDevice);
    _detectDevice();
  }

  stopDeviceSetup() {
    _deviceSearchStopped = true;
    setDeviceSetupPhase(DeviceSetupPhase.cancellingSearch);
  }

  _detectDevice() async {
    // only work on Android.
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
        appId: 'app123',
        deviceId: newDeviceName,
        deviceName: newDeviceName,
      );
      final response = await http.post('$_sizahaFrontendUrl/device',
          headers: {'Authorization': 'Bearer ' + _userToken},
          body: json.encode(request));
      if (response.statusCode != 200) {
        print('API call HTTP error = ${response.statusCode}');
        setDeviceSetupPhase(DeviceSetupPhase.cloudError);
        return;
      }

      Map<String, dynamic> results = json.decode(response.body);
      final deviceModel = new DeviceModel.fromJson(results);

      _startBootStrapping(deviceModel);

      _devices.add(deviceModel);
      setDeviceRetrievalState(DeviceListState.loaded);
    } catch (e) {
      print('API call failed - $e');
      setDeviceSetupPhase(DeviceSetupPhase.cloudError);
    }
  }

  _startBootStrapping(DeviceModel device) {
    setDeviceSetupPhase(DeviceSetupPhase.bootstrappingDevice);

    // TODO: Get current SSID + password (if we can't, show UI)
    // TODO: Connect to device's SSID
    // TODO: Call http://192.168.45.1:8080/setup_device
    // TODO: Reconnect to the main
  }
}
