import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:instashop/pages/messaging/chat_page.dart';
import 'package:instashop/pages/messaging/const.dart';
import 'package:instashop/pages/root_page.dart';
import 'package:instashop/widgets/chat_loading.dart';


class MainChatScreen extends StatefulWidget {
  final String currentUserId;

  MainChatScreen({Key key, @required this.currentUserId}) : super(key: key);

  @override
  State createState() => MainChatScreenState(currentUserId: currentUserId);
}

class MainChatScreenState extends State<MainChatScreen> {
  MainChatScreenState({Key key, @required this.currentUserId});

  final String currentUserId;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool isLoading = false;
  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  @override
  void initState() {
    super.initState();
    registerNotification();
    configLocalNotification();
  }

  void registerNotification() {
    firebaseMessaging.requestNotificationPermissions();

    firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      print('onMessage: $message');
      Platform.isAndroid ? showNotification(message['notification']) : showNotification(message['aps']['alert']);
      return;
    }, onResume: (Map<String, dynamic> message) {
      print('onResume: $message');
      return;
    }, onLaunch: (Map<String, dynamic> message) {
      print('onLaunch: $message');
      return;
    });

    firebaseMessaging.getToken().then((token) {
      print('token: $token');
      Firestore.instance.collection('insta_users').document(currentUserId).updateData({'pushToken': token});
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  void configLocalNotification() {
    var initializationSettingsAndroid = new AndroidInitializationSettings('mipmap/ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Log out') {
      Navigator.pop(context);
    } else {
    }
  }

  void showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      Platform.isAndroid ? 'com.dfa.flutterchatdemo' : 'com.duytq.flutterchatdemo',
      'Flutter chat demo',
      'your channel description',
      playSound: true,
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics =
    new NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    print(message);
//    print(message['body'].toString());
//    print(json.encode(message));

    await flutterLocalNotificationsPlugin.show(
        0, message['title'].toString(), message['body'].toString(), platformChannelSpecifics,
        payload: json.encode(message));

//    await flutterLocalNotificationsPlugin.show(
//        0, 'plain title', 'plain body', platformChannelSpecifics,
//        payload: 'item x');
  }

  Future<bool> onBackPress() {
    Navigator.pop(context);
    return Future.value(false);
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => RootPage()), (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => Navigator.pop(context,false),
        ),
        backgroundColor: Colors.white,
        title: Text(
          'Chats',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            // List
            Container(
              child: StreamBuilder(
                stream: Firestore.instance.collection('insta_users').document(currentUserModel.id).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                      ),
                    );
                  } else {
                    print(snapshot.data["chattingWith"].toString());
                    List<String> chattingWithIds = [];
                    if (snapshot.data["chattingWith"] != null ) {
                      snapshot.data["chattingWith"].forEach((k,v) {
                        if (v) {
                          chattingWithIds.add(k);
                        }
                      });
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("Messages",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0
                            ),),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.all(8.0),
                              itemBuilder: (context, index) => buildItem(context, chattingWithIds[index]),
                              itemCount: chattingWithIds.length,
                            ),
                          ),
                        ],
                      );
                    }
                  return Container();
                  }
                },
              ),
            ),

            // Loading
            Positioned(
              child: isLoading ? const Loading() : Container(),
            )
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  getPeerInfo(String peerId) async {
    DocumentSnapshot doc1 = await Firestore.instance.collection('insta_users').document(peerId).get();
    String collectionId = "";
    if (currentUserModel.id.hashCode <= peerId.hashCode) {
      collectionId = '${currentUserModel.id}-$peerId';
    } else {
      collectionId = '$peerId-${currentUserModel.id}';
    }
    QuerySnapshot doc2 = await Firestore.instance.collection('messages')
        .document(collectionId)
        .collection(collectionId)
        .orderBy("timestamp", descending: true)
        .limit(1)
        .getDocuments();
    return [doc1,doc2];
  }

  Widget buildItem(BuildContext context, String peerId) {
    String collectionId;
    if (currentUserModel.id.hashCode <= peerId.hashCode) {
      collectionId = '${currentUserModel.id}-$peerId';
    } else {
      collectionId = '$peerId-${currentUserModel.id}';
    }
    if (peerId == currentUserId) {
      return Container();
    } else {
      return FutureBuilder(
        future: getPeerInfo(peerId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == null) return Container(
              child: Center(
                child: Text(
                  'You have no messages.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
            );
            var document = snapshot.data[0];
            List<DocumentSnapshot> lastMessage = snapshot.data[1].documents;
            print(lastMessage.toString());
            return Container(
              child: FlatButton(
                child: Row(
                  children: <Widget>[
                    Material(
                      child: document['photoUrl'] != null
                          ? CachedNetworkImage(
                        placeholder: (context, url) => Container(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.0,
                            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                          ),
                          width: 50.0,
                          height: 50.0,
                          padding: EdgeInsets.all(8.0),
                        ),
                        imageUrl: document['photoUrl'],
                        width: 50.0,
                        height: 50.0,
                        fit: BoxFit.cover,
                      )
                          : Icon(
                        Icons.account_circle,
                        size: 50.0,
                        color: greyColor,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(25.0)),
                      clipBehavior: Clip.hardEdge,
                    ),
                    Flexible(
                      child: Container(
                        child: Column(
                          children: <Widget>[
                            Container(
                              child: Text(
                                '${document['username']}',
                                style: TextStyle(color: primaryColor),
                              ),
                              alignment: Alignment.topLeft,
                              margin: EdgeInsets.fromLTRB(8.0, 0.0, 0.0, 0.0),
                            ),
                            StreamBuilder(
                              stream: Firestore.instance
                                  .collection('messages')
                                  .document(collectionId)
                                  .collection(collectionId)
                                  .orderBy('timestamp', descending: true)
                                  .limit(1)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Container();
                                } else {
                                  lastMessage = snapshot.data.documents;
                                  return Container(
                                    child: Text(
                                      '${lastMessage[0]['content']}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(color: Colors.grey,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    alignment: Alignment.topLeft,
                                    margin: EdgeInsets.fromLTRB(8.0, 4.0, 0.0, 0.0),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        margin: EdgeInsets.only(left: 20.0),
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Chat(
                              peerId: document.documentID,
                              peerAvatar: document['photoUrl'],
                              peerUserName: document['username']
                          )));
                },
                color: Colors.white,
                padding: EdgeInsets.all(8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
              ),
              margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
            );
          }
          return Container(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}