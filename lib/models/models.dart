import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';

import 'package:meta/meta.dart';
import 'package:timeago/timeago.dart' as timeago;

const User user1 = User(name: "wangdiam", imageUrl: "", userID: "bdLz9F3ZXlgiIL2SnnpVt3WeLox1");

const currentUser = user1;

class Post {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  List<dynamic> imageUrls;
  String postedAt;
  String postID;
  String key;
  List<User> likedUsers;
  User user;
  List<Like> likes;
  List<Comment> comments;
  String location;
  Map<dynamic,dynamic> usermap = Map();
  Map<dynamic,dynamic> commentmap = Map();


  Post.fromSnapshot(DataSnapshot snapshot) :
    key = snapshot.key,
    postedAt = snapshot.value["postedAt"],
    postID = snapshot.key,
    imageUrls = snapshot.value["imageUrls"],
    likes = snapshot.value["likes"] == null ? [] : snapshot.value["likes"],
    location = snapshot.value["location"] == null ? "" : snapshot.value["location"],
    usermap = snapshot.value["user"],
    commentmap = snapshot.value["comments"] == null ? Map() : snapshot.value["comments"];


  User mapToUser(Map map) {
    return User(
        name: map["name"],
        userID: map["userID"],
        imageUrl: map["imageUrl"] == null ? "" : map["imageUrl"]);
  }

  List<Comment> mapToComments(Map map) {
    List<Comment> list = List();
    print("MAP " + map.toString());
    print(map.keys.toList()[0]);
    map.forEach((key, value) {
      list.add(
        Comment(
        commentID: map.keys.toList()[0],
        text: map[map.keys.toList()[0]]["text"],
        user: mapToUser(map[map.keys.toList()[0]]["user"]),
        commentedAt: map[map.keys.toList()[0]]['commentedAt'],
        postID: map[map.keys.toList()[0]]['postID']
      ));
    });
    return list;
  }

  Map toJSON() {
    user = usermap.isNotEmpty ? mapToUser(usermap) : user;
    print("commentmap " + commentmap.isNotEmpty.toString());
    comments = commentmap.isNotEmpty ? mapToComments(commentmap) : [];
    print(comments);
    return {
      "user": user.toJSON(),
      "postID": postID,
      "likes": likes,
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
    return likes.any((like) => like.user.name == user.name);
  }

  void addLikeIfUnlikedFor(User user) {
    if (!isLikedBy(user)) {
      likes.add(Like(user: user));
    }
  }

  void toggleLikeFor(User user) {
    if (isLikedBy(user)) {
      likes.removeWhere((like) => like.user.name == user.name);
    } else {
      addLikeIfUnlikedFor(user);
    }
  }

  Post({
    @required this.imageUrls,
    @required this.postedAt,
    @required this.likes,
    @required this.comments,
    @required this.user,
    this.location,
  });

  void addComment(Comment comment) {
    this.comments.add(comment);
    _database.reference().child("posts").child(postID).child("comments").push().set(comment.toJSON());
  }
}

class User {
  final String name;
  final String userID;
  final String imageUrl;

  const User({
    @required this.name,
    @required this.userID,
    this.imageUrl,
  });


  Map toJSON() {
    return {
      "name": name,
      "userID": userID,
      "imageUrl": imageUrl
    };
  }
}

class Comment {
  String text;
  final String commentID;
  final String postID;
  User user;
  final String commentedAt;
  List<Like> likes;
  bool flag = true;
  Map<dynamic, dynamic> map;

  Comment.fromSnapshot(DataSnapshot snapshot) :
        commentID = snapshot.key,
        text = snapshot.value["text"],
        map = snapshot.value["user"],
        commentedAt = snapshot.value["commentedAt"],
        likes = snapshot.value["likes"] == null ? [] : snapshot.value["likes"],
        postID = snapshot.value["postID"];


  void isExpanded(bool currentState) {
    flag = !currentState;
  }

  Map toJSON() {
    user = map == null ? user : User(name: map["name"], userID: map["userID"], imageUrl: map["imageUrl"]);
    return {
      "user": this.user.toJSON(),
      "text": this.text,
      "commentedAt": this.commentedAt,
      "likes": this.likes,
      "postID": this.postID
    };
  }


  Comment({
    @required this.commentID,
    @required this.text,
    @required this.user,
    @required this.commentedAt,
    @required this.likes,
    @required this.postID
  });



}

class Like {
  final User user;

  Like({@required this.user});
}