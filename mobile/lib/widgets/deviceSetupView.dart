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
  final _ssidController = TextEditingController();
  final _passkeyController = TextEditingController();

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
        return errorView(model,
            'No new devices found. Please make sure your new device is plugged in and close to your phone.');
      case DeviceSetupPhase.foundNewDevice:
        return foundNewDeviceView(model);
      case DeviceSetupPhase.deviceNaming:
        return deviceNamingView(model);
      case DeviceSetupPhase.registeringDeviceAccount:
        return uninterruptiblePhaseView(model,
            'Registering your new device with the Sizaha cloud. Plase wait...');
        break;
      case DeviceSetupPhase.bootstrappingDevice:
        return uninterruptiblePhaseView(
            model, 'Configuring you new device. Please wait...');
        break;
      case DeviceSetupPhase.completedSetup:
        return errorView(
            model,
            'Device setup succeeded. You can find it in '
            'your device list registered as "${model.newDeviceName}"');
        break;
      case DeviceSetupPhase.cloudError:
        return errorView(
            model, 'Device can not be registered with Sizaha cloud.');
        break;
      case DeviceSetupPhase.deviceError:
        return errorView(model, 'Device setup failed.');
        break;
      default:
        return createNotImplemetedView();
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
            child: const Text('Start Registration'),
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

    final colorScheme = Theme.of(context).colorScheme;
    var bottomNavigationBarItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(Icons.cancel),
        // ignore: deprecated_member_use
        title: Text(cancelling ? 'Cancelling...' : 'Cancel'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.navigate_next),
        // ignore: deprecated_member_use
        title: Text('Wait...'),
      ),
    ];

    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Searching for new devices... Please wait.'
                'This can take few minutes.',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: true,
        items: bottomNavigationBarItems,
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0 && !cancelling) {
            appModel.stopDeviceSearch();
          }
        },
        selectedItemColor: colorScheme.onPrimary,
        unselectedItemColor: colorScheme.onPrimary,
        backgroundColor: colorScheme.primary,
      ),
    );
  }

  Widget uninterruptiblePhaseView(AppModel appModel, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          child: Text(message),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
      ],
    );
  }

  Widget errorView(AppModel appModel, String errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          child: Text(errorMessage),
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
    final colorScheme = Theme.of(context).colorScheme;
    var bottomNavigationBarItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(Icons.cancel),
        // ignore: deprecated_member_use
        title: const Text('Cancel'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.navigate_next),
        // ignore: deprecated_member_use
        title: const Text('Next'),
      ),
    ];

    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                child: const Text('New Sizaha garage controller found! '
                    'Please confirm the device name below.'),
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: true,
        items: bottomNavigationBarItems,
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            appModel.setDeviceSetupPhase(DeviceSetupPhase.notStarted);
          } else {
            appModel.setDeviceSetupPhase(DeviceSetupPhase.deviceNaming);
          }
        },
        selectedItemColor: colorScheme.onPrimary,
        unselectedItemColor: colorScheme.onPrimary,
        backgroundColor: colorScheme.primary,
      ),
    );
  }

  Widget deviceNamingView(AppModel appModel) {
    _ssidController.text = appModel.currentSsid;

    final colorScheme = Theme.of(context).colorScheme;
    var bottomNavigationBarItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(Icons.cancel),
        // ignore: deprecated_member_use
        title: Text('Cancel'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.navigate_next),
        // ignore: deprecated_member_use
        title: Text('Next'),
      ),
    ];

    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Please enter device info:',
                ),
                TextFormField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'New device name',
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
                  height: 20,
                ),
                Text(
                  'Please enter your WiFi info:',
                ),
                // TODO: Maybe split WiFi to another screen?
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'SSID',
                  ),
                  controller: _ssidController,
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter some text';
                    } else if (value.length > 32) {
                      return 'SSID name is too long';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Passphrase',
                  ),
                  controller: _passkeyController,
                  obscureText: true,
                  validator: (value) {
                    if (value.length < 8) {
                      return 'Passphrase must be at least 8 characters long';
                    } else if (value.length > 63) {
                      return 'Passphrase is too long';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: true,
        items: bottomNavigationBarItems,
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          print(index);
          if (index == 0)
            appModel.setDeviceSetupPhase(DeviceSetupPhase.notStarted);
          else
            _startBootstraping(appModel);
        },
        selectedItemColor: colorScheme.onPrimary,
        unselectedItemColor: colorScheme.onPrimary,
        backgroundColor: colorScheme.primary,
      ),
    );
  }

  void _startBootstraping(AppModel appModel) {
    // next
    if (_formKey.currentState.validate()) {
      String deviceName = _deviceNameController.text;
      String ssid = _ssidController.text;
      String passphrase = _passkeyController.text;
      appModel.setWifiInfo(ssid, passphrase);
      appModel.createCloudDevice(deviceName);
    }
  }
}
