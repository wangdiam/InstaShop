import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:instashop/models/user.dart';
import 'package:instashop/utils/data_parse_util.dart';

class Comment {
  String text;
  final String postID;
  User user;
  final String commentedAt;
  bool flag = true;

  Comment({
    @required this.text,
    @required this.user,
    @required this.commentedAt,
    @required this.postID
  });

  Comment.fromSnapshot(DataSnapshot snapshot) :
        text = snapshot.value["text"],
        commentedAt = snapshot.value["commentedAt"],
        postID = snapshot.value["postID"],
        user = DataParseUtils().mapToUser(snapshot.value["user"]);


  void isExpanded(bool currentState) {
    flag = !currentState;
  }


  Map toJson() {
    return {
      "user": this.user.toJson(),
      "text": this.text,
      "commentedAt": this.commentedAt,
      "postID": this.postID
    };
  }






}