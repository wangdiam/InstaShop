import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instashop/models/comment.dart';
import "dart:async";

import 'package:instashop/pages/root_page.dart';
import 'package:instashop/widgets/comment_widget.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String postOwner;
  final String postMediaUrl;

  const CommentScreen({this.postId, this.postOwner, this.postMediaUrl});
  @override
  _CommentScreenState createState() => _CommentScreenState(
      postId: this.postId,
      postOwner: this.postOwner,
      postMediaUrl: this.postMediaUrl);
}

class _CommentScreenState extends State<CommentScreen> {
  final String postId;
  final String postOwner;
  final String postMediaUrl;
  List<Comment> commentList = [];
  final TextEditingController _commentController = TextEditingController();

  _CommentScreenState({this.postId, this.postOwner, this.postMediaUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
        title: Text(
          "Comments",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: buildPage(),
    );
  }

  Widget buildPage() {
    return Column(
      children: [
        Expanded(
          child:
            buildComments(),
        ),
        Divider(),
        ListTile(
          title: TextFormField(
            controller: _commentController,
            decoration: InputDecoration(labelText: 'Add a comment...'),
            onFieldSubmitted: addComment,
          ),
          trailing: OutlineButton(onPressed: (){addComment(_commentController.text);}, borderSide: BorderSide.none, child: Text("Post"),),
        ),

      ],
    );

  }

  Widget buildCommentTile(Comment comment) {
    return Padding(
      padding: const EdgeInsets.only(top:8.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            title: Column(
              children: [
                CommentWidget(comment),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(comment.timeAgo(),
                      style: TextStyle(
                          fontSize: 10.0,
                          color: Colors.black26
                      ),
                    ),
                  ],
                )
              ],
            ),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(comment.avatarUrl),
            ),
          ),
        ],
      ),
    );
  }


  Widget buildComments() {
    return FutureBuilder<List<Comment>>(
        future: getComments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Container(
                alignment: FractionalOffset.center,
                child: CircularProgressIndicator());

          return ListView(
            children: commentList.map((comment) {
              return buildCommentTile(comment);
            }).toList(),
          );
        });
  }

  Future<List<Comment>> getComments() async {
    List<Comment> comments = [];

    QuerySnapshot data = await Firestore.instance
        .collection("insta_comments")
        .document(postId)
        .collection("comments")
        .orderBy("timestamp")
        .getDocuments();
    data.documents.forEach((DocumentSnapshot doc) {
      comments.add(Comment.fromDocument(doc));
    });
    setState(() {
      commentList = comments;
    });
    return comments;
  }

  addComment(String comment) {
    _commentController.clear();
    Comment newComment = Comment(
      username: currentUserModel.username,
      comment: comment,
      timestamp: DateTime.now(),
      avatarUrl: currentUserModel.photoUrl,
      userId: currentUserModel.id
    );
    setState(() {
      commentList.add(newComment);
    });
    Firestore.instance
        .collection("insta_comments")
        .document(postId)
        .collection("comments")
        .add({
      "username": currentUserModel.username,
      "comment": comment,
      "timestamp": DateTime.now(),
      "avatarUrl": currentUserModel.photoUrl,
      "userId": currentUserModel.id
    });

    //adds to postOwner's activity feed
    Firestore.instance
        .collection("insta_a_feed")
        .document(postOwner)
        .collection("items")
        .add({
      "username": currentUserModel.username,
      "userId": currentUserModel.id,
      "type": "comment",
      "userProfileImg": currentUserModel.photoUrl,
      "commentData": comment,
      "timestamp": DateTime.now(),
      "postId": postId,
      "mediaUrl": postMediaUrl,
    });
  }
}
