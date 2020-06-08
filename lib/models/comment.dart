import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comment {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  var timestamp;
  bool flag = false;

  Comment(
      {this.username,
        this.userId,
        this.avatarUrl,
        this.comment,
        this.timestamp});

  factory Comment.fromDocument(DocumentSnapshot document) {
    return Comment(
      username: document['username'],
      userId: document['userId'],
      comment: document["comment"],
      timestamp: document["timestamp"],
      avatarUrl: document["avatarUrl"],
    );
  }

  void isExpanded(bool currentState) {
    flag = !currentState;
  }

  String timeAgo() {
    final now = DateTime.now();
    try {
      return timeago.format(
          now.subtract(
              now.difference(
                  DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds']*1000)
              )
          )
      );
    } catch (e) {
      return timeago.format(
          now.subtract(
              now.difference(
                  timestamp.runtimeType == DateTime ? timestamp : timestamp.toDate()
              )
          )
      );
    }

  }

}