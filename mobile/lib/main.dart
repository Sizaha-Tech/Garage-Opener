import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mobile/widgets/navigationDestinationView.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';

import 'models/appModel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  AppModel model = AppModel();
  model.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (context) => model,
      child: ControllerApp(),
    ),
  );
}

/// The entry point of the application.
///
/// Returns a [MaterialApp].
class ControllerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Sizaha Garage Controller',
        theme: ThemeData.dark(),
        home: Consumer<AppModel>(builder: (context, cart, child) {
          return MainScreenWidget();
        }));
  }
}

class MainScreenWidget extends StatefulWidget {
  final String title = 'Sizaha Controller';

  @override
  _MainScreenWidgetState createState() => _MainScreenWidgetState();
}

class _MainScreenWidgetState extends State<MainScreenWidget> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    var appModel = context.watch<AppModel>();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (appModel.signinState == SignedinState.signedOut) {
      // account view selected
      _currentIndex = 2;
    }

    var bottomNavigationBarItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(Icons.call_to_action),
        // ignore: deprecated_member_use
        title: Text('My Devices'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.add_comment),
        // ignore: deprecated_member_use
        title: Text('Register New'),
      ),
      BottomNavigationBarItem(
          icon: const Icon(Icons.account_circle),
          // ignore: deprecated_member_use
          title: Text('Account')),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.title),
      ),
      body: Center(
        child: PageTransitionSwitcher(
          child: NavigationDestinationView(
              // Adding [UniqueKey] to make sure the widget rebuilds when transitioning.
              key: UniqueKey(),
              selectedView: _currentIndex),
          transitionBuilder: (child, animation, secondaryAnimation) {
            return FadeThroughTransition(
              child: child,
              animation: animation,
              secondaryAnimation: secondaryAnimation,
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: true,
        items: bottomNavigationBarItems,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: textTheme.caption.fontSize,
        unselectedFontSize: textTheme.caption.fontSize,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: colorScheme.onPrimary,
        unselectedItemColor: colorScheme.onPrimary.withOpacity(0.38),
        backgroundColor: colorScheme.primary,
      ),
    );
  }
}
