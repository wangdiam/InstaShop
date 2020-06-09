import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String username;
  String id;
  String photoUrl;
  String email;
  String displayName;
  String bio;
  Map followers;
  Map following;

  User(
      {this.username,
      this.id,
      this.photoUrl,
      this.email,
      this.displayName,
      this.followers,
      this.following,
      this.bio});

  factory User.fromDocument(DocumentSnapshot document) {
    return User(
      email: document['email'],
      username: document['username'],
      photoUrl: document['photoUrl'],
      id: document.documentID,
      displayName: document['displayName'],
      bio: document['bio'],
      followers: document['followers'],
      following: document['following'],
    );
  }
}
