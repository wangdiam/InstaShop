
import 'dart:io';

import 'package:instashop/models/comment.dart';
import 'package:instashop/models/like.dart';
import 'package:instashop/models/post.dart';
import 'package:instashop/models/user.dart';

const UNDEFINED = "undefined";
const USERNAME = "name";
const USERID = "userID";
const IMAGEURL = "imageUrl";
const TEXT = "text";
const COMMENTID = "commentID";
const POSTID = "postID";
const USER = "user";
const COMMENTEDAT = "commentedAt";
const LOCATION = "location";
const COMMENTS = "comments";
const LIKEDUSERS = "likes";
const IMAGEURLS = "imageUrls";
const POSTEDAT = "postedAt";

class DataParseUtils {

  User mapToUser(Map map) {
    try {
      String name = map[USERNAME];
      String userID = map[USERID];
      String imageUrl = map[IMAGEURL];
      return User(name: name, userID: userID, imageUrl: imageUrl);
    } catch (e) {
      return User(name: UNDEFINED, userID: UNDEFINED, imageUrl: UNDEFINED);
    }
  }

  Post mapToPost(String key, Map map) {
    String postID = key;
    String postedAt = map[POSTEDAT];
    String location = map[LOCATION];
    User user = mapToUser(map[USER]);
    List<Comment> comments = jsonArrayToCommentList(map[COMMENTS]);
    List<User> likedUsers = mapToLikedUsersList(map[LIKEDUSERS]);
    List<dynamic> imageUrls = map[IMAGEURLS];
    return Post(imageUrls: imageUrls, postedAt: postedAt, likedUsers: likedUsers, comments: comments, user: user, location: location, postID: postID);
  }

  List<User> mapToLikedUsersList(Map map) {
    List<User> likedUsers = List();
    if (map == null) {
      return likedUsers;
    } else {
      map.forEach((key, value) {
        likedUsers.add(User(userID: map[key]["userID"], name: map[key]["name"]));
      });
      return likedUsers;
    }
  }

  List<Comment> jsonArrayToCommentList(var jsonArray) {
    List<Comment> list = List();
    try {
      jsonArray.forEach((key, element) {
        User user = DataParseUtils().mapToUser(element["user"]);
        String text = element["text"];
        String commentedAt = element["commentedAt"];
        String postID = element["postID"];
        list.add(Comment(
            text: text, user: user, commentedAt: commentedAt, postID: postID));
      });
    } catch (e) {

    }
    return list;
  }

  List<Comment> mapToCommentList(Map map) {
    try {
      List<Comment> list = List();
      map.forEach((key, value) {
        value.forEach((key, v) {
          String commentedAt = map[COMMENTEDAT];
          String postID = map[POSTID];
          String text = map[TEXT];
          //print("COMMENT KEY: " + key);
          User user = DataParseUtils().mapToUser(map[USER]);
          Comment comment = Comment(text: text, user: user, commentedAt: commentedAt, postID: postID);
          list.add(comment);
        });
      });
      return list;
    } catch (e) {
      return [];
    }
  }
  
}




