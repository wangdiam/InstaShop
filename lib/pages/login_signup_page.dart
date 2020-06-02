import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:instashop/models/user.dart';
import 'package:instashop/pages/create_account.dart';
import 'package:instashop/pages/root_page.dart';
import 'package:instashop/services/authentication.dart';
import 'package:instashop/main.dart';

final auth = FirebaseAuth.instance;
final googleSignIn = GoogleSignIn();
final ref = Firestore.instance.collection('insta_users');
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

class LoginSignupPage extends StatefulWidget {
  LoginSignupPage({this.loginCallback});

  final VoidCallback loginCallback;

  @override
  State<StatefulWidget> createState() => new _LoginSignupPageState();

}

class _LoginSignupPageState extends State<LoginSignupPage> {
  final _formKey = new GlobalKey<FormState>();
  int _page = 0;
  bool triedSilentLogin = false;
  bool setupNotifications = false;

  String _email;
  String _password;
  String _username;
  String _errorMessage;

  User user;

  bool _isLoginForm;
  bool _isLoading;

  
  // Check if form is valid before perform login or signup
  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  // Perform login or signup
  void validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      print("LOGIN SAVED");
      String userId = "";
      try {
        if (_isLoginForm) {
          userId = await baseAuth.signIn(_email, _password);
          print('Signed in: $userId');
          await ref.document(userId).get()
          .then((value) {
            setState(() {
              currentUserModel = User.fromDocument(value);
            });
          });
        } else {
          userId = await baseAuth.signUp(_email, _password);
          //widget.auth.sendEmailVerification();
          //_showVerifyEmailSentDialog();
          print('Signed up user: $userId');
          ref.document(userId).setData({
            "id": userId,
            "username": _username,
            "photoUrl": "",
            "email": _email,
            "bio": "",
            "followers": {},
            "following": {},
            "displayName": _username
          });
        }
        setState(() {
          _isLoading = false;
        });
        print("userId length: " + userId.length.toString() + userId.toString());
        if (userId.length > 0 && userId != null && _isLoginForm) {
          widget.loginCallback();
        }
      } catch (e) {
        print('Error: $e');
        setState(() {
          print("ERROR");
          _isLoading = false;
          _errorMessage = e.toString();
          _formKey.currentState.reset();
        });
      }
    } else {
      setState(() {
        print("ERROR");
        _isLoading = false;
      });
    }
  }

  void login() async {
    print("google login");
    await _ensureLoggedIn(context)
    .then((value) {
      setState(() {
        triedSilentLogin = true;
      });
    });
  }

  void silentLogin(BuildContext context) async {
    print("google silentlogin");
    await _silentLogin(context)
    .then((value) {
      setState(() {
        triedSilentLogin = true;
      });
    });
  }


  Future<Null> _ensureLoggedIn(BuildContext context) async {
    GoogleSignInAccount user = googleSignIn.currentUser;
    if (user == null) {
      user = await googleSignIn.signInSilently();
    }
    if (user == null) {
      await googleSignIn.signIn();
      await tryCreateUserRecord(context);
    }

    if (await auth.currentUser() == null) {

      final GoogleSignInAccount googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;


      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await auth.signInWithCredential(credential);
    }
    print("Signed in with credential");
  }

  Future<Null> _silentLogin(BuildContext context) async {
    GoogleSignInAccount user = googleSignIn.currentUser;

    if (user == null) {
      user = await googleSignIn.signInSilently();
      await tryCreateUserRecord(context);
      print("tried to create user record at silentlogin");
    }
    print("User: " + user.toString());
    if (await auth.currentUser() == null && user != null) {
      final GoogleSignInAccount googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await auth.signInWithCredential(credential);
    }
  }

  void setUpNotifications() {
    _setUpNotifications();
    setState(() {
      setupNotifications = true;
    });
  }

  Future<Null> _setUpNotifications() async {
    if (Platform.isAndroid) {
      _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
          print('on message $message');
        },
        onResume: (Map<String, dynamic> message) async {
          print('on resume $message');
        },
        onLaunch: (Map<String, dynamic> message) async {
          print('on launch $message');
        },
      );

      _firebaseMessaging.getToken().then((token) {
        print("Firebase Messaging Token: " + token);

        Firestore.instance
            .collection("insta_users")
            .document(currentUserModel.id)
            .updateData({"androidNotificationToken": token});
      });
    }
  }

  Future<void> tryCreateUserRecord(BuildContext context) async {
    GoogleSignInAccount user = googleSignIn.currentUser;
    if (user == null) {
      print("googleSignIn.currentUser = null");
      return null;
    }
    DocumentSnapshot userRecord = await ref.document(user.id).get();
    print("retrieved userRecord");
    if (userRecord.data == null) {
      // no user record exists, time to create
      print("creating userRecord");
      String userName = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Center(
              child: Scaffold(
                  appBar: AppBar(
                    leading: Container(),
                    title: Text('Fill out missing data',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.white,
                  ),
                  body: ListView(
                    children: <Widget>[
                      Container(
                        child: CreateAccount(),
                      ),
                    ],
                  )),
            )),
      );

      if (userName != null || userName.length != 0) {
        ref.document(user.id).setData({
          "id": user.id,
          "username": userName,
          "photoUrl": user.photoUrl,
          "email": user.email,
          "displayName": user.displayName,
          "bio": "",
          "followers": {},
          "following": {},
        });
      }
    }
    print("trying to retrieve currentUserModel");
    await ref.document(user.id).get().then((value) {
      setState(() {
        print(value.toString());
        currentUserModel = User.fromDocument(value);
        print("Retrieved currentUserModel");
        widget.loginCallback();
      });
      return null;
    });
  }

  @override
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    _isLoginForm = true;
    super.initState();
  }

  void resetForm() {
    _formKey.currentState.reset();
    _errorMessage = "";
  }

  void toggleFormMode() {
    resetForm();
    setState(() {
      _isLoginForm = !_isLoginForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (triedSilentLogin == false) {
      silentLogin(context);
    }

    if (setupNotifications == false && currentUserModel != null) {
      setUpNotifications();
    }
    return new Scaffold(
        body: Stack(
          children: <Widget>[
            _showForm(),
            _showCircularProgress(),
          ],
        ));
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

//  void _showVerifyEmailSentDialog() {
//    showDialog(
//      context: context,
//      builder: (BuildContext context) {
//        // return object of type Dialog
//        return AlertDialog(
//          title: new Text("Verify your account"),
//          content:
//              new Text("Link to verify account has been sent to your email"),
//          actions: <Widget>[
//            new FlatButton(
//              child: new Text("Dismiss"),
//              onPressed: () {
//                toggleFormMode();
//                Navigator.of(context).pop();
//              },
//            ),
//          ],
//        );
//      },
//    );
//  }

  Widget _showForm() {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new ListView(
            shrinkWrap: true,
            children: _isLoginForm ? <Widget>[
              showLogo(),
              showAppName(),
              showEmailInput(),
              showPasswordInput(),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GestureDetector(
                  onTap: login,
                  child: Image.asset(
                    "assets/images/google_signin_button.png",
                    height: 60.0,
                  ),
                ),
              ),
              showPrimaryButton(),
              showSecondaryButton(),
              showErrorMessage(),
            ] : <Widget>[
              showLogo(),
              showAppName(),
              showUsernameInput(),
              showEmailInput(),
              showPasswordInput(),
              showPrimaryButton(),
              showSecondaryButton(),
              showErrorMessage(),
            ],
          ),
        ));
  }

  Widget showErrorMessage() {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      return new Text(
        _errorMessage,
        style: TextStyle(
            fontSize: 13.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w300),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  Widget showLogo() {
    return new Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 70.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 48.0,
          child: Image.asset('assets/images/ic_launcher.png'),
        ),
      ),
    );
  }

  Widget showAppName() {
    return Padding(
      padding: EdgeInsets.all(32.0),
      child: Center(
        child: Text(
          "InstaShop",
          style: TextStyle(
            fontSize: 60.0,
            fontFamily: "Billabong"
          ),
        ),
      ),
    );
  }

  Widget showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Email',
            icon: new Icon(
              Icons.mail,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Email can\'t be empty' : null,
        onSaved: (value) => _email = value.trim(),
      ),
    );
  }
  Widget showUsernameInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Username',
            icon: new Icon(
              Icons.perm_identity,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Username can\'t be empty' : null,
        onSaved: (value) => _username = value.trim(),
      ),
    );
  }

  Widget showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 16.0),
      child: new TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Password',
            icon: new Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Password can\'t be empty' : null,
        onSaved: (value) => _password = value.trim(),
      ),
    );
  }

  Widget showSecondaryButton() {
    return new FlatButton(
        child: new Text(
            _isLoginForm ? 'Create an account' : 'Have an account? Sign in',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: toggleFormMode);
  }

  Widget showPrimaryButton() {
    return new Padding(
        padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: new RaisedButton(
            elevation: 5.0,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.blue,
            child: new Text(_isLoginForm ? 'Login' : 'Create account',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: validateAndSubmit,
          ),
        ));
  }
}