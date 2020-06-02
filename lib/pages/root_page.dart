import 'package:flutter/material.dart';
import 'package:instashop/models/user.dart';
import 'package:instashop/pages/login_signup_page.dart';
import 'package:instashop/services/authentication.dart';
import 'package:instashop/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

User currentUserModel;
BaseAuth baseAuth = Auth();
AuthStatus authStatus = AuthStatus.NOT_DETERMINED;

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

class RootPage extends StatefulWidget {
  RootPage();

  @override
  State<StatefulWidget> createState() => new _RootPageState();
}

class _RootPageState extends State<RootPage> {
  String _userId = "";
  User user;

  @override
  void initState() {
    super.initState();
    baseAuth.getCurrentUser().then((user) {
      setState(() {
        if (user != null) {
          _userId = user?.uid;
          authStatus =
          user?.uid == null ? AuthStatus.NOT_LOGGED_IN : AuthStatus.LOGGED_IN;
        }
      });
    });
  }

  void loginCallback() {
    print("logincallback");
    print(googleSignIn.currentUser.toString());
    print(currentUserModel.toString());
    if (currentUserModel == null) {
      if (_userId == "") {
        setState(() {
          authStatus = AuthStatus.NOT_LOGGED_IN;
        });
        return;
      }
    } else {
      baseAuth.getCurrentUser().then((user) {
        setState(() {
          _userId = currentUserModel.id;
        });
      });
      setState(() {
        authStatus = AuthStatus.LOGGED_IN;
      });
    }
  }

  void logoutCallback() async {
    print("logout");
    await auth.signOut();
    await googleSignIn.signOut();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    currentUserModel = null;
    setState(() {
      authStatus = AuthStatus.NOT_LOGGED_IN;
      _userId = "";
    });
  }

  Widget buildWaitingScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    switch (authStatus) {
      case AuthStatus.NOT_DETERMINED:
      case AuthStatus.NOT_LOGGED_IN:
        return new LoginSignupPage(
          loginCallback: loginCallback,
        );
        break;
      case AuthStatus.LOGGED_IN:
        //currentUser = User(name: _username, userID: userId, imageUrl: "assets/images/wangdiam.jpg");
        if (_userId.length > 0 && _userId != null && currentUserModel != null) {
          return MainScaffold(
            userId: currentUserModel.id,
            logoutCallback: logoutCallback,
          );
        } else
          return LoginSignupPage(
            loginCallback: loginCallback,
          );
        break;
      default:
        return LoginSignupPage(
          loginCallback: loginCallback,
        );
    }
  }
}