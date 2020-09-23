import 'package:flutter/material.dart';
import 'package:mobile/models/appModel.dart';
import 'package:mobile/models/deviceModel.dart';
import 'package:provider/provider.dart';

class DeviceListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _DeviceList(),
            ),
          ),
          Divider(height: 4, color: Colors.black),
//          _DevicesFinal(),
        ],
      ),
    );
  }
}

class _DeviceList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var itemNameStyle = Theme.of(context).textTheme.headline6;
    // This gets the current state of CartModel and also tells Flutter
    // to rebuild this widget when CartModel notifies listeners (in other words,
    // when it changes).
    var model = context.watch<AppModel>();
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        verticalDirection: VerticalDirection.down,
        children: <Widget>[
          Expanded(child: dataBody(model)),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: OutlineButton(
                    child: Text('Unregister'),
                    onPressed: () {},
                  ),
                ),
              ])
        ]);
  }

  SingleChildScrollView dataBody(AppModel model) {
    List<DeviceModel> devices = model.devices;
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text("Action"),
            numeric: false,
          ),
          DataColumn(
            label: Text("Devices"),
            numeric: false,
          ),
        ],
        rows: devices
            .map(
              (device) => DataRow(cells: [
                DataCell(
                  Text(device.deviceId),
                  onTap: () {
                    print('Selected ${device.deviceId}');
                  },
                ),
                DataCell(
                  FlatButton(
                    child: const Text('Activate'),
                    textColor: Colors.white,
                    color: Colors.red[300],
                    onPressed: () {
                      model.activateDevice(device.deviceId);
                    },
                  ),
                ),
              ]),
            )
            .toList(),
      ),
    );
  }
}
