import 'package:flutter/material.dart';
import 'package:mobile/models/appModel.dart';
import 'package:mobile/widgets/signInView.dart';
import 'package:provider/provider.dart';

import 'deviceListView.dart';

class AccountView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appModel = context.watch<AppModel>();
    if (appModel.signinState == SignedinState.authenticated)
      return createAccountDetailsScreen(context, appModel);

    return SignInView();
  }

  Widget createAccountDetailsScreen(BuildContext context, AppModel appModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          child: Text('Welcome back ${appModel.userDisplayName}!'),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
        Container(
            alignment: Alignment.bottomCenter,
            child: FlatButton(
              child: const Text('Sign out'),
              textColor: Theme.of(context).buttonColor,
              onPressed: () {
                appModel.signOut();
              },
            )),
      ],
    );
  }
}
