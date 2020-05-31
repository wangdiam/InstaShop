import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:instashop/models/comment.dart';
import 'package:instashop/models/post.dart';
import 'package:instashop/models/user.dart';
import 'package:instashop/pages/root_page.dart';
import 'package:instashop/utils/heart_icon_animator.dart';
import 'package:instashop/utils/heart_overlay_animator.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:instashop/widgets/avatar_widget.dart';
import 'package:instashop/widgets/comment_widget.dart';
import 'package:instashop/utils/ui_utils.dart';

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}

const List<Choice> choices = const <Choice>[
  const Choice(title: 'Report this post', icon: Icons.flag),
];

class PostWidget extends StatefulWidget {
  final Post post;
  final String userID;

  PostWidget(this.post, this.userID);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  final StreamController<void> _doubleTapImageEvents =
      StreamController.broadcast();
  bool _isSaved = false;
  int _currentImageIndex = 0;
  int _selectedChoice = 0;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  bool liked = false;
  StreamSubscription<Event> _onCommentAddedSubscription;
  Query _commentQuery;


  @override
  void initState() {
    widget.post.comments = List();
    super.initState();

    _commentQuery = _database
        .reference()
        .child("posts")
        .child(widget.post.postID)
        .child("comments");
    _onCommentAddedSubscription = _commentQuery.onChildAdded.listen(onCommentAdded);
    print("REBUILT POST WIDGET");


  }
  @override
  void dispose() {
    _doubleTapImageEvents.close();
    _onCommentAddedSubscription.cancel();
    super.dispose();
  }

  void onCommentAdded(Event event) {
    Comment comment = Comment.fromSnapshot(event.snapshot);
    setState(() {
      widget.post.comments.add(comment);
    });
  }

  void _updateImageIndex(int index) {
    setState(() => _currentImageIndex = index);
  }

  void _onDoubleTapLikePhoto() {
    setState(() => widget.post.addLikeIfUnlikedFor(currentUser));
    _doubleTapImageEvents.sink.add(null);
  }

  void _toggleIsSaved() {
    setState(() => _isSaved = !_isSaved);
  }

  void _togglePostIsLiked() {
    setState(() => widget.post.toggleLikeFor(currentUser));
    //send request to server to like post
  }

  void _select(Choice choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    setState(() {
      _selectedChoice = 0;
      //TODO: submit postID of post for report
    });
  }

  void _showAddCommentModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: AddCommentModal(
            user: currentUser,
            onPost: (String text) {
              setState(() {
                widget.post.addComment(Comment(
                  text: text,
                  user: currentUser,
                  commentedAt: DateTime.now().millisecondsSinceEpoch.toString(),
                  postID: widget.post.postID
                ));
              });
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
//    print("CURRENT USER " + currentUser.toJson().toString());
//    print("is liked by currentuser " + widget.post.isLikedBy(currentUser).toString());
//    print("Post JSON: " + widget.post.toJson().toString());
//    print("Post username " + widget.post.user.name);
//    print("Post likelist: " + widget.post.likedUsers.toString());
//    print("Post comments: " + widget.post.comments.toString());
    return Column(
      children: <Widget>[
        // User Details
        Row(
          children: <Widget>[
            AvatarWidget(user: widget.post.user),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(
                    TextSpan(
                      text: widget.post.user.name,
                      style: bold,
                      recognizer: TapGestureRecognizer()
                      ..onTap = () {
                      print('Clicked Profile name');
                      })),
                if (widget.post.location != null) Text(widget.post.location)
              ],
            ),
            Spacer(),
            PopupMenuButton<Choice>(
              onSelected: _select,
              itemBuilder: (BuildContext context) {
                return choices.map((Choice choice) {
                  return PopupMenuItem<Choice>(
                    value: choice,
                    child: Text(choice.title),
                  );
                }).toList();
              },
            ),
          ],
        ),
        // Photo Carosuel
        GestureDetector(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CarouselSlider(
                items: widget.post.imageUrls.map((url) {
                  return Container(
                      height: double.infinity,
                      width: double.infinity,
                      child: Image.asset(
                        url,
                        //height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.fitWidth,
                  ));
                }).toList(),
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                aspectRatio: 1,
                onPageChanged: _updateImageIndex,
              ),
              HeartOverlayAnimator(
                  triggerAnimationStream: _doubleTapImageEvents.stream),
            ],
          ),
          onDoubleTap: _onDoubleTapLikePhoto,
        ),
        // Action Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: HeartIconAnimator(
                isLiked: widget.post.isLikedBy(currentUser),
                size: 28.0,
                onTap: _togglePostIsLiked,
                triggerAnimationStream: _doubleTapImageEvents.stream,
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              iconSize: 28.0,
              icon: Icon(Icons.chat_bubble_outline),
              onPressed: _showAddCommentModal,
            ),
            IconButton(
              padding: EdgeInsets.zero,
              iconSize: 28.0,
              icon: Icon(OMIcons.nearMe),
              onPressed: () => showSnackbar(context, 'Share'),
            ),
            Spacer(),
            if (widget.post.imageUrls.length > 1)
              PhotoCarouselIndicator(
                photoCount: widget.post.imageUrls.length,
                activePhotoIndex: _currentImageIndex,
              ),
            Spacer(),
            Spacer(),
            IconButton(
              padding: EdgeInsets.zero,
              iconSize: 28.0,
              icon:
                  _isSaved ? Icon(Icons.bookmark) : Icon(Icons.bookmark_border),
              onPressed: _toggleIsSaved,
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 16.0, right: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Liked by
              if (widget.post.likedUsers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: <Widget>[
                      Text('Liked by '),
                      Text.rich(
                          TextSpan(
                              text: widget.post.likedUsers[0].name,
                              style: bold,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  print('Clicked Profile name');
                                })),
                      if (widget.post.likedUsers.length > 1) ...[
                        Text(' and'),
                        Text(' ${widget.post.likedUsers.length - 1} others',
                            style: bold),
                      ]
                    ],
                  ),
                ),
              // Comments
              if (widget.post.comments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Column(
                    children: widget.post.comments
                        .map((Comment c) => CommentWidget(c))
                        .toList(),
                  ),
                ),
              // Add a comment...
              Row(
                children: <Widget>[
                  AvatarWidget(
                    user: currentUser,
                    padding: EdgeInsets.only(right: 8.0),
                  ),
                  GestureDetector(
                    child: Text(
                      'Add a comment...',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: _showAddCommentModal,
                  ),
                ],
              ),
              // Posted Timestamp
              Text(
                widget.post.timeAgo(),
                style: TextStyle(color: Colors.grey, fontSize: 11.0),
              ),
            ],
          ),
        ),
      ],
    );
  }


}

class PhotoCarouselIndicator extends StatelessWidget {
  final int photoCount;
  final int activePhotoIndex;

  PhotoCarouselIndicator({
    @required this.photoCount,
    @required this.activePhotoIndex,
  });

  Widget _buildDot({bool isActive}) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.only(left: 3.0, right: 3.0),
        child: Container(
          height: isActive ? 7.5 : 6.0,
          width: isActive ? 7.5 : 6.0,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(photoCount, (i) => i)
          .map((i) => _buildDot(isActive: i == activePhotoIndex))
          .toList(),
    );
  }
}

class AddCommentModal extends StatefulWidget {
  final User user;
  final ValueChanged<String> onPost;

  AddCommentModal({@required this.user, @required this.onPost});

  @override
  _AddCommentModalState createState() => _AddCommentModalState();
}

class _AddCommentModalState extends State<AddCommentModal> {
  final _textController = TextEditingController();
  bool _canPost = false;

  @override
  void initState() {
    _textController.addListener(() {
      setState(() => _canPost = _textController.text.isNotEmpty);
    });
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        AvatarWidget(user: widget.user),
        Expanded(
          child: TextField(
            controller: _textController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              border: InputBorder.none,
            ),
          ),
        ),
        FlatButton(
          child: Opacity(
            opacity: _canPost ? 1.0 : 0.4,
            child: Text('Post', style: TextStyle(color: Colors.blue)),
          ),
          onPressed:
              _canPost ? () => widget.onPost(_textController.text) : null,
        )
      ],
    );
  }
}
