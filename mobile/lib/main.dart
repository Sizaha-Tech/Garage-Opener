import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http show get;

import 'models/deviceModel.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ControllerApp());
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
        home: SigninSplash());
  }
}

class SigninSplash extends StatefulWidget {
  final String title = 'Sizaha Controller';

  @override
  _SigninSplashState createState() => _SigninSplashState();
}

class _SigninSplashState extends State<SigninSplash> {
  final String sizahaFrontendUrl = 'http://dev_api.sizaha.com:8080/';
  int signinState = 0;
  String accessToken;
  String idToken;
  User user;

  List<DeviceModel> devices = [];

  void getDevices(String accessToken) async {
    try {
      final response = await http.get('$sizahaFrontendUrl/devices',
          headers: {'Authorization': 'Bearer ' + accessToken});
      if (response.statusCode != 200) {
        print('API call HTTP error = ${response.statusCode}');
        return;
      }

      List<dynamic> results = json.decode(response.body);
      List<DeviceModel> userDevices = [];
      for (dynamic res in results) {
        final deviceModel = new DeviceModel.fromJson(res);
        userDevices.add(deviceModel);
      }
      setState(() {
        devices.clear();
        devices.addAll(userDevices);
      });
    } catch (e) {
      print('API call failed - $e');
    }
  }

  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _tokenSecretController = TextEditingController();

  int _selection = 0;
  bool _showAuthSecretTextField = false;
  bool _showProviderTokenField = false;
  String _provider = 'Google';

  _fetchPrefs() async {
    try {
      user = _auth.currentUser;
      if (user == null) {
        setState(() {
          signinState = 2; // show sign in screen
        });
      } else {
        var token = await user.getIdToken();
        setState(() {
          accessToken = token;
          signinState = 1; // got the prefs; set to some value if needed
        });
        getDevices(accessToken);
      }
    } catch (e) {
      setState(() {
        signinState = 2; //got the prefs; set to some value if needed
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPrefs(); //running initialisation code; getting prefs etc.
  }

  // Example code for sign out.
  void _signOut() async {
    await GoogleSignIn().disconnect();
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          Builder(builder: (BuildContext context) {
            return FlatButton(
              child: const Text('Sign out'),
              textColor: Theme.of(context).buttonColor,
              onPressed: () async {
                if (signinState != 1) return;

                final User user = _auth.currentUser;
                if (user == null) {
                  Scaffold.of(context).showSnackBar(const SnackBar(
                    content: Text('No one has signed in.'),
                  ));
                } else {
                  _signOut();
                  final String name = user.displayName;
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text(name + ' has successfully signed out.'),
                  ));
                  setState(() {
                    signinState = 2; // show sign in screen
                  });
                }
              },
            );
          })
        ],
      ),
      body: signinState == 2
          ? createSigninScreen()
          : (signinState == 1
              ? createStartSessionScreen()
              : createProgressScreen()),
    );
  }

  Widget createSigninScreen() {
    return Card(
      child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                child: const Text('Select Authentication Provider',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                alignment: Alignment.center,
              ),
              Container(
                padding: EdgeInsets.only(top: 16),
                child: kIsWeb
                    ? Text(
                        'When using Flutter Web, API keys are configured through the Firebase Console. The below providers demonstrate how this works')
                    : Text(
                        'We do not provide an API to obtain the token for below providers apart from Google '
                        'Please use a third party service to obtain token for other providers.'),
                alignment: Alignment.center,
              ),
              Container(
                padding: const EdgeInsets.only(top: 16.0),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Visibility(
                      visible: !kIsWeb,
                      child: ListTile(
                        title: Text('Google'),
                        leading: Radio<int>(
                          value: 0,
                          groupValue: _selection,
                          onChanged: _handleRadioButtonSelected,
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text('Twitter'),
                      leading: Radio<int>(
                        value: 1,
                        groupValue: _selection,
                        onChanged: _handleRadioButtonSelected,
                      ),
                    ),
                    ListTile(
                      title: Text('Facebook'),
                      leading: Radio<int>(
                        value: 2,
                        groupValue: _selection,
                        onChanged: _handleRadioButtonSelected,
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: _showProviderTokenField && !kIsWeb,
                child: TextField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                      labelText: 'Enter provider\'s token'),
                ),
              ),
              Visibility(
                visible: _showAuthSecretTextField && !kIsWeb,
                child: TextField(
                  controller: _tokenSecretController,
                  decoration: const InputDecoration(
                      labelText: 'Enter provider\'s authTokenSecret'),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 16.0),
                alignment: Alignment.center,
                child: SignInButton(
                  _provider == "Facebook"
                      ? Buttons.Facebook
                      : (_provider == "Twitter"
                          ? Buttons.Twitter
                          : Buttons.GoogleDark),
                  text: "Sign In",
                  onPressed: () async {
                    _signInWithOtherProvider();
                  },
                ),
              ),
            ],
          )),
    );
  }

  void _handleRadioButtonSelected(int value) {
    setState(() {
      _selection = value;

      switch (_selection) {
        case 1:
          {
            _provider = "Twitter";
            _showAuthSecretTextField = true;
            _showProviderTokenField = true;
          }
          break;

        case 2:
          {
            _provider = "Facebook";
            _showAuthSecretTextField = false;
            _showProviderTokenField = true;
          }
          break;

        default:
          {
            _provider = "Google";
            _showAuthSecretTextField = false;
            _showProviderTokenField = false;
          }
      }
    });
  }

  void _signInWithOtherProvider() {
    switch (_selection) {
      case 1:
        _signInWithTwitter();
        break;
      case 2:
        _signInWithFacebook();
        break;
      default:
        _signInWithGoogle();
    }
  }

  void _signInWithFacebook() async {
    try {
      final AuthCredential credential = FacebookAuthProvider.credential(
        _tokenController.text,
      );
      final User user = (await _auth.signInWithCredential(credential)).user;

      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Sign In ${user.uid} with Facebook"),
      ));
    } catch (e) {
      print(e);
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Failed to sign in with Facebook: $e"),
      ));
    }
  }

  // Example code of how to sign in with Twitter.
  void _signInWithTwitter() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        TwitterAuthProvider twitterProvider = TwitterAuthProvider();
        await _auth.signInWithPopup(twitterProvider);
      } else {
        final AuthCredential credential = TwitterAuthProvider.credential(
            accessToken: _tokenController.text,
            secret: _tokenSecretController.text);
        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;

      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Signed in ${user.uid} with Twitter"),
      ));
    } catch (e) {
      print(e);
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Failed to sign in with Twitter: $e"),
      ));
    }
  }

  //Example code of how to sign in with Google.
  void _signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final GoogleAuthCredential googleAuthCredential =
            GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(googleAuthCredential);
      }

      final newUser = userCredential.user;
      setState(() {
        signinState = 1;
        user = newUser;
      });
    } catch (e) {
      print(e);
      setState(() {
        signinState = 2;
      });
    }
  }

  Widget createProgressScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          child: const Text('Signing in...'),
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

  Widget createStartSessionScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          child: Text('Welcome back ${user.displayName}!'),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
        ),
      ],
    );
  }
}
