import 'package:flutter/material.dart';
import 'package:mobile/models/appModel.dart';
import 'package:mobile/widgets/deviceListView.dart';
import 'package:mobile/widgets/signInView.dart';
import 'package:provider/provider.dart';
import 'package:wifi/wifi.dart';

import 'accountView.dart';

class NavigationDestinationView extends StatelessWidget {
  NavigationDestinationView({Key key, this.selectedView}) : super(key: key);

  final int selectedView;

  @override
  Widget build(BuildContext context) {
    var appModel = context.watch<AppModel>();
    switch (appModel.signinState) {
      case SignedinState.signedOut:
        return SignInView();
      case SignedinState.pendingAuthentication:
        return createProgressView();
      case SignedinState.authenticated:
        switch (selectedView) {
          case 0:
            return DeviceListView();
          case 1:
            return createNewDeviceView(context);
          default:
            return AccountView();
        }
    }
  }

  Widget createProgressView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          child: const Text('Loading...'),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
        Container(
          child: CircularProgressIndicator(),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
      ],
    );
  }

  Widget createNewDeviceView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          child: const Text(
              'Plug in your Garage opener device, start searching for by pressing:'),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
        Container(
          child: FlatButton(
            child: const Text('Register new device'),
            textColor: Theme.of(context).buttonColor,
            onPressed: _findDevice,
          ),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
      ],
    );
  }

  _findDevice() async {
    print('Clicked!');
    // only work on Android.
    List<WifiResult> wifiList = await Wifi.list('');
    for (var wifi in wifiList) {
      print('Found ssid "${wifi.ssid}".');
      if (wifi.ssid.startsWith("Sizaha")) {
        print('Found one!');
      }
    }
  }
}
