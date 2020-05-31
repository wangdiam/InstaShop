import 'package:flutter/material.dart';
import 'package:instashop/models/user.dart';

class Like {
  final User user;
  final String likedAt;

  Like({
    @required this.user,
    @required this.likedAt
  });


  Map toJSON() {
    return {
      user: user.toJson(),
      likedAt: likedAt
    };
  }
}