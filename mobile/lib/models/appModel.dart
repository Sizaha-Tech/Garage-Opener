import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http show get;

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

final FirebaseAuth _auth = FirebaseAuth.instance;

class AppModel extends ChangeNotifier {
  final String _sizahaFrontendUrl = 'http://35.202.40.231/';

  /// Internal, private state of the app.
  SignedinState _signinState = SignedinState.pendingAuthentication;
  DeviceListState _deviceListState = DeviceListState.notStarted;
  List<DeviceModel> _devices = [];

  // Authentication data.
  User _user;
  String _userToken;

  /// An unmodifiable view of the items in the cart.
  SignedinState get signinState => _signinState;
  DeviceListState get deviceListState => _deviceListState;
  UnmodifiableListView<DeviceModel> get devices =>
      UnmodifiableListView(_devices);
  String get userToken => _userToken;

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
}
