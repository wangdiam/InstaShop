import 'package:flutter/material.dart';

class User {
  String name;
  String userID;
  String imageUrl;

  User({
    @required this.name,
    @required this.userID,
    this.imageUrl,
  });


  Map toJson() {
    return {
      "name": name,
      "userID": userID,
      "imageUrl": imageUrl
    };
  }
}