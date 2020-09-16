import 'package:flutter/material.dart';
import 'package:mobile/models/appModel.dart';
import 'package:provider/provider.dart';

class DeviceListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
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

    return ListView.builder(
        itemCount: model.devices.length,
        itemBuilder: (context, index) => Card(
              child: ListTile(
                leading: Icon(Icons.sentiment_very_satisfied),
                title: Text(
                  model.devices[index].deviceId,
                  style: itemNameStyle,
                ),
              ),
            ));
  }
}

class _DevicesFinal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var hugeStyle =
        Theme.of(context).textTheme.headline1.copyWith(fontSize: 48);

    return SizedBox(
      height: 200,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Another way to listen to a model's change is to include
            // the Consumer widget. This widget will automatically listen
            // to CartModel and rerun its builder on every change.
            //
            // The important thing is that it will not rebuild
            // the rest of the widgets in this build method.
            Consumer<AppModel>(
                builder: (context, model, child) => Text(
                    '${model.devices.length} deviced registered',
                    style: hugeStyle)),
            SizedBox(width: 24),
            FlatButton(
              onPressed: () {
                Scaffold.of(context)
                    .showSnackBar(SnackBar(content: Text('Coming soon...')));
              },
              color: Colors.white,
              child: Text('Register New Device'),
            ),
          ],
        ),
      ),
    );
  }
}
