import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instashop/models/comment.dart';
import 'package:timeago/timeago.dart' as timeago;

class Post {
  List<Comment> comments;
  final String location;
  final String postId;
  final String username;
  final String mediaUrl;
  final likes;
  final String description;
  final String ownerId;
  final String price;
  bool saved;
  var timestamp;

  Post({
    this.location,
    this.username,
    this.mediaUrl,
    this.likes,
    this.description,
    this.ownerId,
    this.postId,
    this.price,
    this.timestamp,
  });

  factory Post.fromJSON(Map data) {
    return Post(
        username: data['username'],
        location: data['location'],
        mediaUrl: data['mediaUrl'],
        likes: data['likes'],
        description: data['description'],
        ownerId: data['ownerId'],
        postId: data['postId'],
        timestamp: data['timestamp'],
        price: data['price']);
  }

  factory Post.fromDocument(DocumentSnapshot document) {
    return Post(
        username: document['username'],
        location: document['location'],
        mediaUrl: document['mediaUrl'],
        likes: document['likes'],
        description: document['description'],
        postId: document.documentID,
        ownerId: document['ownerId'],
        timestamp: document['timestamp'],
        price: document['price']);
  }

  String timeAgo() {
    final now = DateTime.now();
    try {
      return timeago.format(now.subtract(now.difference(
          DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000))));
    } catch (e) {
      return timeago.format(now.subtract(now.difference(timestamp.toDate())));
    }
  }
}
