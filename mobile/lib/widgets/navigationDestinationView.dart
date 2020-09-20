import 'package:flutter/material.dart';
import 'package:mobile/models/appModel.dart';
import 'package:mobile/widgets/deviceListView.dart';
import 'package:mobile/widgets/deviceSetupView.dart';
import 'package:mobile/widgets/signInView.dart';
import 'package:provider/provider.dart';

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
            return DeviceSetupView();
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
}
