import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/models/appModel.dart';
import 'package:provider/provider.dart';

class SignInView extends StatefulWidget {
  @override
  SignInViewState createState() => SignInViewState();
}

final FirebaseAuth _auth = FirebaseAuth.instance;

class SignInViewState extends State<SignInView> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _tokenSecretController = TextEditingController();

  int _selection = 0;
  bool _showAuthSecretTextField = false;
  bool _showProviderTokenField = false;
  String _provider = 'Google';

  @override
  Widget build(BuildContext context) {
    // Don't change the view of model state changes.
    var model = Provider.of<AppModel>(context, listen: false);
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
                    _signInWithOtherProvider(model);
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

  void _signInWithOtherProvider(AppModel model) {
    switch (_selection) {
      case 1:
        _signInWithTwitter();
        break;
      case 2:
        _signInWithFacebook();
        break;
      default:
        _signInWithGoogle(model);
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
  void _signInWithGoogle(AppModel model) async {
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
      var token = await newUser.getIdToken();

      model.setSigninState(SignedinState.authenticated, token);
    } catch (e) {
      print(e);
      model.setSigninState(SignedinState.signedOut, '');
    }
  }
}
