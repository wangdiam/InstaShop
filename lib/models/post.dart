import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:instashop/models/comment.dart';
import 'package:instashop/models/user.dart';
import 'package:instashop/pages/root_page.dart';
import 'package:instashop/utils/data_parse_util.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'like.dart';

class Post {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  List<dynamic> imageUrls;
  String postedAt;
  String postID;
  String key;
  List<User> likedUsers;
  User user;
  List<Comment> comments;
  String location;

  Post({
    @required this.imageUrls,
    @required this.postedAt,
    @required this.likedUsers,
    @required this.comments,
    @required this.user,
    this.location,
    this.postID
  });


  Post.fromSnapshot(DataSnapshot snapshot) :
    key = snapshot.key,
    postedAt = snapshot.value["postedAt"],
    postID = snapshot.key,
    imageUrls = snapshot.value["imageUrls"],
    likedUsers = DataParseUtils().mapToLikedUsersList(snapshot.value["likes"]),
    location = snapshot.value["location"] == null ? "" : snapshot.value["location"],
    user = DataParseUtils().mapToUser(snapshot.value["user"]),
    comments = DataParseUtils().mapToCommentList(snapshot.value["comments"]);


  User mapToUser(Map map) {
    return User(
        name: map["name"],
        userID: map["userID"],
        imageUrl: map["imageUrl"] == null ? "assets/images/wangdiam.jpg" : map["imageUrl"]);
  }

  List<Like> mapToLikes(Map map) {
    List<Like> list = List();
    map.forEach((key, value) {
      list.add(Like(user: User(userID: map[key]["userID"], name: map[key]["name"])));
    });
    return list;
  }

  Map toJson() {
    return {
      "user": user.toJson(),
      "postID": postID,
      "likedUsers": likedUsers,
      "imageUrls": imageUrls,
      "comments": comments,
      "postedAt": postedAt,
      "location": location,
    };
  }

  String timeAgo() {
    final now = DateTime.now();
    return timeago.format(
        now.subtract(
            now.difference(
                DateTime.fromMillisecondsSinceEpoch(int.parse(postedAt))
            )
        )
    );
  }

  bool isLikedBy(User user) {
    return likedUsers.any((user) => user.name == currentUser.name);
  }

  void addLikeIfUnlikedFor(User user) {
    if (!isLikedBy(user)) {
      //_database.reference().child("likes").child(postID).push().set({"userID": user.userID, "name": user.name});
      _database.reference().child("posts").child(postID).child("likes").push().set({"name":user.name, "userID": user.userID});
    }
  }

  void removeLike(User user) {
    likedUsers.removeWhere((user) => user.name == currentUser.name);
  }

  void addLike(User user) {
    likedUsers.add(currentUser);
  }

  Future<void> toggleLikeFor(User user) async {
    if (isLikedBy(user)) {
      _database.reference().child("posts").child(postID).child("likes").once().then((snapshot) {
        print("SNAPSHOT VALUE: " + snapshot.value.toString());
        List<String> userIDList = List();
        List<String> userIDKeyList = List();
        snapshot.value.forEach((key,v) {
          userIDList.add(v["userID"]);
          userIDKeyList.add(key);
        });
        var exists = userIDList.contains(currentUser.userID);
        if (exists) {
          _database.reference().child("posts").child(postID).child("likes").child(userIDKeyList[userIDList.indexOf(currentUser.userID)]).remove();
        }
      });

    } else {
      addLikeIfUnlikedFor(user);
    }
  }


  void addComment(Comment comment) {
    comments.add(comment);
    comments.sort((a,b) => int.parse(a.commentedAt).compareTo(int.parse(b.commentedAt)));
    _database.reference().child("posts").child(postID).child("comments").push().set(comment.toJson());
  }
}