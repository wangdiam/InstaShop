import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instashop/models/user.dart';
import 'package:instashop/pages/login_signup_page.dart';
import 'package:instashop/pages/main_page.dart';
import 'package:instashop/services/authentication.dart';
import 'package:shared_preferences/shared_preferences.dart';

User currentUserModel;
BaseAuth baseAuth = Auth();
AuthStatus authStatus;

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
  User user;

  @override
  void initState() {
    _getUser();
    super.initState();
  }

  /*
  *  Retrieves user records from SharedPreferences.
  * */
  void _getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId');
    setState(() {
      // If entry exists in SharedPreferences, authStatus will be set to Authstatus.LOGGED_IN and vice versa
      authStatus = prefs.getString('userId') == null
          ? AuthStatus.NOT_LOGGED_IN
          : AuthStatus.LOGGED_IN;
    });
    // If authStatus == AuthStatus.LOGGED_IN, retrieve user data from Firestore
    // TODO: move all Firestore methods to its own utils class
    if (authStatus == AuthStatus.LOGGED_IN) {
      await Firestore.instance
          .collection("insta_users")
          .document(userId)
          .get()
          .then((value) {
        setState(() {
          // Sets global currentUserModel to the fetched user data
          currentUserModel = User.fromDocument(value);
        });
      });
    }
  }

/*
*  Login Callback function
*  TODO: remove legacy code that is useless after implementation of Sign In with Google
* */

  void loginCallback() {
    print(currentUserModel.toString());
    if (currentUserModel != null) {
      setState(() {
        authStatus = AuthStatus.LOGGED_IN;
      });
    }
  }

  /*
*  Logout Callback function
*  TODO: remove legacy code that is useless after implementation of Sign In with Google
* */
  void logoutCallback() async {
    // Sign out
    await auth.signOut();
    await googleSignIn.signOut();

    // Clear SharedPreferences so that no user data will be stored
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Set global currentUserModel to null
    currentUserModel = null;
    setState(() {
      // Set authStatus to AuthStatus.NOT_LOGGED_IN
      authStatus = AuthStatus.NOT_LOGGED_IN;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("ROOTPAGE AUTHSTATUS: " + authStatus.toString());
    switch (authStatus) {
      case AuthStatus.NOT_DETERMINED:
        // TODO: return an app loading page instead of an empty container widget
        return Container();
      case AuthStatus.NOT_LOGGED_IN:
        // Creates LoginSignupPage if user is not logged in
        return new LoginSignupPage(
          loginCallback: loginCallback,
        );
      case AuthStatus.LOGGED_IN:
        if (currentUserModel != null) {
          // Creates MainScaffold if user is logged in, else return an empty container widget
          return MainScaffold(
            userId: currentUserModel.id,
            logoutCallback: logoutCallback,
          );
        } else
          return Container();
        break;
      default:
        return Container();
    }
  }
}
