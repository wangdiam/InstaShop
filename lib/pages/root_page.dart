import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:instashop/models/user.dart';
import 'package:instashop/pages/login_signup_page.dart';
import 'package:instashop/services/authentication.dart';
import 'package:instashop/main.dart';
import 'package:instashop/utils/data_parse_util.dart';

User currentUser;

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

class RootPage extends StatefulWidget {
  RootPage({this.auth});

  final BaseAuth auth;

  @override
  State<StatefulWidget> createState() => new _RootPageState();
}

class _RootPageState extends State<RootPage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  String _userId = "";
  User user;

  @override
  void initState() {
    super.initState();
    widget.auth.getCurrentUser().then((user) {
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
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        _userId = user.uid.toString();
      });
    });
    setState(() {
      authStatus = AuthStatus.LOGGED_IN;
    });
  }

  Future<void> getUserInfo(String userID) async {
    await _database.reference().once()
        .then((value) {
      setState(() {
        if (value.value != null) {
          print("USER INITIALIZATION");
          Map<dynamic,dynamic> map = value.value["users"];
          List<Map<dynamic,dynamic>> userInfoList = List();
          map.forEach((key, value) {
            userInfoList.add(value);
          });
          currentUser = User(name: userInfoList.last["username"], userID: userInfoList.last["userID"], imageUrl: "assets/images/wangdiam.jpg");
        }
      });
    });
  }

  void logoutCallback() {
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
//      case AuthStatus.NOT_DETERMINED:
//        return buildWaitingScreen();
//        break;
      case AuthStatus.NOT_DETERMINED:
      case AuthStatus.NOT_LOGGED_IN:
        return new LoginSignupPage(
          auth: widget.auth,
          loginCallback: loginCallback,
        );
        break;
      case AuthStatus.LOGGED_IN:
        //currentUser = User(name: _username, userID: userId, imageUrl: "assets/images/wangdiam.jpg");
        if (_userId.length > 0 && _userId != null) {
          try {
            return FutureBuilder(
              future: _database.reference().child("users").orderByChild('userID').equalTo(_userId).once(),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.hasData && snapshot.data.value != null) {
                  User user;
                  snapshot.data.value.forEach((key, v) {
                    user = DataParseUtils().mapToUser(v);
                  });
                  if (user.imageUrl == null) user.imageUrl = "assets/images/wangdiam.jpg";
                  currentUser = user;
                  print(snapshot.data.value.toString());
                  print("INITIALIZED USER: " + currentUser.toJson().toString());
                  return MainScaffold(
                    userId: _userId,
                    auth: widget.auth,
                    logoutCallback: logoutCallback,
                  );
                } else {
                  return LoginSignupPage(
                    auth: widget.auth,
                    loginCallback: loginCallback,
                  );
                }
              },
            );
          } catch (e) {
            return LoginSignupPage(
              auth: widget.auth,
              loginCallback: loginCallback,
            );
          }
        } else
          return buildWaitingScreen();
        break;
      default:
        return buildWaitingScreen();
    }
  }
}