import 'package:flutter/material.dart';
import 'package:mobile/models/appModel.dart';
import 'package:provider/provider.dart';

class DeviceSetupView extends StatefulWidget {
  @override
  DeviceSetupViewState createState() {
    return DeviceSetupViewState();
  }
}

class DeviceSetupViewState extends State<DeviceSetupView> {
  final _formKey = GlobalKey<FormState>();
  final _deviceNameController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var model = context.watch<AppModel>();
    switch (model.deviceSetupPhase) {
      case DeviceSetupPhase.notStarted:
        return notStartedView(model);
      case DeviceSetupPhase.searchingForNewDevice:
      case DeviceSetupPhase.cancellingSearch:
        return searchingForNewDeviceView(model);
      case DeviceSetupPhase.deviceNotFound:
        return deviceNotFoundView(model);
      case DeviceSetupPhase.foundNewDevice:
        return foundNewDeviceView(model);
      case DeviceSetupPhase.deviceNaming:
        return deviceNamingView(model);
      default:
        return createNotImplemetedView();
/*        
      case DeviceSetupPhase.registeringDeviceAccount:
        return registeringDeviceAccountView(model);
        break;
      case DeviceSetupPhase.bootstrappingDevice:
        return bootstrappingDeviceView(model);
        break;
      case DeviceSetupPhase.completedSetup:
        return completedSetupView(model);
        break;
*/
    }
  }

  Widget createNotImplemetedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          child: const Text('What are you looking at?'),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
      ],
    );
  }

  Widget notStartedView(AppModel appModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          child: const Text(
              'Plug in your Sizaha garage door opener device, start setup for by pressing the button below.'),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
        Container(
          child: FlatButton(
            child: const Text('Next'),
            textColor: Colors.white,
            color: Colors.blue[300],
            onPressed: appModel.startNewDeviceSetup,
          ),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
      ],
    );
  }

  Widget searchingForNewDeviceView(AppModel appModel) {
    bool cancelling =
        appModel.deviceSetupPhase == DeviceSetupPhase.cancellingSearch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          child: const Text(
              'Searching for new devices... Please wait... This can take few minutes.'),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
        Container(
          child: FlatButton(
            child: Text(cancelling ? 'Cancelling...' : 'Cancel'),
            textColor: Colors.white,
            color: Colors.red[300],
            onPressed: cancelling ? null : () => appModel.stopDeviceSetup(),
          ),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
      ],
    );
  }

  Widget deviceNotFoundView(AppModel appModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          child: const Text(
              'No new devices found. Please make sure your new device is plugged in and close to your phone.'),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
        Container(
          child: FlatButton(
            child: const Text('OK'),
            textColor: Colors.white,
            color: Colors.blue[300],
            onPressed: () =>
                appModel.setDeviceSetupPhase(DeviceSetupPhase.notStarted),
          ),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
      ],
    );
  }

  Widget foundNewDeviceView(AppModel appModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          child: const Text(
              'New Sizaha garage controller found! Please confirm the device name below.'),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
        Container(
          child: Text(
            appModel.deviceSSID,
            style: new TextStyle(
              fontSize: 20.0,
              color: Colors.yellow[300],
            ),
          ),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
        Container(
          child: FlatButton(
            child: const Text('Cancel'),
            textColor: Colors.white,
            color: Colors.red[300],
            onPressed: () =>
                appModel.setDeviceSetupPhase(DeviceSetupPhase.notStarted),
          ),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
        Container(
          child: FlatButton(
            child: const Text('Next'),
            textColor: Colors.white,
            color: Colors.blue[300],
            onPressed: () =>
                appModel.setDeviceSetupPhase(DeviceSetupPhase.deviceNaming),
          ),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
      ],
    );
  }

  Widget deviceNamingView(AppModel appModel) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(80.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'What would you like this device to be identified as?',
                ),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Device name:',
                  ),
                  controller: _deviceNameController,
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: 24,
                ),
                FlatButton(
                  color: Colors.blue[300],
                  child: Text('Next'),
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      String deviceName = _deviceNameController.text;
                      appModel.createCloudDevice(deviceName);
/*                      
                      Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Registering device "${_deviceNameController.text}"')));
*/
                    }
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
